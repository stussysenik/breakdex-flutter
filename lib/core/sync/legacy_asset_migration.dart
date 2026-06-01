import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/daos/moves_dao.dart';
import '../database/database.dart';
import '../services/video_path_resolver.dart';
import 'asset_hash_service.dart';

/// Progress snapshot emitted during legacy migration.
class MigrationProgress {
  final int completed;
  final int total;
  final String? currentMoveName;

  const MigrationProgress({
    required this.completed,
    required this.total,
    this.currentMoveName,
  });

  double get fraction => total > 0 ? completed / total : 0;
  bool get isDone => completed >= total;
}

/// Migrates existing moves with `videoPath` into the content-addressable
/// asset manifest system introduced in schema v10.
///
/// On first launch after the v10 migration:
/// 1. Queries all moves where `videoPath != null`
/// 2. For each move: computes SHA-256, inserts `asset_manifest` entry,
///    inserts `asset_copies` (provider='local'), sets `moves.content_hash`
/// 3. Runs sequentially to avoid saturating I/O
/// 4. Idempotent — safe to restart if interrupted (skips moves that already
///    have a content_hash set)
class LegacyAssetMigration {
  final MovesDao _movesDao;
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;
  final AppDatabase _db;

  LegacyAssetMigration({
    required final MovesDao movesDao,
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final AssetHashService hashService,
    required final AppDatabase db,
  }) : _movesDao = movesDao,
       _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _hashService = hashService,
       _db = db;

  /// Run the migration, yielding progress updates.
  ///
  /// This is a no-op if all moves already have content hashes.
  Stream<MigrationProgress> migrate() async* {
    final allMoves = await _movesDao.getAllIncludingArchived();
    final pending = allMoves
        .where((final m) => m.videoPath != null && m.contentHash == null)
        .toList();

    if (pending.isEmpty) {
      yield const MigrationProgress(completed: 0, total: 0);
      return;
    }

    final total = pending.length;
    for (int i = 0; i < total; i++) {
      final move = pending[i];
      yield MigrationProgress(
        completed: i,
        total: total,
        currentMoveName: move.name,
      );

      try {
        await _migrateMove(move);
      } catch (e) {
        debugPrint('Legacy migration failed for ${move.name}: $e');
        // Continue with next move — idempotent, will retry on next launch
      }
    }

    yield MigrationProgress(completed: total, total: total);
  }

  Future<void> _migrateMove(final Move move) async {
    final videoPath = move.videoPath!;
    // Resolve to absolute path for file operations (may be relative or stale)
    final absolutePath = VideoPathResolver.toAbsolute(videoPath);
    final file = File(absolutePath);

    if (!await file.exists()) {
      debugPrint(
        '[LegacyMigration] ${move.name}: video missing at $videoPath — clearing stale path',
      );
      // Clear the stale videoPath so the move enters the "Missing" state
      // cleanly. All metadata (name, category, date, notes) is preserved.
      await _movesDao.updateMove(
        MovesCompanion(id: Value(move.id), videoPath: const Value(null)),
      );
      return;
    }

    final hash = await _hashService.computeHash(absolutePath);
    final stat = await file.stat();
    final now = DateTime.now();

    // Use a transaction to ensure atomicity — either all three writes
    // succeed or none do.
    await _db.transaction(() async {
      // Insert manifest entry (no-op if hash already exists = dedup)
      await _manifestDao.insertManifest(
        AssetManifestCompanion.insert(
          contentHash: hash,
          fileSizeBytes: stat.size,
          localPath: Value(VideoPathResolver.toRelative(videoPath)),
          localVerifiedAt: Value(now),
          sourceType: 'legacy_migration',
          sourceName: Value(move.originalVideoName ?? move.name),
          importedAt: now,
        ),
      );

      // Insert local copy record
      final copyId = '${move.id}_local'; // Deterministic ID for idempotency
      await _copiesDao.upsertCopy(
        AssetCopiesCompanion.insert(
          id: copyId,
          contentHash: hash,
          provider: 'local',
          status: const Value('verified'),
          verifiedAt: Value(now),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Link the move to its content hash
      await _movesDao.updateMove(
        MovesCompanion(id: Value(move.id), contentHash: Value(hash)),
      );
    });
  }
}
