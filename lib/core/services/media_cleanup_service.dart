import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/reviewable_item.dart';
import '../utils/diagnostics.dart';
import 'native_video_album.dart';
import 'video_path_resolver.dart';
import 'video_service.dart';

class MediaCleanupService {
  MediaCleanupService({
    required final AppDatabase db,
    required final VideoService videoService,
    final NativeVideoAlbum? videoAlbum,
  }) : _db = db,
       _videoService = videoService,
       _videoAlbum = videoAlbum ?? NativeVideoAlbum();

  final AppDatabase _db;
  final VideoService _videoService;
  final NativeVideoAlbum _videoAlbum;

  Future<void> cleanupMoveMedia(final Move move) {
    return _cleanupAsset(
      storedVideoPath: move.videoPath,
      resolvedVideoPath: move.resolvedVideoPath,
      contentHash: move.contentHash,
      managedAlbumAssetId: move.managedAlbumAssetId,
      title: move.name,
      category: move.category,
      excludingMoveId: move.id,
    );
  }

  Future<void> cleanupComboMedia(final Combo combo) {
    return _cleanupAsset(
      storedVideoPath: combo.activeVideoPath,
      resolvedVideoPath: combo.resolvedActiveVideoPath,
      contentHash: combo.contentHash,
      title: combo.name,
      category: 'combo',
      excludingComboId: combo.id,
    );
  }

  Future<void> cleanupDetachedAsset({
    required final String title,
    final String? category,
    final String? storedVideoPath,
    final String? resolvedVideoPath,
    final String? contentHash,
    final String? managedAlbumAssetId,
    final String? excludingMoveId,
    final String? excludingComboId,
    final bool skipPhotosCleanup = false,
  }) {
    return _cleanupAsset(
      storedVideoPath: storedVideoPath,
      resolvedVideoPath: resolvedVideoPath,
      contentHash: contentHash,
      managedAlbumAssetId: managedAlbumAssetId,
      title: title,
      category: category,
      excludingMoveId: excludingMoveId,
      excludingComboId: excludingComboId,
      skipPhotosCleanup: skipPhotosCleanup,
    );
  }

  Future<void> _cleanupAsset({
    required final String title,
    final String? category,
    final String? storedVideoPath,
    final String? resolvedVideoPath,
    final String? contentHash,
    final String? managedAlbumAssetId,
    final String? excludingMoveId,
    final String? excludingComboId,
    final bool skipPhotosCleanup = false,
  }) async {
    final pathStillReferenced = await _isPathStillReferenced(
      storedVideoPath: storedVideoPath,
      excludingMoveId: excludingMoveId,
      excludingComboId: excludingComboId,
    );
    final hashStillReferenced = await _isHashStillReferenced(
      contentHash: contentHash,
      excludingMoveId: excludingMoveId,
      excludingComboId: excludingComboId,
    );

    final pathForCleanup = resolvedVideoPath ?? storedVideoPath;
    final willDelete = !pathStillReferenced && pathForCleanup != null && pathForCleanup.trim().isNotEmpty;
    final willTombstone = !hashStillReferenced && contentHash != null && contentHash.trim().isNotEmpty;
    DiagnosticsLog.debug('MediaCleanup', '_cleanupAsset title="$title" willDelete=$willDelete willTombstone=$willTombstone');
    if (!pathStillReferenced &&
        pathForCleanup != null &&
        pathForCleanup.trim().isNotEmpty) {
      try {
        DiagnosticsLog.debug('MediaCleanup', 'DELETING local video: $pathForCleanup');
        await _videoService.deleteVideo(pathForCleanup);
        DiagnosticsLog.debug('MediaCleanup', 'Local video DELETED: $pathForCleanup');
      } on Object catch (error) {
        DiagnosticsLog.warn('MediaCleanup', 'Local video cleanup FAILED for "$title": $error');
      }

      if (!skipPhotosCleanup && managedAlbumAssetId != null && managedAlbumAssetId.trim().isNotEmpty) {
        try {
          DiagnosticsLog.debug('MediaCleanup', 'Deleting album copy for "$title" assetId=$managedAlbumAssetId');
          await _videoAlbum.deleteExactManagedCopy(managedAlbumAssetId.trim());
          DiagnosticsLog.debug('MediaCleanup', 'Album copy deleted for "$title"');
        } on Object catch (error) {
          DiagnosticsLog.warn('MediaCleanup', 'Album cleanup FAILED for "$title": $error');
        }
      }
    }

    if (hashStillReferenced ||
        contentHash == null ||
        contentHash.trim().isEmpty) {
      return;
    }
    DiagnosticsLog.debug('MediaCleanup', 'TOMBSTONING asset: $contentHash');
    await _tombstoneAsset(contentHash);
  }

