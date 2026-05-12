import 'package:flutter_test/flutter_test.dart';
import 'package:breakdex/core/services/canonical_folder_service.dart';

void main() {
  group('Ledger', () {
    test('fromJson round-trips correctly', () {
      final original = Ledger(entries: {
        'a.mp4': LedgerEntry(fileName: 'a.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
        'b.mp4': LedgerEntry(fileName: 'b.mp4', fileSizeBytes: 200,
            lastSeenAt: DateTime(2026, 1, 16), recordedAt: DateTime(2026, 1, 16)),
      });
      final restored = Ledger.fromJson(original.toJson());
      expect(restored.entries.length, 2);
      expect(restored['a.mp4']!.fileSizeBytes, 100);
      expect(restored['b.mp4']!.fileSizeBytes, 200);
    });

    test('upsert overwrites existing entry', () {
      final ledger = Ledger(entries: {
        'test.mp4': LedgerEntry(fileName: 'test.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      final updated = ledger.upsert(LedgerEntry(
          fileName: 'test.mp4', fileSizeBytes: 999,
          lastSeenAt: DateTime(2026, 1, 20), recordedAt: DateTime(2026, 1, 20)));
      expect(updated['test.mp4']!.fileSizeBytes, 999);
      expect(ledger['test.mp4']!.fileSizeBytes, 100);
    });

    test('remove returns new ledger without entry', () {
      final ledger = Ledger(entries: {
        'keep.mp4': LedgerEntry(fileName: 'keep.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
        'remove.mp4': LedgerEntry(fileName: 'remove.mp4', fileSizeBytes: 200,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      final result = ledger.remove('remove.mp4');
      expect(result.entries.length, 1);
      expect(result.contains('keep.mp4'), true);
      expect(result.contains('remove.mp4'), false);
    });

    test('empty ledger has no entries', () {
      final ledger = Ledger.empty();
      expect(ledger.entries, isEmpty);
      expect(ledger.version, 1);
    });

    test('contains returns correct membership', () {
      final ledger = Ledger(entries: {
        'found.mp4': LedgerEntry(fileName: 'found.mp4', fileSizeBytes: 100,
            lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15)),
      });
      expect(ledger.contains('found.mp4'), true);
      expect(ledger.contains('missing.mp4'), false);
    });

    test('operator [] returns entry by key', () {
      final ledger = Ledger(entries: {
        'file.mp4': LedgerEntry(fileName: 'file.mp4', fileSizeBytes: 300,
            lastSeenAt: DateTime(2026, 1, 20), recordedAt: DateTime(2026, 1, 20)),
      });
      expect(ledger['file.mp4']!.fileSizeBytes, 300);
      expect(ledger['missing.mp4'], isNull);
    });
  });

  group('FileScanResult', () {
    final testDate = DateTime(2026, 1, 15);
    test('isOrphan true when not in ledger', () {
      final r = FileScanResult(path: '/v.mp4', fileName: 'v.mp4',
          fileSizeBytes: 100, modifiedAt: testDate, inLedger: false);
      expect(r.isOrphan, true);
    });
    test('isOrphan false when in ledger', () {
      final r = FileScanResult(path: '/v.mp4', fileName: 'v.mp4',
          fileSizeBytes: 100, modifiedAt: testDate, inLedger: true);
      expect(r.isOrphan, false);
    });
  });

  group('LedgerEntry', () {
    test('fromJson correctly parses all fields', () {
      final entry = LedgerEntry.fromJson({
        'file': 'test.mp4', 'size': 500,
        'seen': '2026-01-15T10:00:00.000', 'recorded': '2026-01-15T11:00:00.000',
      });
      expect(entry.fileName, 'test.mp4');
      expect(entry.fileSizeBytes, 500);
      expect(entry.lastSeenAt, DateTime(2026, 1, 15, 10, 0, 0));
      expect(entry.recordedAt, DateTime(2026, 1, 15, 11, 0, 0));
    });

    test('equality compares fileName and fileSizeBytes only', () {
      final a = LedgerEntry(fileName: 'same.mp4', fileSizeBytes: 100,
          lastSeenAt: DateTime(2026, 1, 15), recordedAt: DateTime(2026, 1, 15));
      final b = LedgerEntry(fileName: 'same.mp4', fileSizeBytes: 100,
          lastSeenAt: DateTime(2026, 1, 16), recordedAt: DateTime(2026, 1, 16));
      expect(a, equals(b));
    });
  });
}
