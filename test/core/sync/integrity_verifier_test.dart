import 'dart:io';
import 'dart:math';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';
import 'package:breakdex/core/sync/integrity_verifier.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AssetHashService hashService;

  setUp(() {
    db = createTestDatabase();
    hashService = AssetHashService();
  });

  tearDown(() async {
    await db.close();
  });

  /// Insert a manifest entry with a known hash and local path.
  Future<void> seedManifest(
    AppDatabase db, {
    required String hash,
    String? localPath,
    DateTime? localVerifiedAt,
  }) async {
    await db.assetManifestDao.upsert(AssetManifestCompanion(
      contentHash: Value(hash),
      fileSizeBytes: const Value(1024),
      sourceType: const Value('camera'),
      importedAt: Value(DateTime.now()),
      localPath: Value(localPath),
      localVerifiedAt: Value(localVerifiedAt),
    ));
  }

  Future<void> seedLocalCopy(
    AppDatabase db, {
    required String hash,
    String status = 'verified',
  }) async {
    await db.assetCopiesDao.insertCopy(AssetCopiesCompanion(
      id: Value('local-$hash'),
      contentHash: Value(hash),
      provider: const Value('local'),
      status: Value(status),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  group('IntegrityVerifier', () {
    test('returns empty report when no stale files exist', () async {
      final verifier = IntegrityVerifier(
        db.assetManifestDao,
        db.assetCopiesDao,
        hashService,
      );

      final report = await verifier.verify();

      expect(report.filesChecked, 0);
      expect(report.filesOk, 0);
      expect(report.filesMismatched, 0);
      expect(report.filesMissing, 0);
      expect(report.allGood, isTrue);
    });

    test('returns empty report when all files are recently verified',
        () async {
      final verifier = IntegrityVerifier(
        db.assetManifestDao,
        db.assetCopiesDao,
        hashService,
      );

      // Verified just now — not stale
      await seedManifest(db,
          hash: 'abc123',
          localPath: '/tmp/test.mp4',
          localVerifiedAt: DateTime.now());

      final report = await verifier.verify();

      expect(report.filesChecked, 0);
      expect(report.allGood, isTrue);
    });

    test('detects file with matching hash as OK', () async {
      // Use a fixed random seed so we always pick the same sample
      final verifier = IntegrityVerifier(
        db.assetManifestDao,
        db.assetCopiesDao,
        hashService,
        random: Random(42),
      );

      // Create a real file and compute its actual hash
      final dir = Directory.systemTemp.createTempSync('verify_test_');
      final file = File('${dir.path}/good_video.mp4')
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final realHash = await hashService.computeHash(file.path);

      // Seed manifest with the real hash, never verified (stale)
      await seedManifest(db, hash: realHash, localPath: file.path);
      await seedLocalCopy(db, hash: realHash);

      final report = await verifier.verify();

      expect(report.filesChecked, 1);
      expect(report.filesOk, 1);
      expect(report.filesMismatched, 0);
      expect(report.allGood, isTrue);

      dir.deleteSync(recursive: true);
    });

    test('detects hash mismatch and marks local copy as failed', () async {
      final verifier = IntegrityVerifier(
        db.assetManifestDao,
        db.assetCopiesDao,
        hashService,
        random: Random(42),
      );

      // Create a real file but seed with a wrong hash
      final dir = Directory.systemTemp.createTempSync('verify_test_');
      final file = File('${dir.path}/corrupt_video.mp4')
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final wrongHash = 'a' * 64; // Definitely wrong

      await seedManifest(db, hash: wrongHash, localPath: file.path);
      await seedLocalCopy(db, hash: wrongHash);

      final report = await verifier.verify();

      expect(report.filesChecked, 1);
      expect(report.filesMismatched, 1);
      expect(report.allGood, isFalse);

      // Verify the local copy was marked as failed
      final localCopy = await db.assetCopiesDao.getLocalCopy(wrongHash);
      expect(localCopy?.status, 'failed');

      dir.deleteSync(recursive: true);
    });

    test('counts null localPath as filesMissing', () {
      // The verifier's "missing" counter only increments when localPath is
      // null, which getStaleVerifications filters out. Test the report model
      // directly to verify the allGood logic covers this case.
      const report = IntegrityReport(
        filesChecked: 3,
        filesOk: 1,
        filesMismatched: 0,
        filesMissing: 2,
      );
      expect(report.filesMissing, 2);
      expect(report.allGood, isFalse);
    });

    test('allGood getter is true only when no issues found', () {
      expect(
        const IntegrityReport(
                filesChecked: 5, filesOk: 5, filesMismatched: 0, filesMissing: 0)
            .allGood,
        isTrue,
      );
      expect(
        const IntegrityReport(
                filesChecked: 5, filesOk: 4, filesMismatched: 1, filesMissing: 0)
            .allGood,
        isFalse,
      );
      expect(
        const IntegrityReport(
                filesChecked: 5, filesOk: 4, filesMismatched: 0, filesMissing: 1)
            .allGood,
        isFalse,
      );
    });
  });
}
