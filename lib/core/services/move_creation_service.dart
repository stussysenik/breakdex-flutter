import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories.dart';
import '../database/database.dart';
import '../models/move_creation.dart';
import 'native_video_album.dart';
import 'reviewable_naming_service.dart';
import 'video_path_resolver.dart';

typedef MoveVideoImportedHandler =
    Future<void> Function({required String localPath, required String moveId});

class MoveCreationService {
  MoveCreationService({
    required MoveRepository moveRepository,
    required ReviewableNamingService namingService,
    required NativeVideoAlbum videoAlbum,
    required MoveVideoImportedHandler onVideoImported,
    String Function()? idGenerator,
  }) : _moveRepository = moveRepository,
       _namingService = namingService,
       _videoAlbum = videoAlbum,
       _onVideoImported = onVideoImported,
       _idGenerator = idGenerator ?? (() => const Uuid().v4());

  final MoveRepository _moveRepository;
  final ReviewableNamingService _namingService;
  final NativeVideoAlbum _videoAlbum;
  final MoveVideoImportedHandler _onVideoImported;
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

    final moveId = _idGenerator();
    final storedVideoPath = request.localVideoPath == null
        ? null
        : VideoPathResolver.toRelative(request.localVideoPath!);

    await _moveRepository.insert(
      MovesCompanion.insert(
        id: moveId,
        name: normalizedName,
        category: Value(normalizedCategory),
        videoPath: Value(storedVideoPath),
        originalVideoName: Value(request.originalVideoName),
        count: Value(request.count),
        learningState: Value(request.learningState),
      ),
    );

    // Move video to semantic path: Moves/{category}/{name}/video.{ext}
    String? finalVideoPath = storedVideoPath;
    if (storedVideoPath != null) {
      finalVideoPath = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: storedVideoPath,
        category: normalizedCategory,
        moveName: normalizedName,
      );
      if (finalVideoPath != storedVideoPath) {
        await _moveRepository.update(
          MovesCompanion(id: Value(moveId), videoPath: Value(finalVideoPath)),
        );
      }
    }

    await _storeManagedAlbumCopyIfPresent(
      moveId: moveId,
      title: normalizedName,
      category: normalizedCategory,
      localVideoPath: request.localVideoPath,
    );

    if (request.localVideoPath != null) {
      unawaited(
        _onVideoImported(
          localPath: request.localVideoPath!,
          moveId: moveId,
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

  Future<CreateMoveResult> createRecoveredMove(
    CreateRecoveredMoveRequest request,
  ) async {
    final normalizedCategory = _normalizeCategory(request.category);
    final normalizedName = await _namingService.nextAvailableName(
      request.preferredName,
    );
    final moveId = _idGenerator();
    final storedVideoPath = VideoPathResolver.toRelative(
      request.localVideoPath,
    );

    await _moveRepository.insert(
      MovesCompanion.insert(
        id: moveId,
        name: normalizedName,
        category: Value(normalizedCategory),
        videoPath: Value(storedVideoPath),
        originalVideoName: Value(request.originalVideoName),
        managedAlbumAssetId: Value(request.managedAlbumAssetId.trim()),
        managedAlbumFilename: Value(request.managedAlbumFilename.trim()),
        managedAlbumName: Value(request.managedAlbumName.trim()),
      ),
    );

    unawaited(
      _onVideoImported(
        localPath: request.localVideoPath,
        moveId: moveId,
      ).catchError(
        (Object error, StackTrace stackTrace) =>
            debugPrint('Recovered move sync hook failed (non-fatal): $error'),
      ),
    );

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
