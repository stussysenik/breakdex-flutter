// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import '../database/database.dart';
import '../sync/asset_hash_service.dart';
import 'canonical_folder_service.dart';
import 'video_path_resolver.dart';

class ReconcileReport {
  final List<ReconciledFile> diskOrphans;
  final List<ReconciledAsset> dbOrphans;
  final int photosRecovered;
  final int photosUnrecovered;
  final int filesScanned;
  final int manifestEntriesChecked;
  final DateTime completedAt;

  const ReconcileReport({
    required this.diskOrphans,
    required this.dbOrphans,
    this.photosRecovered = 0,
    this.photosUnrecovered = 0,
    required this.filesScanned,
    required this.manifestEntriesChecked,
    required this.completedAt,
  });

  bool get isClean =>
      diskOrphans.isEmpty && dbOrphans.isEmpty && photosUnrecovered == 0;
  bool get needsAttention => diskOrphans.isNotEmpty || dbOrphans.isNotEmpty;
}

class ReconciledFile {
  final String path;
  final String fileName;
  final int fileSizeBytes;
  final DateTime modifiedAt;
  final bool wasImported;

  const ReconciledFile({
    required this.path,
    required this.fileName,
    required this.fileSizeBytes,
    required this.modifiedAt,
    this.wasImported = false,
  });
}

class ReconciledAsset {
  final String hash;
  final String? expectedPath;
  final String? sourceName;
  final bool hasCloudCopies;
  final bool wasRecovered;

  const ReconciledAsset({
    required this.hash,
    this.expectedPath,
    this.sourceName,
    this.hasCloudCopies = false,
    this.wasRecovered = false,
  });
}

class CanonicalReconcileService {
  final CanonicalFolderService _folderService;
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;

  CanonicalReconcileService({
    required final CanonicalFolderService folderService,
    required final AssetManifestDao manifestDao,
    required final AssetCopiesDao copiesDao,
    required final AssetHashService hashService,
  }) : _folderService = folderService,
       _manifestDao = manifestDao,
       _copiesDao = copiesDao,
       _hashService = hashService;

  Future<ReconcileReport> scan() async {
    final diskOrphans = <ReconciledFile>[];
    final dbOrphans = <ReconciledAsset>[];
    final now = DateTime.now();

    final scanResults = await _folderService.scanOrphans();
    for (final result in scanResults) {
      if (result.isOrphan) {
        diskOrphans.add(ReconciledFile(
          path: result.path,
          fileName: result.fileName,
          fileSizeBytes: result.fileSizeBytes,
          modifiedAt: result.modifiedAt,
        ));
      }
    }

    final allManifests = await _manifestDao.getAll();
    for (final manifest in allManifests) {
      if (manifest.deletedAt != null) continue;
      if (manifest.localPath == null) {
        final copies = await _copiesDao.getByHash(manifest.contentHash);
        dbOrphans.add(ReconciledAsset(
          hash: manifest.contentHash,
          sourceName: manifest.sourceName,
          hasCloudCopies: copies.any((final c) => c.status == 'verified'),
        ));
        continue;
      }

      final absolutePath = VideoPathResolver.toAbsolute(manifest.localPath!);
      final file = File(absolutePath);
      if (!await file.exists()) {
        final copies = await _copiesDao.getByHash(manifest.contentHash);
        dbOrphans.add(ReconciledAsset(
          hash: manifest.contentHash,
          expectedPath: absolutePath,
          sourceName: manifest.sourceName,
          hasCloudCopies: copies.any((final c) => c.status == 'verified'),
        ));
      }
    }

    return ReconcileReport(
      diskOrphans: diskOrphans,
      dbOrphans: dbOrphans,
      filesScanned: scanResults.length,
      manifestEntriesChecked: allManifests.length,
      completedAt: now,
    );
  }

  Future<int> importOrphans(final List<ReconciledFile> orphans) async {
    var imported = 0;
    for (final orphan in orphans) {
      try {
        final file = File(orphan.path);
        if (!await file.exists()) continue;
        final hash = await _hashService.computeHash(orphan.path);
        final stat = await file.stat();

        final existing = await _manifestDao.getByHash(hash);
        if (existing != null) {
          await _manifestDao.updateLocalState(
            hash,
            localPath: Value(VideoPathResolver.toRelative(orphan.path)),
            localVerifiedAt: Value(DateTime.now()),
          );
        } else {
          final now = DateTime.now();
          await _manifestDao.upsert(
            AssetManifestCompanion.insert(
              contentHash: hash,
              fileSizeBytes: stat.size,
              localPath: Value(VideoPathResolver.toRelative(orphan.path)),
              localVerifiedAt: Value(now),
              sourceType: 'files',
              sourceName: Value(orphan.fileName),
              importedAt: now,
            ),
          );
          final copyId = '${hash}_local';
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
        }

        await _folderService.upsertLedgerEntry(
          LedgerEntry(
            fileName: orphan.fileName,
            fileSizeBytes: stat.size,
            lastSeenAt: stat.modified,
            recordedAt: DateTime.now(),
          ),
        );
        imported++;
      } on Object catch (e) {
        debugPrint('[CanonicalReconcile] Import orphan failed for ${orphan.path}: $e');
      }
    }
    return imported;
  }

  Future<int> recoverOrphansLocally(final List<ReconciledAsset> orphans) async {
    var recovered = 0;
    for (final orphan in orphans) {
      if (orphan.expectedPath == null) continue;
      final file = File(orphan.expectedPath!);
      if (!await file.exists()) continue;
      try {
        final verified = await _hashService.verifyHash(
          orphan.expectedPath!,
          orphan.hash,
        );
        if (verified) {
          await _manifestDao.updateLocalState(
            orphan.hash,
            localPath: Value(VideoPathResolver.toRelative(orphan.expectedPath!)),
            localVerifiedAt: Value(DateTime.now()),
          );
          recovered++;
        }
      } on Object catch (_) {}
    }
    return recovered;
  }
}
