import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../models/reviewable_item.dart';
import 'native_video_album.dart';
import 'video_path_resolver.dart';
import 'video_service.dart';

class MediaCleanupService {
  MediaCleanupService({
    required AppDatabase db,
    required VideoService videoService,
    NativeVideoAlbum? videoAlbum,
  }) : _db = db,
       _videoService = videoService,
       _videoAlbum = videoAlbum ?? NativeVideoAlbum();

  final AppDatabase _db;
  final VideoService _videoService;
  final NativeVideoAlbum _videoAlbum;

  Future<void> cleanupMoveMedia(Move move) {
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

  Future<void> cleanupComboMedia(Combo combo) {
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
    required String title,
    String? category,
    String? storedVideoPath,
    String? resolvedVideoPath,
    String? contentHash,
    String? managedAlbumAssetId,
    String? excludingMoveId,
    String? excludingComboId,
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
    );
  }

  Future<void> _cleanupAsset({
    required String title,
    String? category,
    String? storedVideoPath,
    String? resolvedVideoPath,
    String? contentHash,
    String? managedAlbumAssetId,
    String? excludingMoveId,
    String? excludingComboId,
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
    if (!pathStillReferenced &&
        pathForCleanup != null &&
        pathForCleanup.trim().isNotEmpty) {
      try {
        await _videoService.deleteVideo(pathForCleanup);
      } catch (error) {
        debugPrint('Local video cleanup failed for $title: $error');
      }

      try {
        await _videoAlbum.deleteManagedCopies(
          assetTitle: title,
          category: category,
          fileExtension: p.extension(pathForCleanup),
          assetLocalIdentifier: managedAlbumAssetId,
        );
      } catch (error) {
        debugPrint('Album cleanup failed for $title: $error');
      }
    }

    if (hashStillReferenced ||
        contentHash == null ||
        contentHash.trim().isEmpty) {
      return;
    }
    await _tombstoneAsset(contentHash);
  }

  Future<bool> _isPathStillReferenced({
    String? storedVideoPath,
    String? excludingMoveId,
    String? excludingComboId,
  }) async {
    final normalizedPath = storedVideoPath == null || storedVideoPath.isEmpty
        ? null
        : VideoPathResolver.toRelative(storedVideoPath);

    if (normalizedPath != null) {
      final moveRefs =
          await (_db.select(_db.moves)..where(
                (t) =>
                    t.videoPath.equals(normalizedPath) &
                    (excludingMoveId == null
                        ? const Constant(true)
                        : t.id.isNotValue(excludingMoveId)),
              ))
              .get();
      if (moveRefs.isNotEmpty) return true;

      final comboRefs =
          await (_db.select(_db.combos)..where(
                (t) =>
                    t.activeVideoPath.equals(normalizedPath) &
                    (excludingComboId == null
                        ? const Constant(true)
                        : t.id.isNotValue(excludingComboId)),
              ))
              .get();
      if (comboRefs.isNotEmpty) return true;
    }

    return false;
  }

  Future<bool> _isHashStillReferenced({
    String? contentHash,
    String? excludingMoveId,
    String? excludingComboId,
  }) async {
    if (contentHash == null || contentHash.isEmpty) return false;

    final moveHashRefs =
        await (_db.select(_db.moves)..where(
              (t) =>
                  t.contentHash.equals(contentHash) &
                  (excludingMoveId == null
                      ? const Constant(true)
                      : t.id.isNotValue(excludingMoveId)),
            ))
            .get();
    if (moveHashRefs.isNotEmpty) return true;

    final comboHashRefs =
        await (_db.select(_db.combos)..where(
              (t) =>
                  t.contentHash.equals(contentHash) &
                  (excludingComboId == null
                      ? const Constant(true)
                      : t.id.isNotValue(excludingComboId)),
            ))
            .get();
    return comboHashRefs.isNotEmpty;
  }

  Future<void> _tombstoneAsset(String contentHash) async {
    final manifest = await _db.assetManifestDao.getByHash(contentHash);
    if (manifest == null || manifest.deletedAt != null) return;

    await _db.assetManifestDao.upsert(
      AssetManifestCompanion(
        contentHash: Value(contentHash),
        localPath: const Value(null),
        localVerifiedAt: const Value(null),
      ),
    );
    await _db.assetManifestDao.softDelete(contentHash, 'user');

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
    }

    await _db.assetManifestDao.updateCopyCount(contentHash);
  }
}
