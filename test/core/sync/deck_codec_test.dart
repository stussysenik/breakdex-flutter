/// Wave task 4.7 — `deck_codec` round-trip proof for the Appwrite-only decks +
/// deck_moves entities. Each encode/decode pair is exact inverses; the deck-move
/// join has no synthetic id, so its wire identity is the composite
/// `'$deckId:$moveId'` while its decode reads deckId/moveId from `json`. Pure —
/// no DB.
library;

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/codecs/deck_codec.dart';
import 'package:breakdex/core/sync/sync_backend.dart';
import 'package:flutter_test/flutter_test.dart';

Deck _deck({
  final String id = 'd1',
  final String name = 'Powermoves',
  final String deckType = 'smart',
  final String? filterCriteria = '{"categories":["powermove"]}',
  final int? sessionSize = 20,
  required final DateTime createdAt,
  required final DateTime updatedAt,
}) => Deck(
  id: id,
  name: name,
  deckType: deckType,
  filterCriteria: filterCriteria,
  sessionSize: sessionSize,
  createdAt: createdAt,
  updatedAt: updatedAt,
);

void main() {
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1699000000000, isUtc: true);
  final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

  group('deck codec', () {
    test('encode splits id + LWW clock out of json', () {
      final rec = deckToSyncRecord(_deck(createdAt: createdAt, updatedAt: updatedAt));
      expect(rec.id, 'd1');
      expect(rec.type, SyncEntityType.deck);
      expect(rec.updatedAt, updatedAt);
      expect(rec.clientOpId, 'backfill:deck:d1');
      expect(rec.json, {
        'name': 'Powermoves',
        'deckType': 'smart',
        'filterCriteria': '{"categories":["powermove"]}',
        'sessionSize': 20,
        'createdAt': createdAt.millisecondsSinceEpoch,
      });
      expect(rec.json.containsKey('id'), isFalse);
      expect(rec.json.containsKey('updatedAt'), isFalse);
    });

    test('round-trip preserves the canonical fields + remote clock', () {
      final original = _deck(createdAt: createdAt, updatedAt: updatedAt);
      final back = deckFromSyncRecord(deckToSyncRecord(original));
      expect(back.id.value, 'd1');
      expect(back.name.value, 'Powermoves');
      expect(back.deckType.value, 'smart');
      expect(back.filterCriteria.value, '{"categories":["powermove"]}');
      expect(back.sessionSize.value, 20);
      expect(back.createdAt.value, createdAt);
      // The remote clock is preserved verbatim (never re-stamped to now()).
      expect(back.updatedAt.value, updatedAt);
    });

    test('manual deck with null filter/session round-trips', () {
      final back = deckFromSyncRecord(deckToSyncRecord(_deck(
        deckType: 'manual',
        filterCriteria: null,
        sessionSize: null,
        createdAt: createdAt,
        updatedAt: updatedAt,
      )));
      expect(back.deckType.value, 'manual');
      expect(back.filterCriteria.value, isNull);
      expect(back.sessionSize.value, isNull);
    });
  });

  group('deck_move codec', () {
    DeckMove dm({
      final String deckId = 'd1',
      final String moveId = 'm1',
      final DateTime? updatedAt,
    }) => DeckMove(deckId: deckId, moveId: moveId, updatedAt: updatedAt);

    test('composite id is deckId:moveId; deckId/moveId live in json', () {
      final rec = deckMoveToSyncRecord(dm(updatedAt: updatedAt));
      expect(rec.id, 'd1:m1');
      expect(rec.type, SyncEntityType.deckMove);
      expect(rec.updatedAt, updatedAt);
      expect(rec.clientOpId, 'backfill:deckMove:d1:m1');
      expect(rec.json, {'deckId': 'd1', 'moveId': 'm1'});
    });

    test('round-trip preserves deckId/moveId + clock; decode ignores the id', () {
      final rec = deckMoveToSyncRecord(dm(deckId: 'dX', moveId: 'mY', updatedAt: updatedAt));
      final back = deckMoveFromSyncRecord(rec);
      expect(back.deckId.value, 'dX');
      expect(back.moveId.value, 'mY');
      expect(back.updatedAt.value, updatedAt);
    });

    test('null clock encodes as epoch-0 (guard), never null', () {
      final rec = deckMoveToSyncRecord(dm());
      expect(rec.updatedAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });

    test('deckMoveWireId matches the encoded id', () {
      expect(deckMoveWireId('a', 'b'), 'a:b');
    });
  });
}
