import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../../helpers/test_database.dart';

void main() {
  group('AssetManifestDao.updateLocalState', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'updates local fields without rewriting required manifest columns',
      () async {
        await db.assetManifestDao.upsert(
          AssetManifestCompanion.insert(
            contentHash: 'hash-1',
            fileSizeBytes: 1024,
            sourceType: 'photos',
            importedAt: DateTime.utc(2026, 5, 1),
            localPath: const Value('videos/hash-1.mp4'),
          ),
        );

        await db.assetManifestDao.updateLocalState(
          'hash-1',
          localPath: const Value(null),
          localVerifiedAt: const Value(null),
        );

        final manifest = await db.assetManifestDao.getByHash('hash-1');
        expect(manifest, isNotNull);
        expect(manifest!.fileSizeBytes, 1024);
        expect(manifest.sourceType, 'photos');
        expect(manifest.importedAt.toUtc(), DateTime.utc(2026, 5, 1));
        expect(manifest.localPath, isNull);
        expect(manifest.localVerifiedAt, isNull);
      },
    );
  });
}
