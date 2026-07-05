// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:breakdex/core/services/provenance_journal_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvenanceJournalService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'breakdex-provenance-journal-',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('records structured events and reads them back in order', () async {
      var now = DateTime.utc(2026, 5, 1, 12);
      final service = ProvenanceJournalService(
        documentsDirectory: () async => tempDir,
        now: () => now,
        sessionIdGenerator: () => 'session-1',
      );

      await service.log(
        scope: 'startup',
        eventType: 'app_boot',
        status: 'started',
        message: 'boot',
      );
      now = now.add(const Duration(seconds: 5));
      await service.log(
        scope: 'video_retrieval',
        eventType: 'download_restored',
        status: 'available',
        entityType: 'asset_manifest',
        entityId: 'hash-123',
        contentHash: 'hash-123',
        localPath: '/tmp/hash-123.mp4',
        message: 'restored',
      );

      final events = await service.readRecent(limit: 10);

      expect(events, hasLength(2));
      expect(events.first.eventType, 'app_boot');
      expect(events.last.contentHash, 'hash-123');
      expect(events.last.localPath, '/tmp/hash-123.mp4');
      expect(events.last.sessionId, 'session-1');
    });

    test('sanitizes newlines and tabs in free-form messages', () async {
      final service = ProvenanceJournalService(
        documentsDirectory: () async => tempDir,
      );

      await service.log(
        scope: 'crash',
        eventType: 'flutter_error',
        status: 'captured',
        message: 'line 1\tline 2\nline 3',
      );

      final events = await service.readRecent(limit: 1);
      expect(events.single.message, 'line 1 line 2 line 3');
    });
  });
}
