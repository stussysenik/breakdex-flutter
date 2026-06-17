import 'dart:convert';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/sync/manifest_serializer.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late ManifestSerializer serializer;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({
      'categories': jsonEncode([
        {'name': 'Power Moves', 'colorValue': 0xFFDA1E28, 'isDefault': true},
        {'name': 'Footwork', 'colorValue': 0xFF2362A2, 'isDefault': true},
      ]),
    });
    prefs = await SharedPreferences.getInstance();

    serializer = ManifestSerializer(
      movesDao: db.movesDao,
      combosDao: db.combosDao,
      fsrsCardsDao: db.fsrsCardsDao,
      reviewsDao: db.reviewsDao,
      decksDao: db.decksDao,
      db: db,
      prefs: prefs,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ManifestSerializer', () {
    test('produces valid JSON with version 2 schema', () async {
      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['version'], equals(2));
      expect(data['exportedAt'], isNotNull);
      expect(data.containsKey('moves'), isTrue);
      expect(data.containsKey('combos'), isTrue);
      expect(data.containsKey('categories'), isTrue);
      expect(data.containsKey('fsrsCards'), isTrue);
      expect(data.containsKey('reviews'), isTrue);
      expect(data.containsKey('decks'), isTrue);
      expect(data.containsKey('assets'), isTrue);
      expect(data.containsKey('notes'), isTrue);
      expect(data.containsKey('plans'), isTrue);
    });

    test('serializes moves with contentHash', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(
          id: 'move-1',
          name: 'Windmill',
          category: const Value('Power Moves'),
          contentHash: const Value('abc123def456'),
        ),
      );

      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final moves = data['moves'] as List;

      expect(moves, hasLength(1));
      expect(moves[0]['id'], equals('move-1'));
      expect(moves[0]['name'], equals('Windmill'));
      expect(moves[0]['category'], equals('Power Moves'));
      expect(moves[0]['contentHash'], equals('abc123def456'));
      expect(moves[0]['createdAt'], isNotNull);
    });

    test('serializes categories from SharedPreferences', () async {
      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final categories = data['categories'] as List;

      expect(categories, hasLength(2));
      expect(categories[0]['name'], equals('Power Moves'));
      expect(categories[1]['name'], equals('Footwork'));
    });

    test('exportedAt uses UTC ISO 8601', () async {
      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final exportedAt = data['exportedAt'] as String;

      // UTC ISO dates end with 'Z'
      expect(exportedAt, endsWith('Z'));
      // Parses without error
      expect(() => DateTime.parse(exportedAt), returnsNormally);
    });

    test('handles empty database gracefully', () async {
      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect((data['moves'] as List), isEmpty);
      expect((data['combos'] as List), isEmpty);
      expect((data['reviews'] as List), isEmpty);
      expect((data['fsrsCards'] as List), isEmpty);
      expect((data['decks'] as List), isEmpty);
      expect((data['assets'] as List), isEmpty);
      expect((data['notes'] as List), isEmpty);
      expect((data['plans'] as List), isEmpty);
    });

    test('serializes combo journal notes and practice plans', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c1', name: 'Opener'),
      );
      await db.comboNoteEntriesDao.addEntry(
        id: 'note-1',
        comboId: 'c1',
        body: 'felt strong on the freeze',
        kind: 'jot',
        videoHash: 'abc123',
      );
      await db.comboPlansDao.insertPlan(
        ComboPlansCompanion.insert(
          id: 'plan-1',
          comboId: 'c1',
          planDate: DateTime.utc(2026, 6, 20),
        ),
      );

      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;

      final notes = (data['notes'] as List).cast<Map<String, dynamic>>();
      expect(notes, hasLength(1));
      expect(notes.single['id'], equals('note-1'));
      expect(notes.single['comboId'], equals('c1'));
      expect(notes.single['kind'], equals('jot'));
      expect(notes.single['body'], equals('felt strong on the freeze'));
      expect(notes.single['videoContentHash'], equals('abc123'));
      expect(notes.single['createdAt'], endsWith('Z'));

      final plans = (data['plans'] as List).cast<Map<String, dynamic>>();
      expect(plans, hasLength(1));
      expect(plans.single['id'], equals('plan-1'));
      expect(plans.single['comboId'], equals('c1'));
      expect(plans.single['completedAt'], isNull);
    });

    test('serializes provider-agnostic asset metadata', () async {
      await db
          .into(db.assetManifest)
          .insert(
            AssetManifestCompanion.insert(
              contentHash: 'hash-123',
              fileSizeBytes: 4096,
              mimeType: const Value('video/mp4'),
              durationMs: const Value(1800),
              width: const Value(1920),
              height: const Value(1080),
              localPath: const Value('/tmp/hash-123.mp4'),
              localVerifiedAt: Value(DateTime.utc(2026, 4, 30, 12)),
              sourceType: 'camera',
              sourceName: const Value('round.mp4'),
              importedAt: DateTime.utc(2026, 4, 29, 18),
              deletedAt: const Value.absent(),
              tombstoneReason: const Value.absent(),
              copyCount: const Value(2),
              lastSyncAt: Value(DateTime.utc(2026, 4, 30, 8)),
            ),
          );

      final json = await serializer.serialize();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final assets = data['assets'] as List;

      expect(assets, hasLength(1));
      expect(assets[0]['contentHash'], equals('hash-123'));
      expect(assets[0]['fileSizeBytes'], equals(4096));
      expect(assets[0]['mimeType'], equals('video/mp4'));
      expect(assets[0]['durationMs'], equals(1800));
      expect(assets[0]['width'], equals(1920));
      expect(assets[0]['height'], equals(1080));
      expect(assets[0]['sourceType'], equals('camera'));
      expect(assets[0]['sourceName'], equals('round.mp4'));
      expect(assets[0]['importedAt'], equals('2026-04-29T18:00:00.000Z'));
    });
  });
}
