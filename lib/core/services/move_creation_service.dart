import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/repositories.dart';
import '../database/database.dart';
import '../database/daos/fsrs_cards_dao.dart';
import '../models/move_creation.dart';
import '../utils/diagnostics.dart';
import '../utils/filesystem_utils.dart';
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
    required MoveVideoImportedHandler onVideoImported,
    required AssetHashService hashService,
    required FsrsCardsDao fsrsCardsDao,
    BlackboxService? blackbox,
    String Function()? idGenerator,
  }) : _moveRepository = moveRepository,
       _namingService = namingService,
       _onVideoImported = onVideoImported,
       _hashService = hashService,
       _fsrsCardsDao = fsrsCardsDao,
       _blackbox = blackbox,
       _idGenerator = idGenerator ?? (() => const Uuid().v4());

  final MoveRepository _moveRepository;
  final ReviewableNamingService _namingService;
  final MoveVideoImportedHandler _onVideoImported;
  final AssetHashService _hashService;
  final FsrsCardsDao _fsrsCardsDao;
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
      contentHash: contentHash ?? moveId,
    );

    // If we have a local path, move it to semantic path IMMEDIATELY
    String? storedVideoPath;
    String? finalAbsPath;
    if (request.localVideoPath != null) {
      final targetAbs = VideoPathResolver.toAbsolute(semanticRelative);
      try {
        await FileSystemUtils.safeMove(request.localVideoPath!, targetAbs);
        storedVideoPath = semanticRelative;
        finalAbsPath = targetAbs;
      } catch (e) {
        DiagnosticsLog.error('MoveCreationService', 'Failed to move video to $targetAbs: $e');
        // Fallback: use the temporary path for now if move failed but we MUST proceed?
        // Actually, safeMove should handle fallback to copy, so if it fails, it's a real issue.
        // We rethrow to prevent inconsistent DB state (move with no valid video path).
        rethrow;
      }
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
        videoFileSize: Value(request.videoFileSize != null ? BigInt.from(request.videoFileSize!) : null),
        videoCreationDate: Value(request.videoCreationDate),
        contentHash: Value(contentHash),
        count: Value(request.count),
        learningState: Value(request.learningState),
      ),
    );

    unawaited(
      _fsrsCardsDao.ensureCard(moveId, entityType: 'move'),
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
}
