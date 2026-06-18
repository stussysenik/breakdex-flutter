import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../database/daos/asset_copies_dao.dart';
import '../database/daos/asset_manifest_dao.dart';
import 'asset_hash_service.dart';

/// Why a single file failed verification.
enum IntegrityIssueKind {
  /// File exists but its content hash no longer matches the manifest.
  mismatch,

  /// Manifest row has no local path (nothing on disk to check).
  missing,

  /// File could not be read/hashed (permissions, deleted mid-scan, I/O error).
  unreadable,
}

/// Per-file detail for a verification failure — what the debug UI renders.
class IntegrityIssue {
  final IntegrityIssueKind kind;
  final String contentHash;
  final String? localPath;

  /// The hash actually computed from disk (only for [IntegrityIssueKind.mismatch]).
  final String? actualHash;
  final String? error;

  const IntegrityIssue({
    required this.kind,
    required this.contentHash,
    required this.localPath,
    required this.actualHash,
    this.error,
  });
}

/// Result of an integrity verification run.
class IntegrityReport {
  final int filesChecked;
  final int filesOk;
  final int filesMismatched;
  final int filesMissing;

  /// Per-file failure detail. Empty when [allGood]. Populated for both
  /// mismatches and missing/unreadable files so the UI can show specifics.
  final List<IntegrityIssue> issues;

  const IntegrityReport({
    required this.filesChecked,
    required this.filesOk,
    required this.filesMismatched,
    required this.filesMissing,
    this.issues = const [],
  });

  bool get allGood => filesMismatched == 0 && filesMissing == 0;

  /// Content hashes of mismatched files — the set a "re-download" heal targets.
  List<String> get mismatchedHashes => issues
      .where((final i) => i.kind == IntegrityIssueKind.mismatch)
      .map((final i) => i.contentHash)
      .toList();
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
    final Random? random,
  }) : _random = random ?? Random();

  /// Run an integrity check on local files, returning per-file detail.
  ///
  /// [maxAge] controls which files are eligible in the sampled (background)
  /// mode — only files not verified within [maxAge] are candidates.
  ///
  /// [checkAll] = true hashes *every* live local file (ignoring sampling and
  /// staleness). Use this for the manual "debug" run so the counts reflect
  /// reality, not a random tenth.
  ///
  /// [heal] = true (the default, for background runs) mutates the database:
  /// clean files get their verified timestamp bumped, and mismatches mark the
  /// local copy `failed` so the sync engine re-downloads from cloud. Pass
  /// [heal] = false for a **read-only** scan that only reports — important for
  /// debugging, since blind re-download would overwrite local-only edits.
  Future<IntegrityReport> verify({
    final Duration maxAge = const Duration(days: 7),
    final bool checkAll = false,
    final bool heal = true,
  }) async {
    final candidates = checkAll
        ? await _manifestDao.getLocalAssets()
        : await _manifestDao.getStaleVerifications(maxAge);
    if (candidates.isEmpty) {
      return const IntegrityReport(
        filesChecked: 0,
        filesOk: 0,
        filesMismatched: 0,
        filesMissing: 0,
      );
    }

    final List<AssetManifestData> sample;
    if (checkAll) {
      sample = candidates;
    } else {
      // Sample 10% (minimum 1)
      final sampleSize = max(1, (candidates.length * _sampleFraction).ceil());
      candidates.shuffle(_random);
      sample = candidates.take(sampleSize).toList();
    }

    int ok = 0;
    final issues = <IntegrityIssue>[];

    for (final asset in sample) {
      final localPath = asset.localPath;
      if (localPath == null) {
        issues.add(IntegrityIssue(
          kind: IntegrityIssueKind.missing,
          contentHash: asset.contentHash,
          localPath: null,
          actualHash: null,
        ));
        continue;
      }

      String actualHash;
      try {
        actualHash = await _hashService.computeHash(localPath);
      } catch (e) {
        debugPrint('Integrity check error for ${asset.contentHash}: $e');
        issues.add(IntegrityIssue(
          kind: IntegrityIssueKind.unreadable,
          contentHash: asset.contentHash,
          localPath: localPath,
          actualHash: null,
          error: '$e',
        ));
        continue;
      }

      if (actualHash == asset.contentHash) {
        ok++;
        if (heal) {
          await _manifestDao.markLocalVerified(asset.contentHash);
        }
      } else {
        debugPrint(
          'Integrity mismatch: ${asset.contentHash} at $localPath '
          '(actual $actualHash)',
        );
        issues.add(IntegrityIssue(
          kind: IntegrityIssueKind.mismatch,
          contentHash: asset.contentHash,
          localPath: localPath,
          actualHash: actualHash,
        ));
        if (heal) {
          await _markForRedownload(asset.contentHash);
        }
      }
    }

    final mismatched =
        issues.where((final i) => i.kind == IntegrityIssueKind.mismatch).length;

    return IntegrityReport(
      filesChecked: sample.length,
      filesOk: ok,
      filesMismatched: mismatched,
      filesMissing: issues.length - mismatched,
      issues: issues,
    );
  }

  /// User-initiated heal: mark each asset's local copy `failed` so the sync
  /// engine re-downloads a clean copy from cloud. Returns the number healed.
  ///
  /// Destructive for local-only edits — the cloud copy wins — so this is only
  /// ever called explicitly from the integrity report, never automatically by
  /// a read-only scan.
  Future<int> healMismatches(final Iterable<String> contentHashes) async {
    var healed = 0;
    for (final hash in contentHashes) {
      await _markForRedownload(hash);
      healed++;
    }
    return healed;
  }

  Future<void> _markForRedownload(final String contentHash) async {
    final localCopy = await _copiesDao.getLocalCopy(contentHash);
    if (localCopy != null) {
      await _copiesDao.markFailed(
        localCopy.id,
        'Integrity verification failed: hash mismatch',
      );
    }
    await _manifestDao.updateCopyCount(contentHash);
  }
}
