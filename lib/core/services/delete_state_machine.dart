// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import 'package:breakdex/core/platform/io.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:breakdex/core/database/daos/asset_copies_dao.dart';
import 'package:breakdex/core/database/daos/asset_manifest_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/safety_guard.dart';
import 'package:breakdex/core/services/canonical_folder_service.dart';

enum DeletePhase {
  idle,
  safetyCheck,
  softDeleting,
  trashed,
  restoring,
  hardDeleting,
  complete,
  failed,
}

class DeleteStateMachine {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final CanonicalFolderService _folderService;
  final SafetyGuard _safetyGuard;

  final _stateController = StreamController<DeleteState>.broadcast();
  DeleteState _current = const DeleteState.idle();

  DeleteState get state => _current;
  Stream<DeleteState> get stateStream => _stateController.stream;

  DeleteStateMachine({
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final CanonicalFolderService folderService,
    required final SafetyGuard safetyGuard,
  }) : _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _folderService = folderService,
       _safetyGuard = safetyGuard;

  Future<void> trash(final String hash, {final String reason = 'user'}) async {
    _transition(DeletePhase.safetyCheck);
    try {
      final manifest = await _manifestDao.getByHash(hash);
      if (manifest == null) throw _DeleteException('Asset not found: $hash');
      if (manifest.deletedAt != null) {
        throw _DeleteException('Asset already trashed: $hash');
      }

      _transition(DeletePhase.softDeleting);
      await _manifestDao.softDelete(hash, reason);
      await _folderService.removeLedgerEntry(hash);

      const daysLeft = 30;
      _transition(DeletePhase.trashed, daysUntilPurge: daysLeft);
    } catch (e) {
      _transition(DeletePhase.failed, error: '$e');
      rethrow;
    }
  }

  Future<void> restore(final String hash) async {
    _transition(DeletePhase.restoring);
    try {
      final manifest = await _manifestDao.getByHash(hash);
      if (manifest == null) throw _DeleteException('Asset not found: $hash');
      if (manifest.deletedAt == null) {
        throw _DeleteException('Asset is not trashed: $hash');
      }

      final graceEnd = manifest.deletedAt!.add(const Duration(days: 30));
      if (DateTime.now().isAfter(graceEnd)) {
        throw const _DeleteException('Grace period expired — asset cannot be restored');
      }

      await _manifestDao.upsert(
        AssetManifestCompanion.insert(
          contentHash: hash,
          fileSizeBytes: manifest.fileSizeBytes,
          localPath: Value(manifest.localPath),
          sourceType: manifest.sourceType,
          sourceName: Value(manifest.sourceName),
          importedAt: manifest.importedAt,
          mimeType: Value(manifest.mimeType),
        ),
      );

      _transition(DeletePhase.complete);
    } catch (e) {
      _transition(DeletePhase.failed, error: '$e');
      rethrow;
    }
  }

  Future<void> hardDelete(final String hash) async {
    _transition(DeletePhase.safetyCheck);
    try {
      final manifest = await _manifestDao.getByHash(hash);
      if (manifest == null) throw _DeleteException('Asset not found: $hash');

      final verifiedCopies = await _copiesDao.countVerified(hash);
      final canDelete = await _safetyGuard.canDeleteLocal(hash);
      if (verifiedCopies < 2 && !canDelete) {
        throw _DeleteException(
          'Safety check failed: asset has only $verifiedCopies verified '
          'copy(s). Minimum 2 required for hard delete. Use trash for '
          'safe deletion with a 30-day grace period.',
        );
      }

      _transition(DeletePhase.hardDeleting);

      if (manifest.localPath != null) {
        try {
          final file = File(manifest.localPath!);
          if (await file.exists()) await file.delete();
        } on Object catch (e) {
          debugPrint('[DeleteStateMachine] File delete failed: $e');
        }
      }

      await _copiesDao.deleteByHash(hash);
      await _folderService.removeLedgerEntry(hash);
      await _manifestDao.hardDelete(hash);

      _transition(DeletePhase.complete);
    } catch (e) {
      _transition(DeletePhase.failed, error: '$e');
      rethrow;
    }
  }

  Future<int> purgeExpired() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final expired = await _manifestDao.getTombstonedBefore(cutoff);

    var purged = 0;
    for (final manifest in expired) {
      try {
        final hash = manifest.contentHash;
        if (manifest.localPath != null) {
          try {
            final file = File(manifest.localPath!);
            if (await file.exists()) await file.delete();
          } on Object catch (_) {}
        }
        await _copiesDao.deleteByHash(hash);
        await _folderService.removeLedgerEntry(hash);
        await _manifestDao.hardDelete(hash);
        purged++;
      } on Object catch (e) {
        debugPrint('[DeleteStateMachine] Purge failed for $manifest.contentHash: $e');
      }
    }
    return purged;
  }

  Future<int?> daysUntilPurge(final String hash) async {
    final manifest = await _manifestDao.getByHash(hash);
    if (manifest == null || manifest.deletedAt == null) return null;
    final graceEnd = manifest.deletedAt!.add(const Duration(days: 30));
    return DateTime.now().isBefore(graceEnd)
        ? graceEnd.difference(DateTime.now()).inDays
        : 0;
  }

  void _transition(final DeletePhase phase, {final int? daysUntilPurge, final String? error}) {
    _current = DeleteState(
      phase: phase,
      daysUntilPurge: daysUntilPurge ?? _current.daysUntilPurge,
      error: error,
    );
    _stateController.add(_current);
  }

  void dispose() {
    _stateController.close();
  }
}

class DeleteState {
  final DeletePhase phase;
  final int daysUntilPurge;
  final String? error;

  const DeleteState({
    this.phase = DeletePhase.idle,
    this.daysUntilPurge = 30,
    this.error,
  });

  const DeleteState.idle()
    : phase = DeletePhase.idle,
      daysUntilPurge = 30,
      error = null;

  bool get isTerminal => phase == DeletePhase.complete || phase == DeletePhase.failed;
  bool get isTrashed => phase == DeletePhase.trashed;
  bool get hasError => phase == DeletePhase.failed || error != null;
}

class _DeleteException implements Exception {
  final String message;
  const _DeleteException(this.message);
  @override
  String toString() => message;
}
