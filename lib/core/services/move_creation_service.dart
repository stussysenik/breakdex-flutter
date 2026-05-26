import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/repositories.dart';
import '../database/database.dart';
import '../models/move_creation.dart';
import 'native_video_album.dart';
import 'reviewable_naming_service.dart';
import 'video_path_resolver.dart';
import '../sync/asset_hash_service.dart';
import 'blackbox_service.dart';

typedef MoveVideoImportedHandler =
    Future<void> Function({required String localPath, required String moveId, String? precomputedHash});

class MoveCreationService {
  MoveCreationService({
    required MoveRepository moveRepository,
    required ReviewableNamingService namingService,
    required NativeVideoAlbum videoAlbum,
    required MoveVideoImportedHandler onVideoImported,
    required AssetHashService hashService,
    BlackboxService? blackbox,
    String Function()? idGenerator,
  }) : _moveRepository = moveRepository,
       _namingService = namingService,
       _videoAlbum = videoAlbum,
       _onVideoImported = onVideoImported,
       _hashService = hashService,
       _blackbox = blackbox,
       _idGenerator = idGenerator ?? (() => const Uuid().v4());

  final MoveRepository _moveRepository;
  final ReviewableNamingService _namingService;
  final NativeVideoAlbum _videoAlbum;
  final MoveVideoImportedHandler _onVideoImported;
  final AssetHashService _hashService;
  final BlackboxService? _blackbox;
  final String Function() _idGenerator;

  Future<CreateMoveResult> createMove(CreateMoveRequest request) async {
    final normalizedName = _namingService.normalize(request.name);
    final normalizedCategory = request.category.trim();

    if (normalizedName.isEmpty) {
      throw StateError('empty_move_name');
    }
    if (normalizedCategory.isEmpty) {
      throw StateError('empty_move_category');
    }

    final isTaken = await _namingService.isNameTaken(normalizedName);
    if (isTaken) {
      throw StateError('duplicate_card_name');
    }

    // Generate or derive Move ID (Prefer SHA-256 hash for unified identity)
    String moveId;
    String? contentHash;
    if (request.localVideoPath != null) {
      contentHash = await _hashService.computeHash(request.localVideoPath!);
      moveId = contentHash;
    } else {
      moveId = _idGenerator();
    }

    final ext = request.localVideoPath != null ? p.extension(request.localVideoPath!) : '.mp4';
    final semanticRelative = VideoPathResolver.semanticVideoPath(
      normalizedCategory,
      normalizedName,
      ext,
    );

    // If we have a local path, move it to semantic path IMMEDIATELY
    String? storedVideoPath;
    String? finalAbsPath;
    if (request.localVideoPath != null) {
      final targetAbs = VideoPathResolver.toAbsolute(semanticRelative);
      final targetFile = File(targetAbs);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      await File(request.localVideoPath!).rename(targetAbs);
      storedVideoPath = semanticRelative;
      finalAbsPath = targetAbs;
    }

    // Blackbox safety log
    await _blackbox?.log('create_move', 'move', moveId, {
      'name': normalizedName,
      'category': normalizedCategory,
      'hash': contentHash,
    });

    await _moveRepository.insert(
      MovesCompanion.insert(
        id: moveId,
        name: normalizedName,
        category: Value(normalizedCategory),
        videoPath: Value(storedVideoPath),
        originalVideoName: Value(request.originalVideoName),
        contentHash: Value(contentHash),
        count: Value(request.count),
        learningState: Value(request.learningState),
      ),
    );

    await _storeManagedAlbumCopyIfPresent(
      moveId: moveId,
      title: normalizedName,
      category: normalizedCategory,
      localVideoPath: finalAbsPath,
    );

    if (finalAbsPath != null) {
      unawaited(
        _onVideoImported(
          localPath: finalAbsPath,
          moveId: moveId,
          precomputedHash: contentHash,
        ).catchError(
          (Object error, StackTrace stackTrace) =>
              debugPrint('Move creation sync hook failed (non-fatal): $error'),
        ),
      );
    }

    return CreateMoveResult(
      moveId: moveId,
      name: normalizedName,
      category: normalizedCategory,
      videoPath: storedVideoPath,
    );
  }

  String _normalizeCategory(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'default' : normalized;
  }

  Future<void> _storeManagedAlbumCopyIfPresent({
    required String moveId,
    required String title,
    required String category,
    required String? localVideoPath,
  }) async {
    if (localVideoPath == null) return;

    try {
      final managedCopy = await _videoAlbum.saveToAlbum(
        videoPath: localVideoPath,
        albumName: NativeVideoAlbum.defaultAlbumName(),
        assetTitle: title,
        category: category,
      );

      if (managedCopy == null) return;

      await _moveRepository.update(
        MovesCompanion(
          id: Value(moveId),
          managedAlbumAssetId: Value(managedCopy.assetLocalIdentifier),
          managedAlbumFilename: Value(managedCopy.filename),
          managedAlbumName: Value(managedCopy.albumName),
        ),
      );
    } catch (error) {
      debugPrint('Move creation album save failed (non-fatal): $error');
    }
  }
}
