import '../database/database.dart';

/// Where a single asset stands in the backup pipeline, as one word.
///
/// Derived, never stored — the tables hold copies and operations; this is the
/// question the user actually asks ("is my video safe, and is anything
/// happening?") answered from them.
enum AssetSyncStatus {
  /// At least one cloud provider holds a copy that verified.
  backedUp,

  /// An operation is moving bytes for this asset right now.
  uploading,

  /// An operation is queued but hasn't started.
  queued,

  /// The last attempt failed. See [AssetSyncDetail.errorMessage].
  failed,

  /// No cloud copy, nothing queued, nothing failed — untouched so far.
  pending,
}

/// One provider's standing for an asset, straight off `asset_copies`.
class AssetCopyState {
  final String provider;
  final String status;

  const AssetCopyState({required this.provider, required this.status});
}

/// Read-only per-asset view over `asset_manifest` × `asset_copies` ×
/// `sync_operations`.
class AssetSyncDetail {
  final String contentHash;

  /// Recognisable name for the file. Renames and category moves relocate the
  /// video on disk (task 1.8), so the current path's basename tracks the
  /// owning move's name without joining the moves table.
  final String label;

  final int fileSizeBytes;
  final AssetSyncStatus status;

  /// Bytes moved by the active operation; 0 when nothing is in flight.
  final int transferredBytes;

  /// Error from the most recent failed operation, when [status] is
  /// [AssetSyncStatus.failed].
  final String? errorMessage;

  /// The failed operation has exhausted its retries — the engine will not try
  /// again on its own.
  final bool isTerminal;

  final List<AssetCopyState> copies;

  const AssetSyncDetail({
    required this.contentHash,
    required this.label,
    required this.fileSizeBytes,
    required this.status,
    required this.transferredBytes,
    required this.errorMessage,
    required this.isTerminal,
    required this.copies,
  });

  /// Transfer progress as a fraction, or null when the size isn't known —
  /// never a fabricated 0.0 that would read as "stalled at the start".
  double? get fraction =>
      fileSizeBytes > 0 && transferredBytes > 0
          ? (transferredBytes / fileSizeBytes).clamp(0.0, 1.0)
          : null;
}

/// How the live library divides across the pipeline.
///
/// Folded from the same [AssetSyncDetail] rows the list renders, so the
/// buckets partition the library exactly: every live asset lands in one and
/// no asset lands in two. [total] is therefore an arithmetic identity, not a
/// second count that could disagree with the first.
class AssetSyncTally {
  /// Bytes are moving right now.
  final int uploading;

  /// Queued or untouched — waiting, nothing moving.
  final int waiting;

  /// The last attempt failed and the engine will try that operation again.
  final int retrying;

  /// The last attempt burned its whole retry budget.
  ///
  /// Deliberately *not* named "will never be retried". The operation is
  /// finished, but the next sweep calls `queueUpload` for any asset still
  /// under the copy minimum, and `operationExists` only dedupes against
  /// `queued`/`in_progress` — so a fresh operation is inserted with
  /// `retryCount` back at zero. The budget is bounded per operation and
  /// unbounded per asset. Making that promise true is task 4.4; until then
  /// this bucket means "keeps failing", which is what the user sees.
  final int unbackupable;

  /// A cloud provider holds a verified copy.
  final int backedUp;

  const AssetSyncTally({
    required this.uploading,
    required this.waiting,
    required this.retrying,
    required this.unbackupable,
    required this.backedUp,
  });

  factory AssetSyncTally.from(final List<AssetSyncDetail> details) {
    var uploading = 0;
    var waiting = 0;
    var retrying = 0;
    var unbackupable = 0;
    var backedUp = 0;
    for (final detail in details) {
      switch (detail.status) {
        case AssetSyncStatus.uploading:
          uploading++;
        case AssetSyncStatus.queued:
        case AssetSyncStatus.pending:
          waiting++;
        case AssetSyncStatus.failed:
          if (detail.isTerminal) {
            unbackupable++;
          } else {
            retrying++;
          }
        case AssetSyncStatus.backedUp:
          backedUp++;
      }
    }
    return AssetSyncTally(
      uploading: uploading,
      waiting: waiting,
      retrying: retrying,
      unbackupable: unbackupable,
      backedUp: backedUp,
    );
  }

