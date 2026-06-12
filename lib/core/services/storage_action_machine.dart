import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/canonical_path.dart';
import '../utils/diagnostics.dart';
import '../utils/filesystem_utils.dart';
import '../sync/asset_hash_service.dart';
import 'video_path_resolver.dart';

/// Sealed hierarchy of storage intents.
sealed class StorageAction {
  const StorageAction();
}

final class MaterializeAction extends StorageAction {
  final String sourcePath;
  final String category;
  final String moveName;
  const MaterializeAction({
    required this.sourcePath,
    required this.category,
    required this.moveName,
  });
}

final class DuplicateAction extends StorageAction {
  final CanonicalPath sourceRelative;
  final String newName;
  final String category;
  const DuplicateAction({
    required this.sourceRelative,
    required this.newName,
    required this.category,
  });
}

final class DeleteAction extends StorageAction {
  final CanonicalPath path;
  const DeleteAction(this.path);
}

/// Real-time progress state emitted by the [StorageActionMachine].
class StorageProgress {
  final double progress;
  final String stage;
  final bool isComplete;
  final String? error;

  const StorageProgress({
    required this.progress,
    required this.stage,
    this.isComplete = false,
    this.error,
  });

  factory StorageProgress.initial() => const StorageProgress(progress: 0, stage: 'Idle');
}

/// The "Engine" for all storage-related materialization.
///
/// Processes [StorageAction]s and emits a "Hot" byte-granular progress stream.
/// Enforces transactional integrity: file must be verified on disk before completion.
class StorageActionMachine {
  StorageActionMachine({
    required final AssetHashService hashService,
  }) : _hashService = hashService;

  final AssetHashService _hashService;
  final _progressController = StreamController<StorageProgress>.broadcast();

  Stream<StorageProgress> get progress => _progressController.stream;

  Future<CanonicalPath> execute(final StorageAction action) async {
    final logger = StageLogger.begin('StorageEngine', subsystem: 'StorageActionMachine');
    
    try {
      return await switch (action) {
        final MaterializeAction a => _handleMaterialize(a, logger),
        final DuplicateAction a => _handleDuplicate(a, logger),
        final DeleteAction a => _handleDelete(a, logger),
      };
    } catch (e, st) {
      logger.fail(e, st);
      _progressController.add(StorageProgress(progress: 0, stage: 'Error', error: e.toString()));
      rethrow;
    }
  }

  Future<CanonicalPath> _handleMaterialize(
    final MaterializeAction a, 
    final StageLogger logger,
  ) async {
    _emit(0.0, 'Scanning Identity');
    
    // 1. Compute Hash (0-40%)
    logger.stage('hashing');
    String? hash;
    await for (final event in _hashService.computeHashWithProgress(a.sourcePath)) {
      if (event is double) {
        _emit(event * 0.4, 'Analyzing Bytes');
      } else if (event is String) {
        hash = event;
      }
    }
    
    if (hash == null) throw Exception('Hashing failed: No output');
    final contentHash = ContentHash(hash);
    _emit(0.4, 'Identity Verified');

    // 2. Resolve Semantic Path
    final target = VideoPathResolver.semanticVideoPath(
      a.category, 
      a.moveName, 
      p.extension(a.sourcePath), 
      contentHash: contentHash,
    );
    final targetAbs = VideoPathResolver.toAbsolute(target.value);

    // 3. Materialize / Stream Move (40-90%)
    logger.stage('materializing');
    await for (final p in FileSystemUtils.moveFileWithProgress(a.sourcePath, targetAbs)) {
      _emit(0.4 + (p * 0.5), 'Moving Bytes');
    }
    
    _emit(0.9, 'Finalizing Integrity');
    
    // 4. Verify Final State
    if (!await File(targetAbs).exists()) {
      throw FileSystemException('Materialization failed: Target missing', targetAbs);
    }

    _emit(1.0, 'Success', isComplete: true);
    unawaited(HapticFeedback.heavyImpact());
    
    return target;
  }

  Future<CanonicalPath> _handleDuplicate(
    final DuplicateAction a, 
    final StageLogger logger,
  ) async {
    _emit(0.1, 'Locating Source');
    final sourceAbs = VideoPathResolver.toAbsolute(a.sourceRelative.value);
    
    // 1. Re-verify Hash (Safety first)
    logger.stage('verifying_source');
    final hash = await _hashService.computeHash(sourceAbs);
    final contentHash = ContentHash(hash);
    
    // 2. Prepare Target
    final target = VideoPathResolver.semanticVideoPath(
      a.category, 
      a.newName, 
      p.extension(sourceAbs), 
      contentHash: contentHash,
    );
    final targetAbs = VideoPathResolver.toAbsolute(target.value);

    // 3. Copy (Isolate-offloaded)
    logger.stage('copying');
    _emit(0.3, 'Duplicating Bytes');
    await FileSystemUtils.copyFileBackground(sourceAbs, targetAbs);
    
    _emit(1.0, 'Success', isComplete: true);
    unawaited(HapticFeedback.mediumImpact());
    
    return target;
  }

  Future<CanonicalPath> _handleDelete(
    final DeleteAction a, 
    final StageLogger logger,
  ) async {
    logger.stage('deleting');
    final abs = VideoPathResolver.toAbsolute(a.path.value);
    final file = File(abs);
    
    if (await file.exists()) {
      await file.delete();
      DiagnosticsLog.info('StorageEngine', '[PURGE] Deleted: ${a.path.value}');
    }
    
    // Always prune empty folders
    await FileSystemUtils.pruneEmptyParents(
      abs, 
      stopDir: p.join(VideoPathResolver.documentsPath, 'Moves'),
    );
    
    return a.path;
  }

  void _emit(final double p, final String stage, {final bool isComplete = false}) {
    _progressController.add(StorageProgress(progress: p, stage: stage, isComplete: isComplete));
  }

  void dispose() {
    _progressController.close();
  }
}

final storageActionMachineProvider = Provider<StorageActionMachine>((final ref) {
  final machine = StorageActionMachine(
    hashService: ref.watch(assetHashServiceProvider),
  );
  ref.onDispose(machine.dispose);
  return machine;
});

final assetHashServiceProvider = Provider<AssetHashService>((final _) => AssetHashService());
