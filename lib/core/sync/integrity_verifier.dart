import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import 'asset_hash_service.dart';

/// Result of an integrity verification run.
class IntegrityReport {
  final int filesChecked;
  final int filesOk;
  final int filesMismatched;
  final int filesMissing;

  const IntegrityReport({
    required this.filesChecked,
    required this.filesOk,
    required this.filesMismatched,
    required this.filesMissing,
  });

  bool get allGood => filesMismatched == 0 && filesMissing == 0;
}

/// Periodically re-hashes a random sample of local video files to detect
/// silent corruption (bit rot, incomplete writes, filesystem errors).
///
/// Design:
/// - Checks a random 10% of local files per run
/// - Mismatches mark the local copy as 'failed', triggering re-download
///   from cloud if available
/// - Updates `asset_manifest.local_verified_at` for clean files
/// - Intended to run weekly via background task (workmanager)
class IntegrityVerifier {
  final AssetManifestDao _manifestDao;
  final AssetCopiesDao _copiesDao;
  final AssetHashService _hashService;
  final Random _random;

  /// Fraction of files to check per run (10%).
  static const _sampleFraction = 0.10;

  IntegrityVerifier(
    this._manifestDao,
    this._copiesDao,
    this._hashService, {
    Random? random,
  }) : _random = random ?? Random();

  /// Run an integrity check on a random sample of local files.
  ///
  /// [maxAge] controls which files are eligible — only files not verified
  /// within [maxAge] are candidates. Defaults to 7 days.
  Future<IntegrityReport> verify({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final stale = await _manifestDao.getStaleVerifications(maxAge);
    if (stale.isEmpty) {
      return const IntegrityReport(
        filesChecked: 0,
        filesOk: 0,
        filesMismatched: 0,
        filesMissing: 0,
      );
    }

    // Sample 10% (minimum 1)
    final sampleSize = max(1, (stale.length * _sampleFraction).ceil());
    stale.shuffle(_random);
    final sample = stale.take(sampleSize).toList();

    int ok = 0;
    int mismatched = 0;
    int missing = 0;

    for (final asset in sample) {
      final localPath = asset.localPath;
      if (localPath == null) {
        missing++;
        continue;
      }

      try {
        final matches =
            await _hashService.verifyHash(localPath, asset.contentHash);
        if (matches) {
          ok++;
          await _manifestDao.markLocalVerified(asset.contentHash);
        } else {
          mismatched++;
          debugPrint(
            'Integrity mismatch: ${asset.contentHash} at $localPath',
          );
          // Mark the local copy as failed so sync engine can re-download
          final localCopy =
              await _copiesDao.getLocalCopy(asset.contentHash);
          if (localCopy != null) {
            await _copiesDao.markFailed(
              localCopy.id,
              'Integrity verification failed: hash mismatch',
            );
          }
          await _manifestDao.updateCopyCount(asset.contentHash);
        }
      } catch (e) {
        missing++;
        debugPrint('Integrity check error for ${asset.contentHash}: $e');
      }
    }

    return IntegrityReport(
      filesChecked: sample.length,
      filesOk: ok,
      filesMismatched: mismatched,
      filesMissing: missing,
    );
  }
}
