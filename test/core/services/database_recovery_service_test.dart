import 'dart:io';

import 'package:breakdex/core/services/database_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DatabaseRecoveryService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('breakdex-db-recovery-');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'restores the newest backup when the primary database is missing',
      () async {
        final service = DatabaseRecoveryService(
          documentsDirectory: () async => tempDir,
        );
        final olderBackup = File(
          p.join(
            tempDir.path,
            '${DatabaseRecoveryService.backupFilenamePrefix}1000${DatabaseRecoveryService.databaseFilenameSuffix}',
          ),
        );
        final newerBackup = File(
          p.join(
            tempDir.path,
            '${DatabaseRecoveryService.backupFilenamePrefix}2000${DatabaseRecoveryService.databaseFilenameSuffix}',
          ),
        );
        await olderBackup.writeAsString('older');
        await newerBackup.writeAsString('newer');

        final restored = await service
            .restoreLatestBackupIfPrimaryUnavailable();
        final primary = await service.primaryDatabaseFile();

        expect(restored, isTrue);
        expect(await primary.readAsString(), 'newer');
      },
    );

    test(
      'creates a rolling backup when forced and prunes old copies',
      () async {
        var now = DateTime.utc(2026, 5, 1, 12);
        final service = DatabaseRecoveryService(
          documentsDirectory: () async => tempDir,
          now: () => now,
        );
        final primary = await service.primaryDatabaseFile();
        await primary.writeAsString('primary-db');

        for (
          var index = 0;
          index < DatabaseRecoveryService.maxBackupFiles + 2;
          index++
        ) {
          now = now.add(const Duration(hours: 7));
          final created = await service.createRollingBackupIfDue(force: true);
          expect(created, isTrue);
        }

        final backups = await service.listBackupFilesNewestFirst();
        expect(backups, hasLength(DatabaseRecoveryService.maxBackupFiles));
        expect(await backups.first.readAsString(), 'primary-db');
      },
    );

    test(
      'stashes a broken primary database before another recovery attempt',
      () async {
        final service = DatabaseRecoveryService(
          documentsDirectory: () async => tempDir,
          now: () => DateTime.utc(2026, 5, 1, 12),
        );
        final primary = await service.primaryDatabaseFile();
        await primary.writeAsString('broken-db');

        await service.stashPrimaryAsCorrupt();

        final corruptFiles = await tempDir
            .list()
            .where((entity) => entity is File)
            .cast<File>()
            .where(
              (file) => p
                  .basename(file.path)
                  .startsWith(DatabaseRecoveryService.corruptFilenamePrefix),
            )
            .toList();

        expect(await primary.exists(), isFalse);
        expect(corruptFiles, hasLength(1));
        expect(await corruptFiles.single.readAsString(), 'broken-db');
      },
    );
  });
}
