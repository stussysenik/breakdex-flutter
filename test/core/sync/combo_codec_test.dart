/// Wave task 4.4 — `combo_codec` round-trip proof.
///
/// Each encode/decode pair must be exact inverses (as `move_codec` is), and the
/// identity + LWW clock must ride outside `json`. Pure — no DB.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/codecs/combo_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime.fromMillisecondsSinceEpoch(
    1700000000000,
    isUtc: true,
  );
  final updated = DateTime.fromMillisecondsSinceEpoch(
    1710000000000,
    isUtc: true,
  );

  group('comboToSyncRecord / comboFromSyncRecord', () {
    test('round-trips every field; id + clock live outside json', () {
      final combo = Combo(
        id: 'c1',
        name: 'Windmill → Flare',
        notes: 'open on the 7',
        activeVideoPath: 'Combos/c1.mp4',
        contentHash: 'deadbeef',
        status: 'landed',
        createdAt: created,
        updatedAt: updated,
      );

      final rec = comboToSyncRecord(combo);
      expect(rec.id, 'c1');
      expect(rec.type, SyncEntityType.combo);
      expect(rec.updatedAt, updated);
      expect(rec.clientOpId, 'backfill:combo:c1');
      expect(rec.json.containsKey('id'), isFalse);
      expect(rec.json.containsKey('updatedAt'), isFalse);

      final back = comboFromSyncRecord(rec);
      expect(back.id.value, 'c1');
      expect(back.name.value, 'Windmill → Flare');
      expect(back.notes.value, 'open on the 7');
      expect(back.activeVideoPath.value, 'Combos/c1.mp4');
      expect(back.contentHash.value, 'deadbeef');
      expect(back.status.value, 'landed');
      expect(back.createdAt.value.isAtSameMomentAs(created), isTrue);
      expect(back.updatedAt.value!.isAtSameMomentAs(updated), isTrue);
    });

    test('null updatedAt falls back to createdAt (never a null clock)', () {
      final combo = Combo(
        id: 'c2',
        name: 'Solo',
        status: 'idea',
        createdAt: created,
      );
      expect(comboToSyncRecord(combo).updatedAt, created);
    });

    test('null notes/paths round-trip as null', () {
      final combo = Combo(
        id: 'c3',
        name: 'Bare',
        status: 'idea',
        createdAt: created,
      );
      final back = comboFromSyncRecord(comboToSyncRecord(combo));
      expect(back.notes.value, isNull);
      expect(back.activeVideoPath.value, isNull);
      expect(back.contentHash.value, isNull);
    });
  });

  group('comboMoveToSyncRecord / comboMoveFromSyncRecord', () {
    test('round-trips every field; id + clock live outside json', () {
      final step = ComboMove(
        id: 'cm1',
        sequenceIndex: 3,
        comboId: 'c1',
        moveId: 'm9',
        count: 5,
        updatedAt: updated,
      );

      final rec = comboMoveToSyncRecord(step);
      expect(rec.id, 'cm1');
      expect(rec.type, SyncEntityType.comboMove);
      expect(rec.updatedAt, updated);
      expect(rec.clientOpId, 'backfill:comboMove:cm1');
      expect(rec.json.containsKey('id'), isFalse);

      final back = comboMoveFromSyncRecord(rec);
      expect(back.id.value, 'cm1');
      expect(back.sequenceIndex.value, 3);
      expect(back.comboId.value, 'c1');
      expect(back.moveId.value, 'm9');
      expect(back.count.value, 5);
      expect(back.updatedAt.value!.isAtSameMomentAs(updated), isTrue);
    });

    test(
      'null updatedAt is guarded to epoch-0 (oldest-possible, never wins)',
      () {
        const step = ComboMove(
          id: 'cm2',
          sequenceIndex: 0,
          comboId: 'c1',
          moveId: 'm1',
          count: 1,
        );
        expect(comboMoveToSyncRecord(step).updatedAt.millisecondsSinceEpoch, 0);
      },
    );
  });
}
