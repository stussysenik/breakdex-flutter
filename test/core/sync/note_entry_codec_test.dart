/// Wave task 4.9 — `note_entry_codec` round-trip proof for the Appwrite-only
/// moveNoteEntries + comboNoteEntries entities. Each encode/decode pair is exact
/// inverses; identity + LWW clock live outside `json`. Pure — no DB.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/codecs/note_entry_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt =
      DateTime.fromMillisecondsSinceEpoch(1699000000000, isUtc: true);
  final updatedAt =
      DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

  group('move note entry codec', () {
    MoveNoteEntry note({final DateTime? updatedAt}) => MoveNoteEntry(
          id: 'mn1',
          moveId: 'm1',
          body: 'a jot',
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: null,
        );

    test('encode splits id + LWW clock out of json', () {
      final rec = moveNoteEntryToSyncRecord(note(updatedAt: updatedAt));
      expect(rec.id, 'mn1');
      expect(rec.type, SyncEntityType.moveNoteEntry);
      expect(rec.updatedAt, updatedAt);
      expect(rec.clientOpId, 'backfill:moveNoteEntry:mn1');
      expect(rec.json, {
        'moveId': 'm1',
        'body': 'a jot',
        'createdAt': createdAt.millisecondsSinceEpoch,
      });
      expect(rec.json.containsKey('id'), isFalse);
      expect(rec.json.containsKey('updatedAt'), isFalse);
    });

    test('round-trip preserves fields + remote clock', () {
      final back =
          moveNoteEntryFromSyncRecord(moveNoteEntryToSyncRecord(note(
        updatedAt: updatedAt,
      )));
      expect(back.id.value, 'mn1');
      expect(back.moveId.value, 'm1');
      expect(back.body.value, 'a jot');
      expect(back.createdAt.value, createdAt);
      expect(back.updatedAt.value, updatedAt);
    });

    test('null clock falls back to createdAt (guard), never null', () {
      final rec = moveNoteEntryToSyncRecord(note());
      expect(rec.updatedAt, createdAt);
    });
  });

  group('combo note entry codec', () {
    ComboNoteEntry note({
      final String kind = 'jot',
      final String? videoPath,
      final String? videoHash,
      final DateTime? updatedAt,
    }) =>
        ComboNoteEntry(
          id: 'cn1',
          comboId: 'c1',
          body: 'a take',
          kind: kind,
          videoPath: videoPath,
          videoHash: videoHash,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: null,
        );

    test('encode carries kind + video refs; id/clock split out', () {
      final rec = comboNoteEntryToSyncRecord(note(
        kind: 'status',
        videoPath: 'Moves/x.mp4',
        videoHash: 'sha:abc',
        updatedAt: updatedAt,
      ));
      expect(rec.id, 'cn1');
      expect(rec.type, SyncEntityType.comboNoteEntry);
      expect(rec.updatedAt, updatedAt);
      expect(rec.clientOpId, 'backfill:comboNoteEntry:cn1');
      expect(rec.json, {
        'comboId': 'c1',
        'body': 'a take',
        'kind': 'status',
        'videoPath': 'Moves/x.mp4',
        'videoHash': 'sha:abc',
        'createdAt': createdAt.millisecondsSinceEpoch,
      });
    });

    test('round-trip with null video refs', () {
      final back =
          comboNoteEntryFromSyncRecord(comboNoteEntryToSyncRecord(note(
        updatedAt: updatedAt,
      )));
      expect(back.comboId.value, 'c1');
      expect(back.body.value, 'a take');
      expect(back.kind.value, 'jot');
      expect(back.videoPath.value, isNull);
      expect(back.videoHash.value, isNull);
      expect(back.createdAt.value, createdAt);
      expect(back.updatedAt.value, updatedAt);
    });
  });
}
