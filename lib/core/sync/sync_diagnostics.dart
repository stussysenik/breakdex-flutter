import '../database/database.dart';

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

    return [
      'asset_manifest: ${manifests.length} rows (${live.length} live, '
          '$underprotected underprotected, '
          '${manifests.length - live.length} tombstoned)',
      'asset_copies: ${_fmt(copiesByKey)}',
      'sync_operations: ${_fmt(opsByStatus)}',
      if (errorCounts.isNotEmpty)
        'failed op errors:\n${_fmtErrors(errorCounts)}',
    ].join('\n');
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
