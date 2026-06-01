import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/daos/asset_manifest_dao.dart';
import '../sync/asset_hash_service.dart';
import '../utils/loading_state_machine.dart';

sealed class GateResult {
  const GateResult();
}

class GateAllowed extends GateResult {
  final String hash;
  const GateAllowed({required this.hash});
}

class GateDuplicateContent extends GateResult {
  final String existingHash;
  final String existingName;

  const GateDuplicateContent({
    required this.existingHash,
    required this.existingName,
  });
}

class GateNameConflict extends GateResult {
  final String conflictingName;
  const GateNameConflict({required this.conflictingName});
}

class GateBlocked extends GateResult {
  final String reason;
  const GateBlocked({required this.reason});
}

class CanonicalImportGate {
  final AssetManifestDao _manifestDao;
  final AssetHashService _hashService;

  CanonicalImportGate({
    required final AssetManifestDao manifestDao,
    required final AssetHashService hashService,
  }) : _manifestDao = manifestDao,
       _hashService = hashService;

  Future<GateResult> check({
    required final String sourcePath,
    required final String displayName,
    final Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final hash = await _hashService
          .computeHash(sourcePath)
          .timeout(timeout, onTimeout: () => throw _GateTimeoutException());

      final existingManifest = await _manifestDao
          .getByHash(hash)
          .timeout(const Duration(seconds: 5));
      if (existingManifest != null && existingManifest.deletedAt == null) {
        return GateDuplicateContent(
          existingHash: hash,
          existingName: existingManifest.sourceName ?? hash.substring(0, 8),
        );
      }

      return GateAllowed(hash: hash);
    } on _GateTimeoutException {
      return const GateBlocked(
        reason: 'Import timed out — the file may still be downloading from '
            'iCloud. Try again once the download completes.',
      );
    } catch (e) {
      debugPrint('[CanonicalImportGate] Check failed: $e');
      return GateBlocked(reason: 'Unable to validate file: $e');
    }
  }

  Future<String?> checkNameConflict(final String displayName) async {
    try {
      final all = await _manifestDao.getAll();
      final normalized = displayName.toLowerCase().trim();
      for (final entry in all) {
        if (entry.deletedAt != null) continue;
        final existing = (entry.sourceName ?? '').toLowerCase().trim();
        if (existing == normalized) {
          return entry.sourceName!;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  LoadingStateController<GateResult> checkWithState({
    required final String sourcePath,
    required final String displayName,
    final Duration timeout = const Duration(seconds: 30),
  }) {
    final controller = LoadingStateController<GateResult>(maxAttempts: 1);
    _runGateCheck(controller, sourcePath, displayName, timeout);
    return controller;
  }

  Future<void> _runGateCheck(
    final LoadingStateController<GateResult> controller,
    final String sourcePath,
    final String displayName,
    final Duration timeout,
  ) async {
    controller.send(LoadingEvent.start);
    final result = await check(
      sourcePath: sourcePath,
      displayName: displayName,
      timeout: timeout,
    );
    switch (result) {
      case GateAllowed():
        controller.send(LoadingEvent.complete(result));
      case GateDuplicateContent():
        controller.send(LoadingEvent.fail(
          'Duplicate: already in library as "${result.existingName}"',
          retryable: false,
        ));
      case GateNameConflict():
        controller.send(LoadingEvent.fail(
          'Name conflict: "${result.conflictingName}" already exists',
          retryable: false,
        ));
      case GateBlocked():
        controller.send(LoadingEvent.fail(
          result.reason,
          retryable: true,
        ));
    }
  }
}

class _GateTimeoutException implements Exception {
  @override
  String toString() => 'Gate check timed out';
}

class SandboxMigrationEngine {
  final String _sandboxDir;
  final CanonicalImportGate _gate;

  Stream<int> get progress => _progressController.stream;
  final StreamController<int> _progressController = StreamController<int>.broadcast();

  int _migratedCount = 0;
  int _skippedCount = 0;
  int _errorCount = 0;

  SandboxMigrationEngine({
    required final String documentsPath,
    required final CanonicalImportGate gate,
  }) : _sandboxDir = p.join(documentsPath, 'Moves'),
       _gate = gate;

  Future<SandboxMigrationResult> migrate() async {
    final sandbox = Directory(_sandboxDir);
    if (!await sandbox.exists()) {
      return const SandboxMigrationResult(migrated: 0, skipped: 0, errors: 0);
    }

    final files = <File>[];
    await for (final entity in sandbox.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        files.add(entity);
      }
    }

    _progressController.add(0);

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final gateResult = await _gate.check(
          sourcePath: file.path,
          displayName: p.basenameWithoutExtension(file.path),
        );

        if (gateResult is GateAllowed) {
          _migratedCount++;
        } else if (gateResult is GateDuplicateContent) {
          try {
            await file.delete();
          } catch (_) {}
          _skippedCount++;
        } else {
          _skippedCount++;
        }
      } catch (e) {
        debugPrint('[SandboxMigration] Error migrating ${file.path}: $e');
        _errorCount++;
      }

      _progressController.add(i + 1);
    }

    return SandboxMigrationResult(
      migrated: _migratedCount,
      skipped: _skippedCount,
      errors: _errorCount,
    );
  }

  void dispose() {
    _progressController.close();
  }
}

class SandboxMigrationResult {
  final int migrated;
  final int skipped;
  final int errors;

  const SandboxMigrationResult({
    required this.migrated,
    required this.skipped,
    required this.errors,
  });

  int get total => migrated + skipped + errors;
  bool get allSuccess => errors == 0;
}
