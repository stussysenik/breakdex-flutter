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
import 'storage_action_machine.dart';
import '../models/canonical_path.dart';

typedef MoveVideoImportedHandler =
    Future<void> Function({required String localPath, required String moveId, String? precomputedHash});

class MoveCreationService {
  MoveCreationService({
    required final MoveRepository moveRepository,
    required final ReviewableNamingService namingService,
    required final MoveVideoImportedHandler onVideoImported,
    required final StorageActionMachine storageEngine,
    required final FsrsCardsDao fsrsCardsDao,
    final BlackboxService? blackbox,
    final String Function()? idGenerator,
  }) : _moveRepository = moveRepository,
       _namingService = namingService,
       _onVideoImported = onVideoImported,
       _storageEngine = storageEngine,
       _fsrsCardsDao = fsrsCardsDao,
       _blackbox = blackbox,
       _idGenerator = idGenerator ?? (() => const Uuid().v4());

  final MoveRepository _moveRepository;
  final ReviewableNamingService _namingService;
  final MoveVideoImportedHandler _onVideoImported;
  final StorageActionMachine _storageEngine;
  final FsrsCardsDao _fsrsCardsDao;
  final BlackboxService? _blackbox;
  final String Function() _idGenerator;

  Future<CreateMoveResult> createMove(final CreateMoveRequest request) async {
    final normalizedName = _namingService.normalize(request.name);
    final normalizedCategory = request.category.trim();

    if (normalizedName.isEmpty) throw StateError('empty_move_name');
    if (normalizedCategory.isEmpty) throw StateError('empty_move_category');

    final isTaken = await _namingService.isNameTaken(normalizedName);
    if (isTaken) throw StateError('duplicate_card_name');

    CanonicalPath? storedVideoPath;
    String? moveId;
    String? contentHash;

    // 1. Materialize via Engine (Hashing + Moving)
    if (request.localVideoPath != null) {
      storedVideoPath = await _storageEngine.execute(MaterializeAction(
        sourcePath: request.localVideoPath!,
        category: normalizedCategory,
        moveName: normalizedName,
      ));
      
      // Identity is derived from the materialized path (which contains the hash)
      final filename = p.basenameWithoutExtension(storedVideoPath.value);
      contentHash = filename.split(' - ').last;
      moveId = contentHash;
    } else {
      moveId = _idGenerator();
    }

    // 2. Commit Truth to DB
    await _moveRepository.insert(
      MovesCompanion.insert(
        id: moveId,
        name: normalizedName,
        category: Value(normalizedCategory),
        videoPath: Value(storedVideoPath?.value),
        originalVideoName: Value(request.originalVideoName),
        videoFileSize: Value(request.videoFileSize != null ? BigInt.from(request.videoFileSize!) : null),
        videoCreationDate: Value(request.videoCreationDate),
        contentHash: Value(contentHash),
        count: Value(request.count),
        learningState: Value(request.learningState),
      ),
    );

    await _blackbox?.log('create_move', 'move', moveId, {
      'name': normalizedName,
      'category': normalizedCategory,
      'hash': contentHash,
    });

    unawaited(_fsrsCardsDao.ensureCard(moveId, entityType: 'move'));

    if (storedVideoPath != null) {
      final finalAbs = VideoPathResolver.toAbsolute(storedVideoPath.value);
      unawaited(_onVideoImported(
        localPath: finalAbs,
        moveId: moveId,
        precomputedHash: contentHash,
      ).catchError((final e) => debugPrint('[SyncHook] Failed: $e')));
    }

    return CreateMoveResult(
      moveId: moveId,
      name: normalizedName,
      category: normalizedCategory,
      videoPath: storedVideoPath?.value,
    );
  }
}