  Future<bool> _isPathStillReferenced({
    final String? storedVideoPath,
    final String? excludingMoveId,
    final String? excludingComboId,
  }) async {
    final normalizedPath = storedVideoPath == null || storedVideoPath.isEmpty
        ? null
        : VideoPathResolver.toRelative(storedVideoPath);

    if (normalizedPath != null) {
      final moveRefs =
          await (_db.select(_db.moves)..where(
                (final t) =>
                    t.videoPath.equals(normalizedPath) &
                    (excludingMoveId == null
                        ? const Constant(true)
                        : t.id.isNotValue(excludingMoveId)),
              ))
              .get();
      if (moveRefs.isNotEmpty) {
        DiagnosticsLog.debug('MediaCleanup', '_isPathStillReferenced path="$normalizedPath" moveRefs=${moveRefs.length} => still referenced');
        return true;
      }

      final comboRefs =
          await (_db.select(_db.combos)..where(
                (final t) =>
                    t.activeVideoPath.equals(normalizedPath) &
                    (excludingComboId == null
                        ? const Constant(true)
                        : t.id.isNotValue(excludingComboId)),
              ))
              .get();
      if (comboRefs.isNotEmpty) {
        DiagnosticsLog.debug('MediaCleanup', '_isPathStillReferenced path="$normalizedPath" comboRefs=${comboRefs.length} => still referenced');
        return true;
      }
    }

    DiagnosticsLog.debug('MediaCleanup', '_isPathStillReferenced path="$normalizedPath" => NOT referenced (safe to delete)');
    return false;
  }

  Future<bool> _isHashStillReferenced({
    final String? contentHash,
    final String? excludingMoveId,
    final String? excludingComboId,
  }) async {
    if (contentHash == null || contentHash.isEmpty) return false;

    final moveHashRefs =
        await (_db.select(_db.moves)..where(
              (final t) =>
                  t.contentHash.equals(contentHash) &
                  (excludingMoveId == null
                      ? const Constant(true)
                      : t.id.isNotValue(excludingMoveId)),
            ))
            .get();
    if (moveHashRefs.isNotEmpty) {
      DiagnosticsLog.debug('MediaCleanup', '_isHashStillReferenced hash=$contentHash moveHashRefs=${moveHashRefs.length} => still referenced');
      return true;
    }

    final comboHashRefs =
        await (_db.select(_db.combos)..where(
              (final t) =>
                  t.contentHash.equals(contentHash) &
                  (excludingComboId == null
                      ? const Constant(true)
                      : t.id.isNotValue(excludingComboId)),
            ))
            .get();
    if (comboHashRefs.isNotEmpty) {
      DiagnosticsLog.debug('MediaCleanup', '_isHashStillReferenced hash=$contentHash comboHashRefs=${comboHashRefs.length} => still referenced');
      return true;
    }

    DiagnosticsLog.debug('MediaCleanup', '_isHashStillReferenced hash=$contentHash => NOT referenced (safe to tombstone)');
    return false;
  }

  Future<void> _tombstoneAsset(final String contentHash) async {
    final manifest = await _db.assetManifestDao.getByHash(contentHash);
    if (manifest == null) {
      DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => no manifest (skip)');
      return;
    }
    if (manifest.deletedAt != null) {
      DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => already tombstoned (skip)');
      return;
    }

    DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => executing tombstone...');
    await _db.assetManifestDao.updateLocalState(
      contentHash,
      localPath: const Value(null),
      localVerifiedAt: const Value(null),
    );
    await _db.assetManifestDao.softDelete(contentHash, 'user');
    DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => manifest tombstoned');

    final localCopy = await _db.assetCopiesDao.getLocalCopy(contentHash);
    if (localCopy != null) {
      await _db.assetCopiesDao.updateCopy(
        AssetCopiesCompanion(
          id: Value(localCopy.id),
          status: const Value('deleted'),
          verifiedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => local copy marked deleted');
    }
    DiagnosticsLog.debug('MediaCleanup', '_tombstoneAsset hash=$contentHash => DONE');
    await _db.assetManifestDao.updateCopyCount(contentHash);
  }
}