  int get total => uploading + waiting + retrying + unbackupable + backedUp;

  /// Everything without a verified cloud copy, whatever stage it is at.
  int get unprotected => total - backedUp;
}

/// Compose the per-asset list from raw table rows.
///
/// Pure so the classification is testable without a database. Tombstoned
/// assets are excluded — they are not awaiting backup.
///
/// Ordering puts the rows that answer "is it doing anything?" first:
/// uploading → queued → failed → pending → backed up.
List<AssetSyncDetail> buildAssetSyncDetails({
  required final List<AssetManifestData> manifests,
  required final List<AssetCopy> copies,
  required final List<SyncOperation> operations,
}) {
  final copiesByHash = <String, List<AssetCopy>>{};
  for (final copy in copies) {
    copiesByHash.putIfAbsent(copy.contentHash, () => []).add(copy);
  }

  final opsByHash = <String, List<SyncOperation>>{};
  for (final op in operations) {
    opsByHash.putIfAbsent(op.contentHash, () => []).add(op);
  }

  final details = <AssetSyncDetail>[];
  for (final manifest in manifests) {
    if (manifest.deletedAt != null) continue;

    final assetCopies = copiesByHash[manifest.contentHash] ?? const [];
    final assetOps = opsByHash[manifest.contentHash] ?? const [];

    final active = _firstWhereOrNull(
      assetOps,
      (final op) => op.status == 'in_progress' || op.status == 'uploading',
    );
    final queued = _firstWhereOrNull(assetOps, (final op) => op.status == 'queued');

    // "Backed up" means a cloud provider verified a copy. The local row and
    // the two-copy minimum answer a different question (may I delete the
    // bytes here), so neither is allowed to imply cloud protection.
    final backedUp = assetCopies.any(
      (final c) => c.provider != 'local' && c.status == 'verified',
    );

    final failed = _latestFailed(assetOps);

    final status = active != null
        ? AssetSyncStatus.uploading
        : queued != null
            ? AssetSyncStatus.queued
            : backedUp
                ? AssetSyncStatus.backedUp
                : failed != null
                    ? AssetSyncStatus.failed
                    : AssetSyncStatus.pending;

    details.add(AssetSyncDetail(
      contentHash: manifest.contentHash,
      label: _label(manifest),
      fileSizeBytes: manifest.fileSizeBytes,
      status: status,
      transferredBytes: active?.bytesTransferred ?? 0,
      errorMessage:
          status == AssetSyncStatus.failed ? failed?.errorMessage : null,
      isTerminal: status == AssetSyncStatus.failed &&
          failed != null &&
          failed.retryCount >= failed.maxRetries,
      copies: [
        for (final c in assetCopies)
          AssetCopyState(provider: c.provider, status: c.status),
      ]..sort((final a, final b) => a.provider.compareTo(b.provider)),
    ));
  }

  details.sort((final a, final b) {
    final byStatus = _rank(a.status).compareTo(_rank(b.status));
    return byStatus != 0 ? byStatus : a.label.compareTo(b.label);
  });
  return details;
}

int _rank(final AssetSyncStatus status) => switch (status) {
      AssetSyncStatus.uploading => 0,
      AssetSyncStatus.queued => 1,
      AssetSyncStatus.failed => 2,
      AssetSyncStatus.pending => 3,
      AssetSyncStatus.backedUp => 4,
    };

/// Most recent failed attempt, by when it finished (falling back to when it
/// was queued for operations that carry no completion stamp).
SyncOperation? _latestFailed(final List<SyncOperation> ops) {
  SyncOperation? latest;
  for (final op in ops) {
    if (op.status != 'failed') continue;
    if (latest == null ||
        (op.completedAt ?? op.createdAt)
            .isAfter(latest.completedAt ?? latest.createdAt)) {
      latest = op;
    }
  }
  return latest;
}

String _label(final AssetManifestData manifest) {
  final path = manifest.localPath;
  if (path != null && path.isNotEmpty) {
    final segments = path.split('/');
    if (segments.last.isNotEmpty) return segments.last;
  }
  final source = manifest.sourceName;
  if (source != null && source.isNotEmpty) return source;
  final hash = manifest.contentHash;
  return hash.length <= 12 ? hash : hash.substring(0, 12);
}

T? _firstWhereOrNull<T>(final List<T> items, final bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
