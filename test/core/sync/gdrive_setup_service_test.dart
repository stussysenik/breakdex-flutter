import 'dart:convert';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/gdrive_setup_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedGdriveRow({final String? configJson}) async {
    await db.syncProvidersDao.insertProvider(
      SyncProvidersCompanion.insert(
        id: 'row-gdrive',
        providerType: 'gdrive',
        displayName: 'Google Drive',
        configJson: Value(configJson),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  group('GDriveSetupService.connectedAccountEmail', () {
    test('returns null when no Drive row is configured', () async {
      final service = GDriveSetupService(
        syncProvidersDao: db.syncProvidersDao,
        silentEmail: () async => 'live@gmail.com',
      );

      expect(await service.connectedAccountEmail(), isNull);
    });

    test('live silent read wins and is cached into configJson', () async {
      await seedGdriveRow(configJson: jsonEncode({'folderId': 'f1'}));
      final service = GDriveSetupService(
        syncProvidersDao: db.syncProvidersDao,
        silentEmail: () async => 'dancer@gmail.com',
      );

      expect(await service.connectedAccountEmail(), 'dancer@gmail.com');

      final row = await db.syncProvidersDao.getByType('gdrive');
      final config = jsonDecode(row!.configJson!) as Map<String, dynamic>;
      expect(config['accountEmail'], 'dancer@gmail.com');
      expect(config['folderId'], 'f1', reason: 'existing config keys survive');
    });

    test('offline (silent read null) falls back to the cached email',
        () async {
      await seedGdriveRow(
        configJson: jsonEncode({'folderId': 'f1', 'accountEmail': 'dancer@gmail.com'}),
      );
      final service = GDriveSetupService(
        syncProvidersDao: db.syncProvidersDao,
        silentEmail: () async => null,
      );

      expect(await service.connectedAccountEmail(), 'dancer@gmail.com');
    });

    test('no cache and no session yields null, not a crash', () async {
      await seedGdriveRow();
      final service = GDriveSetupService(
        syncProvidersDao: db.syncProvidersDao,
        silentEmail: () async => null,
      );

      expect(await service.connectedAccountEmail(), isNull);
    });
  });
}
