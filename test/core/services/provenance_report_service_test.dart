import 'dart:io';

import 'package:breakdex/core/services/provenance_journal_service.dart';
import 'package:breakdex/core/services/provenance_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvenanceReportService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'breakdex-provenance-report-',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'summarizes recent failures, crashes, and recovery activity',
      () async {
        final journal = ProvenanceJournalService(
          documentsDirectory: () async => tempDir,
          sessionIdGenerator: () => 'session-report',
        );
        final service = ProvenanceReportService(journal);

        await journal.log(
          scope: 'database_recovery',
          eventType: 'backup_restored',
          status: 'restored',
          entityId: 'breakdex_backup_1.db',
        );
        await journal.log(
          scope: 'video_retrieval',
          eventType: 'download_failed',
          status: 'failed',
          contentHash: 'hash-404',
        );
        await journal.log(
          scope: 'crash',
          eventType: 'platform_error',
          status: 'captured',
          message: 'socket exception',
        );

        final report = await service.loadReport(limit: 20);

        expect(report.totalEvents, 3);
        expect(report.failureCount, 1);
        expect(report.crashCount, 1);
        expect(report.retrievalFailureCount, 1);
        expect(report.databaseRecoveryCount, 1);
        expect(report.recentCriticalEvents, hasLength(2));
        expect(report.headline, contains('crash'));
      },
    );

    test(
      'reports healthy state when no critical signals are present',
      () async {
        final journal = ProvenanceJournalService(
          documentsDirectory: () async => tempDir,
        );
        final service = ProvenanceReportService(journal);

        await journal.log(
          scope: 'startup',
          eventType: 'app_boot',
          status: 'started',
        );
        await journal.log(
          scope: 'video_retrieval',
          eventType: 'download_restored',
          status: 'available',
          contentHash: 'hash-123',
        );

        final report = await service.loadReport(limit: 20);

        expect(report.hasCriticalSignal, isFalse);
        expect(report.failureCount, 0);
        expect(report.crashCount, 0);
        expect(report.headline, 'No recent crash or failure signals');
      },
    );
  });
}
