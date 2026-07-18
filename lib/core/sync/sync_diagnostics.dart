// Async filesystem stat is intentional here for the same reason it is in
// LocalCopyReconciler — the sync alternative blocks the UI isolate.
// ignore_for_file: avoid_slow_async_io

import '../database/database.dart';
import '../platform/io.dart';
import '../services/video_path_resolver.dart';
import 'asset_resolution.dart';
import 'local_copy_reconciler.dart';

/// Dev-only snapshot of the video-backup ground truth: manifest counts,
/// copies grouped by provider×status, operations grouped by status.
///
/// Exists so on-device backup state is inspectable evidence instead of
/// guesswork — "the UI says All synced" becomes three verifiable lines.
class SyncDiagnostics {
  final AppDatabase _db;

  SyncDiagnostics(this._db);

  /// Render the current backup state as a compact multi-line report.
  Future<String> dump() async {
    final manifests = await _db.assetManifestDao.getAll();
    final live = manifests.where((final m) => m.deletedAt == null).toList();
    final underprotected = live.where((final m) => m.copyCount < 2).length;

    final copies = await _db.select(_db.assetCopies).get();
    final copiesByKey = <String, int>{};
    for (final copy in copies) {
      copiesByKey.update(
        '${copy.provider}×${copy.status}',
        (final v) => v + 1,
        ifAbsent: () => 1,
      );
    }

    final ops = await _db.select(_db.syncOperations).get();
    final opsByStatus = <String, int>{};
    for (final op in ops) {
      opsByStatus.update(op.status, (final v) => v + 1, ifAbsent: () => 1);
    }

    // Failed ops grouped by error message — the WHY behind a stuck sweep.
    final errorCounts = <String, int>{};
    for (final op in ops) {
      if (op.status != 'failed') continue;
      final error = op.errorMessage ?? '(no error message)';
      errorCounts.update(error, (final v) => v + 1, ifAbsent: () => 1);
    }

    // Live assets whose bytes are on disk but which carry no `local` copy row
    // — the count task 4.0 asks for, and the gap 4.3's reconcile closes.
    final missingLocal = await LocalCopyReconciler(
      manifestDao: _db.assetManifestDao,
      copiesDao: _db.assetCopiesDao,
    ).findMissingLocalCopies();

    return [
      'asset_manifest: ${manifests.length} rows (${live.length} live, '
          '$underprotected underprotected, '
          '${manifests.length - live.length} tombstoned)',
      'on disk without a local copy row: ${missingLocal.length}',
      'asset_copies: ${_fmt(copiesByKey)}',
      'sync_operations: ${_fmt(opsByStatus)}',
      if (errorCounts.isNotEmpty)
        'failed op errors:\n${_fmtErrors(errorCounts)}',
      await dumpUnresolvableAssets(),
    ].join('\n');
  }

  /// Does a stored relative path have bytes behind it?
  ///
  /// Fails soft on purpose: `VideoPathResolver.toAbsolute` asserts the resolver
  /// was initialized, and a *diagnostic* that throws is worse than useless — it
  /// takes down the one surface you opened to find out what is wrong. An
  /// unresolvable path is reported as "no bytes", which is what it means here.
  Future<bool> _hasBytes(final String? relative) async {
    if (relative == null) return false;
    try {
      return await File(VideoPathResolver.toAbsolute(relative)).exists();
    } on Object {
      return false;
    }
  }

