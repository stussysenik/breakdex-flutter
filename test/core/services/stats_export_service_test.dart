import 'dart:convert';

import 'package:breakdex/core/app_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/stats_export_service.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';
import 'package:breakdex/core/services/fsrs_service.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_data.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  // =========================================================================
  // Group A: validateImportJson
  // =========================================================================
  group('validateImportJson', () {
    test(
      'valid current-schema JSON returns valid:true with correct counts',
      () {
        final json = makeExportJson(
          moves: [
            makeJsonMove(),
            makeJsonMove(id: 'move-2', name: 'Headspin'),
          ],
          reviews: [makeJsonReview()],
          combos: [makeJsonCombo()],
          battleResults: [makeJsonBattleResult()],
          categories: [makeJsonCategory()],
        );

        final result = StatsExportService.validateImportJson(json);

        expect(result.valid, isTrue);
        expect(result.schemaVersion, AppMetadata.exportSchemaVersion);
        expect(result.moveCount, 2);
        expect(result.reviewCount, 1);
        expect(result.comboCount, 1);
        expect(result.battleResultCount, 1);
        expect(result.categoryCount, 1);
        expect(result.error, isNull);
      },
    );

    test('empty arrays returns valid:true with all counts 0', () {
      final json = makeExportJson(
        moves: [],
        reviews: [],
        combos: [],
        battleResults: [],
        categories: [],
      );

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isTrue);
      expect(result.moveCount, 0);
      expect(result.reviewCount, 0);
      expect(result.comboCount, 0);
      expect(result.battleResultCount, 0);
      expect(result.categoryCount, 0);
    });

    test('schema version > current rejected with newer version error', () {
      final json = makeExportJson(
        schemaVersion: AppMetadata.exportSchemaVersion + 1,
        moves: [],
      );

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isFalse);
      expect(result.error, contains('newer version'));
    });

    test('schema versions 1-5 accepted (backward compat)', () {
      for (final v in [1, 2, 3, 4, 5]) {
        final json = makeExportJson(schemaVersion: v, moves: []);
        final result = StatsExportService.validateImportJson(json);
        expect(result.valid, isTrue, reason: 'version $v should be accepted');
        expect(result.schemaVersion, v);
      }
    });

    test('malformed JSON returns Invalid JSON error', () {
      final result = StatsExportService.validateImportJson(
        'not valid json {{{',
      );

      expect(result.valid, isFalse);
      expect(result.error, startsWith('Invalid JSON'));
    });

    test('array at top level returns error', () {
      final result = StatsExportService.validateImportJson('[1, 2, 3]');

      expect(result.valid, isFalse);
      expect(result.error, isNotNull);
    });

    test('move missing id returns error', () {
      final json = jsonEncode({
        'schemaVersion': 6,
        'moves': [
          {'name': 'Windmill'},
        ],
      });

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isFalse);
      expect(result.error, contains('missing id or name'));
    });

    test('move missing name returns error', () {
      final json = jsonEncode({
        'schemaVersion': 6,
        'moves': [
          {'id': 'move-1'},
        ],
      });

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isFalse);
      expect(result.error, contains('missing id or name'));
    });

    test('missing schemaVersion defaults to 1', () {
      final json = jsonEncode({'moves': <Map<String, Object?>>[]});

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isTrue);
      expect(result.schemaVersion, 1);
    });

    test('unicode in move names accepted', () {
      final json = makeExportJson(
        moves: [
          makeJsonMove(id: 'move-1', name: 'フリーズ'),
          makeJsonMove(id: 'move-2', name: 'Toupie 🌀'),
        ],
      );

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isTrue);
      expect(result.moveCount, 2);
    });

    test('large dataset (1000 moves) accepted', () {
      final moves = List.generate(
        1000,
        (final i) => makeJsonMove(id: 'move-$i', name: 'Move $i'),
      );
      final json = makeExportJson(moves: moves);

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isTrue);
      expect(result.moveCount, 1000);
    });

    test('missing optional arrays treated as empty', () {
      final json = jsonEncode({'schemaVersion': 6});

      final result = StatsExportService.validateImportJson(json);

      expect(result.valid, isTrue);
      expect(result.moveCount, 0);
      expect(result.reviewCount, 0);
    });
  });

  // =========================================================================
  // Group B: generateJsonExport
  // =========================================================================
  group('generateJsonExport', () {
    test('empty DB produces valid JSON with empty arrays', () async {
      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;

      expect(data['schemaVersion'], AppMetadata.exportSchemaVersion);
      expect(data['moves'], isEmpty);
      expect(data['reviews'], isEmpty);
      expect(data['combos'], isEmpty);
      expect(data['fsrsCards'], isEmpty);
      expect(data['decks'], isEmpty);
      expect(data['deckMoves'], isEmpty);
      expect(result.moveCount, 0);
      expect(result.reviewCount, 0);
    });

    test('single move with all fields correctly mapped', () async {
      await seedMove(
        db,
        id: 'move-1',
        name: 'Windmill',
        category: 'power',
        videoPath: '/path/to/video.mp4',
        originalVideoName: 'windmill_orig.mp4',
      );

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final moves = data['moves'] as List;

      expect(moves.length, 1);
      final m = moves.first as Map<String, dynamic>;
      expect(m['id'], 'move-1');
      expect(m['name'], 'Windmill');
      expect(m['category'], 'power');
      expect(m['learningState'], 'NEW');
      expect(m['videoFilename'], 'video.mp4');
      expect(m['originalVideoName'], 'windmill_orig.mp4');
      expect(m['createdAt'], isNotNull);
      expect(result.moveCount, 1);
    });

    test('null videoPath produces null videoFilename', () async {
      await seedMove(db, videoPath: null);

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;

      expect(m['videoFilename'], isNull);
    });

    test('videoPath basename extraction', () async {
      await seedMove(db, videoPath: '/long/nested/path/to/clip.mp4');

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;

      expect(m['videoFilename'], 'clip.mp4');
    });

    test('reviews with comboId and FSRS state fields', () async {
      await seedMove(db);
      await seedCombo(db);
      await seedReview(
        db,
        comboId: 'combo-1',
        fsrsPreState: 0,
        fsrsPostState: 1,
      );

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final r = (data['reviews'] as List).first as Map<String, dynamic>;

      expect(r['comboId'], 'combo-1');
      expect(r['fsrsPreState'], 0);
      expect(r['fsrsPostState'], 1);
    });

    test('fsrsCards use entityId+entityType (not moveId)', () async {
      await seedMove(db);
      await seedFsrsCard(db, entityId: 'move-1', entityType: 'move');

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final fc = (data['fsrsCards'] as List).first as Map<String, dynamic>;

      expect(fc['entityId'], 'move-1');
      expect(fc['entityType'], 'move');
      expect(fc.containsKey('moveId'), isFalse);
    });

    test('fsrsCards with both move and combo entity types', () async {
      await seedMove(db);
      await seedCombo(db);
      await seedFsrsCard(db, entityId: 'move-1', entityType: 'move');
      await seedFsrsCard(db, entityId: 'combo-1', entityType: 'combo');

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final cards = data['fsrsCards'] as List;

      expect(cards.length, 2);
      final types = cards.map((final c) => (c as Map)['entityType']).toSet();
      expect(types, containsAll(['move', 'combo']));
    });

    test('decks and deckMoves export correctly', () async {
      await seedMove(db);
      await seedDeck(db, id: 'deck-1', name: 'Power Moves');
      await seedDeckMove(db, deckId: 'deck-1', moveId: 'move-1');

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;

      final decks = data['decks'] as List;
      expect(decks.length, 1);
      expect((decks.first as Map)['name'], 'Power Moves');

      final dms = data['deckMoves'] as List;
      expect(dms.length, 1);
      expect((dms.first as Map)['deckId'], 'deck-1');
      expect((dms.first as Map)['moveId'], 'move-1');
    });

    test('categories from SharedPreferences included', () async {
      await prefs.setString(
        'categories',
        jsonEncode([
          {'name': 'power', 'colorValue': 0xFFFF0000},
          {'name': 'freeze', 'colorValue': 0xFF0000FF},
        ]),
      );

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final cats = data['categories'] as List;

      expect(cats.length, 2);
      expect((cats.first as Map)['name'], 'power');
    });

    test('ExportResult counts match actual data', () async {
      await seedMove(db, id: 'move-1');
      await seedMove(db, id: 'move-2', name: 'Headspin');
      await seedReview(db);
      await seedCombo(db);
      await seedBattleResult(db);

      final result = await StatsExportService.generateJsonExport(db, prefs);

      expect(result.moveCount, 2);
      expect(result.reviewCount, 1);
      expect(result.comboCount, 1);
      expect(result.battleResultCount, 1);
    });

    test('DateTime fields are ISO 8601', () async {
      await seedMove(db);

      final result = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(result.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;

      // ISO 8601 format has a 'T' separator between date and time
      expect(m['createdAt'], contains('T'));
      // Should parse without error
      expect(() => DateTime.parse(m['createdAt'] as String), returnsNormally);
    });
  });

  // =========================================================================
  // Group C: importFromJson — replaceAll mode
  // =========================================================================
  group('importFromJson replaceAll', () {
    test('import single move into empty DB', () async {
      final json = makeExportJson(moves: [makeJsonMove()]);

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 1);
      final moves = await db.movesDao.getAll();
      expect(moves.length, 1);
      expect(moves.first.name, 'Windmill');
    });

    test('replaceAll upserts existing by ID, keeps extras not in import', () async {
      // Pre-populate DB with two moves
      await seedMove(db, id: 'old-move', name: 'Old Move');
      await seedMove(db, id: 'extra-move', name: 'Extra Move');
      await seedReview(db, id: 'old-review', moveId: 'old-move');

      // Import replaces one by ID
      final json = makeExportJson(
        moves: [makeJsonMove(id: 'old-move', name: 'Updated Name')],
      );
      await StatsExportService.importFromJson(
        db, prefs, json, ImportMode.replaceAll,
      );

      final moves = await db.movesDao.getAll();
      expect(moves.length, 2);
      final updated = moves.firstWhere((final m) => m.id == 'old-move');
      expect(updated.name, 'Updated Name');
      final extra = moves.firstWhere((final m) => m.id == 'extra-move');
      expect(extra.name, 'Extra Move');
    });

    test('replaceAll with empty import does not clear data', () async {
      // Pre-populate everything
      await seedMove(db, id: 'move-1');
      await seedCombo(db, id: 'combo-1');
      await seedReview(db, id: 'review-1', moveId: 'move-1');
      await seedBattleResult(db, id: 'battle-1');
      await seedFsrsCard(db, entityId: 'move-1');
      await seedDeck(db, id: 'deck-1');
      await seedDeckMove(db, deckId: 'deck-1', moveId: 'move-1');

      // Import empty — should not affect existing data
      final json = makeExportJson();
      await StatsExportService.importFromJson(db, prefs, json, ImportMode.replaceAll);

      expect((await db.movesDao.getAll()).length, 1);
      expect((await db.reviewsDao.watchAll().first).length, 1);
      expect((await db.combosDao.getAll()).length, 1);
      expect((await db.select(db.comboMoves).get()).length, 0);
      expect((await db.select(db.battleResults).get()).length, 1);
      expect((await db.fsrsCardsDao.getAll()).length, 1);
      expect((await db.decksDao.getAll()).length, 1);
      expect((await db.select(db.deckMoves).get()).length, 1);
    });

    test('videoPath always null after import', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(videoFilename: 'clip.mp4')],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final moves = await db.movesDao.getAll();
      expect(moves.first.videoPath, isNull);
    });

    test('missing video tracked in movesWithMissingVideos', () async {
      final json = makeExportJson(
        moves: [
          makeJsonMove(id: 'move-1', name: 'Windmill', videoFilename: 'w.mp4'),
          makeJsonMove(id: 'move-2', name: 'Headspin'),
        ],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesWithMissingVideos, contains('Windmill'));
      expect(result.movesWithMissingVideos, isNot(contains('Headspin')));
    });

    test('default values: learningState=NEW, category=default', () async {
      final json = makeExportJson(
        moves: [
          {'id': 'move-1', 'name': 'Minimal Move'},
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final moves = await db.movesDao.getAll();
      expect(moves.first.learningState, 'NEW');
      expect(moves.first.category, 'default');
    });

    test('FSRS card v1→v6 backward compat (moveId → entityId)', () async {
      await seedMove(db, id: 'move-1');

      final json = makeExportJson(
        schemaVersion: 1,
        moves: [makeJsonMove()],
        fsrsCards: [
          {
            'moveId': 'move-1',
            'stability': 3.5,
            'difficulty': 4.0,
            'due': DateTime(2024, 2, 1).toIso8601String(),
            'fsrsState': 2,
          },
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.length, 1);
      expect(cards.first.entityId, 'move-1');
      expect(cards.first.entityType, 'move');
      expect(cards.first.stability, 3.5);
    });

    test('import with empty/missing arrays succeeds', () async {
      final json = jsonEncode({'schemaVersion': 6});

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 0);
      expect(result.reviewsImported, 0);
      expect(result.combosImported, 0);
    });

    test('decks and deckMoves imported correctly', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-1')],
        decks: [makeJsonDeck(id: 'deck-1', name: 'My Deck')],
        deckMoves: [makeJsonDeckMove(deckId: 'deck-1', moveId: 'move-1')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.decksImported, 1);
      expect(result.deckMovesImported, 1);

      final decks = await db.decksDao.getAll();
      expect(decks.length, 1);
      expect(decks.first.name, 'My Deck');

      final dms = await db.select(db.deckMoves).get();
      expect(dms.length, 1);
      expect(dms.first.deckId, 'deck-1');
    });

    test('replaceAll preserves decks/deckMoves not in import', () async {
      // Pre-populate
      await seedMove(db, id: 'move-1');
      await seedDeck(db, id: 'old-deck', name: 'Old Deck');
      await seedDeckMove(db, deckId: 'old-deck', moveId: 'move-1');

      // Import without decks — existing decks should stay (safe behavior)
      final json = makeExportJson(moves: [makeJsonMove(id: 'move-1')]);

      await StatsExportService.importFromJson(
        db, prefs, json, ImportMode.replaceAll,
      );

      expect((await db.decksDao.getAll()).length, 1);
      expect((await db.select(db.deckMoves).get()).length, 1);
    });

    test('fsrsCardsImported count is tracked', () async {
      final json = makeExportJson(
        moves: [makeJsonMove()],
        fsrsCards: [makeJsonFsrsCard()],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.fsrsCardsImported, 1);
    });

    test('reviews import with all FSRS fields', () async {
      final json = makeExportJson(
        moves: [makeJsonMove()],
        reviews: [
          makeJsonReview(fsrsPreState: 1, fsrsPostState: 2, comboId: null),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final reviews = await db.reviewsDao.watchAll().first;
      expect(reviews.first.fsrsPreState, 1);
      expect(reviews.first.fsrsPostState, 2);
    });

    test('battle results import with all fields', () async {
      final json = makeExportJson(
        battleResults: [
          makeJsonBattleResult(
            id: 'b-1',
            score: 250,
            movesReviewed: 15,
            goodCount: 8,
            hardCount: 4,
            againCount: 3,
            longestStreak: 5,
            difficulty: 'HARD',
          ),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final battles = await db.select(db.battleResults).get();
      expect(battles.length, 1);
      expect(battles.first.score, 250);
      expect(battles.first.difficulty, 'HARD');
      expect(battles.first.longestStreak, 5);
    });

    test('combos and comboMoves imported', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-1')],
        combos: [makeJsonCombo(id: 'combo-1', name: 'Power Combo')],
        comboMoves: [
          makeJsonComboMove(id: 'cm-1', comboId: 'combo-1', moveId: 'move-1'),
        ],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.combosImported, 1);
      expect(result.comboMovesImported, 1);

      final combos = await db.combosDao.getAll();
      expect(combos.first.name, 'Power Combo');
    });
  });

  // =========================================================================
  // Group D: importFromJson — merge mode
  // =========================================================================
  group('importFromJson merge', () {
    test('merge skips existing move IDs', () async {
      await seedMove(db, id: 'move-1', name: 'Original');

      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-1', name: 'Overwrite Attempt')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.movesImported, 0);
      final moves = await db.movesDao.getAll();
      expect(moves.first.name, 'Original');
    });

    test('merge adds items with new IDs', () async {
      await seedMove(db, id: 'move-1', name: 'Existing');

      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-2', name: 'Brand New')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.movesImported, 1);
      final moves = await db.movesDao.getAll();
      expect(moves.length, 2);
    });

    test('mixed: some new + some existing returns correct counts', () async {
      await seedMove(db, id: 'move-1', name: 'Existing');

      final json = makeExportJson(
        moves: [
          makeJsonMove(id: 'move-1', name: 'Existing Copy'),
          makeJsonMove(id: 'move-2', name: 'New Move'),
          makeJsonMove(id: 'move-3', name: 'Another New'),
        ],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.movesImported, 2);
      final moves = await db.movesDao.getAll();
      expect(moves.length, 3);
    });

    test('empty import changes nothing', () async {
      await seedMove(db, id: 'move-1');
      await seedReview(db, id: 'review-1', moveId: 'move-1');

      final json = makeExportJson();

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.totalImported, 0);
      expect(await db.movesDao.getAll(), hasLength(1));
      expect(await db.reviewsDao.watchAll().first, hasLength(1));
    });

    test('merge skips existing reviews by ID', () async {
      await seedMove(db, id: 'move-1');
      await seedReview(db, id: 'review-1', moveId: 'move-1');

      final json = makeExportJson(
        moves: [makeJsonMove()],
        reviews: [
          makeJsonReview(id: 'review-1', rating: 'EASY'),
          makeJsonReview(id: 'review-new', rating: 'HARD'),
        ],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.reviewsImported, 1);
      final reviews = await db.reviewsDao.watchAll().first;
      expect(reviews.length, 2);
    });

    test('merge skips existing combos by ID', () async {
      await seedCombo(db, id: 'combo-1', name: 'Original');

      final json = makeExportJson(
        combos: [makeJsonCombo(id: 'combo-1', name: 'Copy')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.combosImported, 0);
    });

    test('merge skips existing FSRS cards by entityId+entityType', () async {
      await seedMove(db, id: 'move-1');
      await seedFsrsCard(db, entityId: 'move-1', stability: 10.0);

      final json = makeExportJson(
        moves: [makeJsonMove()],
        fsrsCards: [makeJsonFsrsCard(entityId: 'move-1', stability: 99.0)],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.fsrsCardsImported, 0);
      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.stability, 10.0);
    });

    test('merge skips existing battle results by ID', () async {
      await seedBattleResult(db, id: 'battle-1');

      final json = makeExportJson(
        battleResults: [makeJsonBattleResult(id: 'battle-1', score: 999)],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.battleResultsImported, 0);
    });

    test('merge skips existing decks by ID', () async {
      await seedMove(db, id: 'move-1');
      await seedDeck(db, id: 'deck-1', name: 'Original');

      final json = makeExportJson(
        moves: [makeJsonMove()],
        decks: [makeJsonDeck(id: 'deck-1', name: 'Overwrite')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.decksImported, 0);
      final decks = await db.decksDao.getAll();
      expect(decks.first.name, 'Original');
    });

    test('merge skips existing deckMoves by composite key', () async {
      await seedMove(db, id: 'move-1');
      await seedDeck(db, id: 'deck-1');
      await seedDeckMove(db, deckId: 'deck-1', moveId: 'move-1');

      final json = makeExportJson(
        moves: [makeJsonMove()],
        decks: [makeJsonDeck()],
        deckMoves: [makeJsonDeckMove(deckId: 'deck-1', moveId: 'move-1')],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.merge,
      );

      expect(result.deckMovesImported, 0);
    });
  });

  // =========================================================================
  // Group E: Round-trip tests
  // =========================================================================
  group('round-trip export → import → export', () {
    test('empty DB round-trip', () async {
      final export1 = await StatsExportService.generateJsonExport(db, prefs);

      // Import into same DB (already empty)
      await StatsExportService.importFromJson(
        db,
        prefs,
        export1.json,
        ImportMode.replaceAll,
      );

      final export2 = await StatsExportService.generateJsonExport(db, prefs);

      final data1 = jsonDecode(export1.json) as Map<String, dynamic>;
      final data2 = jsonDecode(export2.json) as Map<String, dynamic>;

      expect(data2['moves'], data1['moves']);
      expect(data2['reviews'], data1['reviews']);
    });

    test('full dataset round-trip (all entity types)', () async {
      final originalJson = makeFullExportJson();

      await StatsExportService.importFromJson(
        db,
        prefs,
        originalJson,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;

      expect((data['moves'] as List).length, 2);
      expect((data['reviews'] as List).length, 2);
      expect((data['combos'] as List).length, 1);
      expect((data['comboMoves'] as List).length, 1);
      expect((data['battleResults'] as List).length, 1);
      expect((data['fsrsCards'] as List).length, 2);
      expect((data['decks'] as List).length, 1);
      expect((data['deckMoves'] as List).length, 1);
      expect((data['categories'] as List).length, 2);
    });

    test('DateTime precision preserved through round-trip', () async {
      final specificDate = DateTime(2024, 6, 15, 14, 30, 45);
      final json = makeExportJson(
        moves: [makeJsonMove(createdAt: specificDate)],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;
      final parsed = DateTime.parse(m['createdAt'] as String);

      expect(parsed.year, specificDate.year);
      expect(parsed.month, specificDate.month);
      expect(parsed.day, specificDate.day);
      expect(parsed.hour, specificDate.hour);
      expect(parsed.minute, specificDate.minute);
    });

    test('decimal precision for FSRS stability/difficulty', () async {
      final json = makeExportJson(
        moves: [makeJsonMove()],
        fsrsCards: [
          makeJsonFsrsCard(stability: 4.567890, difficulty: 5.123456),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.stability, closeTo(4.567890, 0.001));
      expect(cards.first.difficulty, closeTo(5.123456, 0.001));
    });

    test('unicode in names survives round-trip', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-1', name: 'フリーズ 🌀')],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;

      expect(m['name'], 'フリーズ 🌀');
    });

    test('null fields preserved as null through round-trip', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(videoFilename: null, originalVideoName: null)],
        reviews: [makeJsonReview(comboId: null)],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;
      final m = (data['moves'] as List).first as Map<String, dynamic>;

      expect(m['videoFilename'], isNull);
      expect(m['originalVideoName'], isNull);
    });

    test('polymorphic FSRS cards (move + combo) round-trip', () async {
      final json = makeExportJson(
        moves: [makeJsonMove(id: 'move-1')],
        combos: [makeJsonCombo(id: 'combo-1')],
        fsrsCards: [
          makeJsonFsrsCard(
            entityId: 'move-1',
            entityType: 'move',
            stability: 3.0,
          ),
          makeJsonFsrsCard(
            entityId: 'combo-1',
            entityType: 'combo',
            stability: 7.0,
          ),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;
      final cards = (data['fsrsCards'] as List).cast<Map<String, dynamic>>();

      final moveCard = cards.firstWhere((final c) => c['entityType'] == 'move');
      final comboCard = cards.firstWhere((final c) => c['entityType'] == 'combo');

      expect(moveCard['stability'], closeTo(3.0, 0.01));
      expect(comboCard['stability'], closeTo(7.0, 0.01));
    });

    test('categories round-trip via SharedPreferences', () async {
      final json = makeExportJson(
        categories: [
          makeJsonCategory(name: 'power', colorValue: 0xFFFF0000),
          makeJsonCategory(name: 'freeze', colorValue: 0xFF0000FF),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final exported = await StatsExportService.generateJsonExport(db, prefs);
      final data = jsonDecode(exported.json) as Map<String, dynamic>;
      final cats = (data['categories'] as List).cast<Map<String, dynamic>>();

      expect(cats.length, 2);
      expect(cats.map((final c) => c['name']), containsAll(['power', 'freeze']));
    });
  });

  // =========================================================================
  // Group F: Backward compatibility v1–v5
  // =========================================================================
  group('backward compatibility v1-v5', () {
    test('v1 moveId maps to entityId with type move', () async {
      final json = makeExportJson(
        schemaVersion: 1,
        moves: [makeJsonMove()],
        fsrsCards: [
          {
            'moveId': 'move-1',
            'stability': 2.0,
            'difficulty': 3.0,
            'due': DateTime(2024, 3, 1).toIso8601String(),
            'fsrsState': 1,
          },
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.entityId, 'move-1');
      expect(cards.first.entityType, 'move');
    });

    test('v1 videoPath triggers missing video tracking', () async {
      final json = jsonEncode({
        'schemaVersion': 1,
        'moves': [
          {
            'id': 'move-1',
            'name': 'Old Move',
            'videoPath': '/old/path/video.mp4',
          },
        ],
      });

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesWithMissingVideos, contains('Old Move'));
    });

    test('missing fsrsCards key does not crash', () async {
      final json = jsonEncode({
        'schemaVersion': 3,
        'moves': [
          {'id': 'move-1', 'name': 'Test'},
        ],
      });

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 1);
      expect(result.fsrsCardsImported, 0);
    });

    test('v5 moveId with no entityType defaults to move', () async {
      final json = makeExportJson(
        schemaVersion: 5,
        moves: [makeJsonMove()],
        fsrsCards: [
          {
            'moveId': 'move-1',
            'stability': 1.0,
            'difficulty': 2.0,
            'due': DateTime(2024, 4, 1).toIso8601String(),
            'fsrsState': 0,
          },
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.entityType, 'move');
    });

    test('v3 missing combos/comboMoves/battleResults arrays', () async {
      final json = jsonEncode({
        'schemaVersion': 3,
        'moves': [
          {'id': 'move-1', 'name': 'Solo Move'},
        ],
        'reviews': [
          {
            'id': 'r-1',
            'rating': 'GOOD',
            'reviewType': 'STANDARD',
            'moveId': 'move-1',
            'reviewedAt': DateTime(2024, 1, 1).toIso8601String(),
          },
        ],
      });

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 1);
      expect(result.reviewsImported, 1);
      expect(result.combosImported, 0);
      expect(result.comboMovesImported, 0);
      expect(result.battleResultsImported, 0);
    });
  });

  // =========================================================================
  // Group G: Edge cases
  // =========================================================================
  group('edge cases', () {
    test('500 moves + 2000 reviews scale test', () async {
      final moves = List.generate(
        500,
        (final i) => makeJsonMove(id: 'move-$i', name: 'Move $i'),
      );
      final reviews = List.generate(
        2000,
        (final i) => makeJsonReview(
          id: 'review-$i',
          moveId: 'move-${i % 500}',
          rating: ['AGAIN', 'HARD', 'GOOD', 'EASY'][i % 4],
        ),
      );
      final json = makeExportJson(moves: moves, reviews: reviews);

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 500);
      expect(result.reviewsImported, 2000);
    });

    test('special JSON characters in names (quotes, backslash)', () async {
      final json = makeExportJson(
        moves: [
          makeJsonMove(id: 'move-1', name: 'Wind"mill'),
          makeJsonMove(id: 'move-2', name: 'Head\\spin'),
          makeJsonMove(id: 'move-3', name: 'Top\nRock'),
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final moves = await db.movesDao.getAll();
      expect(moves.length, 3);
      final names = moves.map((final m) => m.name).toSet();
      expect(names, contains('Wind"mill'));
      expect(names, contains('Head\\spin'));
      expect(names, contains('Top\nRock'));
    });

    test('review with null moveId AND null comboId', () async {
      final json = makeExportJson(
        reviews: [makeJsonReview(id: 'r-1', moveId: null, comboId: null)],
      );

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.reviewsImported, 1);
      final reviews = await db.reviewsDao.watchAll().first;
      expect(reviews.first.moveId, isNull);
      expect(reviews.first.comboId, isNull);
    });

    test('FSRS stability as int in JSON handles num→double', () async {
      final json = makeExportJson(
        moves: [makeJsonMove()],
        fsrsCards: [
          {
            'entityId': 'move-1',
            'entityType': 'move',
            'stability': 5, // int, not double
            'difficulty': 3, // int, not double
            'due': DateTime(2024, 3, 1).toIso8601String(),
            'fsrsState': 2,
          },
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.stability, 5.0);
      expect(cards.first.difficulty, 3.0);
    });

    test('empty categories array does not overwrite existing prefs', () async {
      await prefs.setString(
        'categories',
        jsonEncode([
          {'name': 'power', 'colorValue': 0xFFFF0000},
        ]),
      );

      final json = makeExportJson(categories: []);

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      // Existing categories should remain — empty array doesn't overwrite
      final catJson = prefs.getString('categories');
      expect(catJson, isNotNull);
      final cats = jsonDecode(catJson!) as List;
      expect(cats.length, 1);
    });

    test('extra unknown fields in JSON silently ignored', () async {
      final json = jsonEncode({
        'schemaVersion': 6,
        'unknownField': 'should be ignored',
        'moves': [
          {'id': 'move-1', 'name': 'Test', 'extraField': 42},
        ],
        'reviews': <Map<String, Object?>>[],
        'futureEntity': [
          {'id': 'x'},
        ],
      });

      final result = await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      expect(result.movesImported, 1);
    });

    test('categories missing name/colorValue filtered out', () async {
      final json = makeExportJson(
        categories: [
          {'name': 'power', 'colorValue': 0xFFFF0000},
          {'name': null, 'colorValue': 0xFF00FF00}, // missing name
          {'name': 'freeze'}, // missing colorValue
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final catJson = prefs.getString('categories');
      expect(catJson, isNotNull);
      final cats = jsonDecode(catJson!) as List;
      expect(cats.length, 1);
      expect((cats.first as Map)['name'], 'power');
    });

    test('FSRS card with null stability/difficulty defaults to 0.0', () async {
      final json = makeExportJson(
        moves: [makeJsonMove()],
        fsrsCards: [
          {
            'entityId': 'move-1',
            'entityType': 'move',
            'stability': null,
            'difficulty': null,
            'due': DateTime(2024, 3, 1).toIso8601String(),
            'fsrsState': 0,
          },
        ],
      );

      await StatsExportService.importFromJson(
        db,
        prefs,
        json,
        ImportMode.replaceAll,
      );

      final cards = await db.fsrsCardsDao.getAll();
      expect(cards.first.stability, 0.0);
      expect(cards.first.difficulty, 0.0);
    });
  });

  // =========================================================================
  // Group H: Transaction atomicity
  // =========================================================================
  group('transaction atomicity', () {
    test(
      'categories import is outside transaction (succeeds independently)',
      () async {
        // This test documents behavior: categories are imported via
        // SharedPreferences outside the DB transaction, so they persist
        // even if the DB portion were to fail.
        final json = makeExportJson(
          moves: [makeJsonMove()],
          categories: [makeJsonCategory(name: 'test-cat')],
        );

        await StatsExportService.importFromJson(
          db,
          prefs,
          json,
          ImportMode.replaceAll,
        );

        final catJson = prefs.getString('categories');
        expect(catJson, isNotNull);
        expect(catJson, contains('test-cat'));
      },
    );

    test(
      'import within transaction ensures all-or-nothing for DB entities',
      () async {
        // Verify that a successful import populates all tables atomically
        final json = makeFullExportJson();

        await StatsExportService.importFromJson(
          db,
          prefs,
          json,
          ImportMode.replaceAll,
        );

        // All entities present — transaction committed successfully
        expect(await db.movesDao.getAll(), hasLength(2));
        expect(await db.reviewsDao.watchAll().first, hasLength(2));
        expect(await db.combosDao.getAll(), hasLength(1));
        expect(await db.select(db.comboMoves).get(), hasLength(1));
        expect(await db.select(db.battleResults).get(), hasLength(1));
        expect(await db.fsrsCardsDao.getAll(), hasLength(2));
        expect(await db.decksDao.getAll(), hasLength(1));
        expect(await db.select(db.deckMoves).get(), hasLength(1));
      },
    );
  });

  // =========================================================================
  // Group I: generateTextSummary
  // =========================================================================
  group('generateTextSummary', () {
    StatsBundle makeStats({
      final Map<String, int>? ratingDistribution,
      final List<MapEntry<String, int>>? topMoveEntries,
      final List<TopMoveInfo>? topMoves,
      final int currentStreak = 5,
      final List<Move>? allMoves,
      final double overallRetention = 0.85,
    }) {
      final defaultMoves = <Move>[];
      return StatsBundle(
        ratingDistribution:
            ratingDistribution ??
            {'AGAIN': 5, 'HARD': 10, 'GOOD': 30, 'EASY': 5},
        topMoveEntries: topMoveEntries ?? [],
        topMoves: topMoves ?? [],
        currentStreak: currentStreak,
        dailyCounts: {},
        allMoves: allMoves ?? defaultMoves,
        dueSummary: const DueSummary(
          newDue: 3,
          learningDue: 2,
          reviewDue: 5,
          totalDueToday: 10,
          dueTomorrow: 4,
        ),
        totalStateCounts: const TotalStateCounts(
          newCount: 10,
          learningCount: 5,
          reviewCount: 20,
        ),
        overallRetention: overallRetention,
        categoryMastery: [],
        dailyBreakdown: [],
        cardStats: const [],
        reviewTimeline: const [],
        moveProgressGroups: const [],
        comboProgressGroups: const [],
      );
    }

    test('populated stats produce correct format', () {
      final stats = makeStats();
      final summary = StatsExportService.generateTextSummary(stats);

      expect(summary, contains('Breakdex Stats'));
      expect(summary, contains('Retention: 85%'));
      expect(summary, contains('Streak: 5 days'));
      expect(summary, contains('AGAIN: 5'));
      expect(summary, contains('GOOD:  30'));
    });

    test('zero reviews produces 0% everywhere (no division-by-zero)', () {
      final stats = makeStats(
        ratingDistribution: {'AGAIN': 0, 'HARD': 0, 'GOOD': 0, 'EASY': 0},
        overallRetention: 0.0,
      );
      final summary = StatsExportService.generateTextSummary(stats);

      expect(summary, contains('Retention: 0%'));
      expect(summary, contains('AGAIN: 0 (0%)'));
      expect(summary, contains('GOOD:  0 (0%)'));
    });

    test('empty top moves shows "No moves practiced yet."', () {
      final stats = makeStats(topMoveEntries: []);
      final summary = StatsExportService.generateTextSummary(stats);

      expect(summary, contains('No moves practiced yet.'));
    });

    test('singular streak uses "day" not "days"', () {
      final stats = makeStats(currentStreak: 1);
      final summary = StatsExportService.generateTextSummary(stats);

      expect(summary, contains('Streak: 1 day'));
      expect(summary, isNot(contains('1 days')));
    });
  });

  // =========================================================================
  // Group J: exportFilename
  // =========================================================================
  group('exportFilename', () {
    test('matches breakdex_export_YYYY-MM-DD.json pattern', () {
      final filename = StatsExportService.exportFilename;

      expect(
        filename,
        matches(RegExp(r'breakdex_export_\d{4}-\d{2}-\d{2}\.json')),
      );
    });

    test('uses today\'s date', () {
      final today = DateTime.now().toIso8601String().split('T').first;
      final filename = StatsExportService.exportFilename;

      expect(filename, contains(today));
    });
  });
}
