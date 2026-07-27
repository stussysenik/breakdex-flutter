// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional
// (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'package:breakdex/core/platform/io.dart';

import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/database/daos/asset_manifest_dao.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';

/// Reconciles `asset_copies` against what is actually on disk (design D8).
///
/// `copyCount` counts verified copy *rows*, not bytes. An asset whose video
/// sits on disk but which never got a `local` row — legacy imports predating
/// the manifest, and rows written by a site that skipped `updateCopyCount` —
/// therefore reads one copy short. It stays "underprotected" forever, is swept
/// on every cycle, and re-uploads to a provider that already has it.
///
/// This inserts the missing `local` rows from disk truth and nothing else: an
/// asset whose file is genuinely gone gets no row, so a missing video is never
/// dressed up as a protected one. Idempotent — safe to re-run.
class LocalCopyReconciler {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;

  LocalCopyReconciler({
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
  })  : _manifestDao = manifestDao,
        _copiesDao = copiesDao;

  /// Content hashes of live assets whose file exists on disk but which carry
  /// no `local` copy row — the gap, without changing anything.
  Future<List<String>> findMissingLocalCopies() async {
    final manifests = await _manifestDao.getAll();
    final missing = <String>[];

    for (final manifest in manifests) {
      if (manifest.deletedAt != null) continue;

      final relative = manifest.localPath;
      if (relative == null) continue;
      if (!await File(VideoPathResolver.toAbsolute(relative)).exists()) {
        continue;
      }

      // Deliberately not `getLocalCopy` — it uses `getSingleOrNull` and throws
      // on the duplicate local rows this codebase used to write (D7).
      final copies = await _copiesDao.getByHash(manifest.contentHash);
      if (copies.any((final c) => c.provider == 'local')) continue;

      missing.add(manifest.contentHash);
    }
    return missing;
  }

  /// Insert the missing `local` copy rows and restate their counts.
  /// Returns how many rows were inserted.
  Future<int> reconcile() async {
    final missing = await findMissingLocalCopies();
    final now = DateTime.now();

    for (final hash in missing) {
      await _copiesDao.upsertCopy(
        AssetCopiesCompanion.insert(
          id: AssetCopiesDao.copyId(hash, 'local'),
          contentHash: hash,
          provider: 'local',
          status: const Value('verified'),
          verifiedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _manifestDao.updateCopyCount(hash);
    }
    return missing.length;
  }
}