  /// Per-asset forensics for every live asset whose bytes the engine cannot
  /// reach — the ground truth design D8 asks for.
  ///
  /// "Local file missing" is one sentence covering four situations, and only
  /// two of them are terminal. For each unreachable asset this reports what its
  /// owning entities actually say and whether any of their paths has bytes
  /// behind it, so the archived-owner blind spot is *counted* rather than
  /// inferred from a sample of filenames. Read-only: selects and stat calls,
  /// no writes.
  Future<String> dumpUnresolvableAssets() async {
    final manifests = await _db.assetManifestDao.getAll();
    final lines = <String>[];
    final tally = <AssetResolution, int>{};

    for (final manifest in manifests) {
      if (manifest.deletedAt != null) continue;

      final relative = manifest.localPath;
      if (await _hasBytes(relative)) {
        continue; // Reachable — not what this report is about.
      }

      final hash = manifest.contentHash;
      // Deleted owners are fetched, not filtered out in SQL: a soft-deleted
      // owner is a materially different verdict from no owner at all, and
      // collapsing them in the query makes the two indistinguishable here.
      final allMoves =
          await (_db.select(_db.moves)
                ..where((final t) => t.contentHash.equals(hash)))
              .get();
      final owners =
          allMoves.where((final m) => m.deletedAt == null).toList();
      final deletedOwnerCount = allMoves.length - owners.length;
      final combos =
          await (_db.select(_db.combos)
                ..where((final t) => t.contentHash.equals(hash)))
              .get();

      // Combos are already unfiltered by the heal's candidate query, so they
      // count toward the *active* side — the heal can see them.
      var activeOnDisk = false;
      var archivedOnDisk = false;
      var archivedCount = 0;

      for (final move in owners) {
        final path = move.videoPath;
        final isArchived = move.archivedAt != null;
        if (isArchived) archivedCount++;
        if (!await _hasBytes(path)) continue;
        if (isArchived) {
          archivedOnDisk = true;
        } else {
          activeOnDisk = true;
        }
      }
      for (final combo in combos) {
        if (await _hasBytes(combo.activeVideoPath)) {
          activeOnDisk = true;
        }
      }

      final resolution = classifyAssetResolution(
        ownerCount: owners.length + combos.length,
        activeOwnerHasBytes: activeOnDisk,
        archivedOwnerHasBytes: archivedOnDisk,
        deletedOwnerCount: deletedOwnerCount,
      );
      tally.update(resolution, (final v) => v + 1, ifAbsent: () => 1);

      lines.add(
        '  ${assetResolutionLabel(resolution)} '
        '${hash.length > 8 ? hash.substring(0, 8) : hash} '
        'owners=${owners.length}($archivedCount archived, '
        '$deletedOwnerCount deleted)+${combos.length}combo '
        'path=${relative ?? '(none)'}',
      );
    }

    final control = await _ownerJoinControl();

    if (lines.isEmpty) return '$control\nunresolvable assets: none';

    final summary = tally.entries
        .map((final e) => '${assetResolutionLabel(e.key)}: ${e.value}')
        .join(' · ');
    final meanings = tally.keys
        .map((final r) => '  ${assetResolutionLabel(r)} — ${assetResolutionMeaning(r)}')
        .join('\n');

    return '$control\n'
        'unresolvable assets: ${lines.length} ($summary)\n'
        '$meanings\n${lines.join('\n')}';
  }

  /// Positive control for the owner lookup above.
  ///
  /// The per-asset loop only ever runs its owner query against assets whose
  /// bytes are already missing, so a report of "owners=0" everywhere is equally
  /// consistent with "these really are orphans" and "this join never matches
  /// anything" (mismatched hash encodings, say). This measures the join across
  /// *all* live manifest hashes, where matches are expected. A reading of 0/N
  /// means the join is broken and every ORPHAN verdict above is worthless.
  Future<String> _ownerJoinControl() async {
    final manifests = await _db.assetManifestDao.getAll();
    final liveHashes = manifests
        .where((final m) => m.deletedAt == null)
        .map((final m) => m.contentHash)
        .toSet();
    if (liveHashes.isEmpty) {
      return 'owner-join control: 0/0 live manifest hashes match ≥1 move';
    }

    final moveHashes = (await _db.select(_db.moves).get())
        .map((final m) => m.contentHash)
        .whereType<String>()
        .toSet();
    final matched = liveHashes.where(moveHashes.contains).length;

    return 'owner-join control: $matched/${liveHashes.length} '
        'live manifest hashes match ≥1 move';
  }

  static String _fmtErrors(final Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((final a, final b) => b.value.compareTo(a.value));
    return entries.map((final e) => '  ${e.value}× ${e.key}').join('\n');
  }

  static String _fmt(final Map<String, int> counts) {
    if (counts.isEmpty) return '(none)';
    final entries = counts.entries.toList()
      ..sort((final a, final b) => a.key.compareTo(b.key));
    return entries.map((final e) => '${e.key}: ${e.value}').join(' · ');
  }
}
