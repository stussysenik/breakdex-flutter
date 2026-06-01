import 'package:breakdex/core/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_database.dart';

/// Tests for [AuraDao] — the data-access layer for Aura Links (move-to-move
/// transition graph) and Aura Presets (saved visual/gameplay configurations).
///
/// AuraLinks form a directed graph: fromMoveId -> toMoveId with an affinity
/// label ('natural', 'possible', 'stretch'). The composite PK (fromMoveId,
/// toMoveId) enables `insertOnConflictUpdate` for upsert semantics.
///
/// AuraPresets use a "single active" pattern where only one preset at a time
/// has isDefault = 1 — managed via [AuraDao.setActivePreset].
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // AuraLinks
  // ---------------------------------------------------------------------------

  group('AuraLinks — upsertLink', () {
    test('creates a new link between two moves', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');

      await db.auraDao.upsertLink('move-a', 'move-b', 'natural');

      final links = await db.auraDao.watchLinksFrom('move-a').first;
      expect(links, hasLength(1));
      expect(links.first.fromMoveId, 'move-a');
      expect(links.first.toMoveId, 'move-b');
      expect(links.first.affinity, 'natural');
    });

    test('creates link with notes', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');

      await db.auraDao.upsertLink(
        'move-a',
        'move-b',
        'possible',
        notes: 'Requires good momentum',
      );

      final links = await db.auraDao.watchLinksFrom('move-a').first;
      expect(links.first.notes, 'Requires good momentum');
    });

    test('updates existing link affinity on upsert', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');

      await db.auraDao.upsertLink('move-a', 'move-b', 'stretch');
      await db.auraDao.upsertLink('move-a', 'move-b', 'natural');

      final links = await db.auraDao.watchLinksFrom('move-a').first;
      expect(links, hasLength(1));
      expect(links.first.affinity, 'natural');
    });

    test('updates existing link notes on upsert', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');

      await db.auraDao.upsertLink('move-a', 'move-b', 'natural',
          notes: 'Old note');
      await db.auraDao.upsertLink('move-a', 'move-b', 'natural',
          notes: 'Updated note');

      final links = await db.auraDao.watchLinksFrom('move-a').first;
      expect(links.first.notes, 'Updated note');
    });
  });

  group('AuraLinks — deleteLink', () {
    test('removes the specified link', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');
      await db.auraDao.upsertLink('move-a', 'move-b', 'natural');

      await db.auraDao.deleteLink('move-a', 'move-b');

      final links = await db.auraDao.watchLinksFrom('move-a').first;
      expect(links, isEmpty);
    });

    test('deleting non-existent link is a no-op', () async {
      // Should not throw — nothing to delete.
      await db.auraDao.deleteLink('move-x', 'move-y');
    });
  });

  group('AuraLinks — watchLinksFrom', () {
    test('returns only outgoing links from the specified move', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');
      await seedMove(db, id: 'move-c', name: 'Flare');

      // A -> B (outgoing from A)
      await db.auraDao.upsertLink('move-a', 'move-b', 'natural');
      // C -> A (incoming to A, outgoing from C)
      await db.auraDao.upsertLink('move-c', 'move-a', 'stretch');
      // A -> C (outgoing from A)
      await db.auraDao.upsertLink('move-a', 'move-c', 'possible');

      final linksFromA = await db.auraDao.watchLinksFrom('move-a').first;
      expect(linksFromA, hasLength(2));

      final targetIds = linksFromA.map((final l) => l.toMoveId).toSet();
      expect(targetIds, containsAll(['move-b', 'move-c']));
    });

    test('returns empty list for move with no outgoing links', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');
      // Only incoming link to A.
      await db.auraDao.upsertLink('move-b', 'move-a', 'natural');

      final linksFromA = await db.auraDao.watchLinksFrom('move-a').first;
      expect(linksFromA, isEmpty);
    });
  });

  group('AuraLinks — watchLinksTo', () {
    test('returns only incoming links to the specified move', () async {
      await seedMove(db, id: 'move-a', name: 'Windmill');
      await seedMove(db, id: 'move-b', name: 'Headspin');
      await seedMove(db, id: 'move-c', name: 'Flare');

      // B -> A (incoming to A)
      await db.auraDao.upsertLink('move-b', 'move-a', 'natural');
      // C -> A (incoming to A)
      await db.auraDao.upsertLink('move-c', 'move-a', 'possible');
      // A -> B (outgoing from A — should NOT appear)
      await db.auraDao.upsertLink('move-a', 'move-b', 'stretch');

      final linksToA = await db.auraDao.watchLinksTo('move-a').first;
      expect(linksToA, hasLength(2));

      final sourceIds = linksToA.map((final l) => l.fromMoveId).toSet();
      expect(sourceIds, containsAll(['move-b', 'move-c']));
    });
  });

  // ---------------------------------------------------------------------------
  // AuraPresets
  // ---------------------------------------------------------------------------

  group('AuraPresets — CRUD', () {
    test('insertPreset creates a new preset', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill Vibe',
      ));

      final presets = await db.auraDao.watchPresets().first;
      expect(presets, hasLength(1));
      expect(presets.first.name, 'Chill Vibe');
      expect(presets.first.isDefault, 0);
    });

    test('multiple presets can be created', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill',
      ));
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-2',
        name: 'Hype',
      ));

      final presets = await db.auraDao.watchPresets().first;
      expect(presets, hasLength(2));
    });
  });

  group('AuraPresets — setActivePreset', () {
    test('sets a preset as active', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill',
      ));

      await db.auraDao.setActivePreset('preset-1');

      final active = await db.auraDao.getActivePreset();
      expect(active, isNotNull);
      expect(active!.id, 'preset-1');
      expect(active.isDefault, 1);
    });

    test('switching active preset clears other defaults', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill',
      ));
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-2',
        name: 'Hype',
      ));

      // Activate preset-1.
      await db.auraDao.setActivePreset('preset-1');
      var active = await db.auraDao.getActivePreset();
      expect(active!.id, 'preset-1');

      // Switch to preset-2.
      await db.auraDao.setActivePreset('preset-2');
      active = await db.auraDao.getActivePreset();
      expect(active!.id, 'preset-2');

      // Verify only one preset has isDefault = 1.
      final presets = await db.auraDao.watchPresets().first;
      final activeCount = presets.where((final p) => p.isDefault == 1).length;
      expect(activeCount, 1);
    });

    test('getActivePreset returns null when no preset is active', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill',
      ));

      final active = await db.auraDao.getActivePreset();
      expect(active, isNull);
    });

    test('setActivePreset with three presets leaves exactly one active',
        () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'A',
      ));
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-2',
        name: 'B',
      ));
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-3',
        name: 'C',
      ));

      await db.auraDao.setActivePreset('preset-1');
      await db.auraDao.setActivePreset('preset-3');

      final presets = await db.auraDao.watchPresets().first;
      final activeIds =
          presets.where((final p) => p.isDefault == 1).map((final p) => p.id).toList();
      expect(activeIds, ['preset-3']);
    });
  });

  group('AuraPresets — watchPresets stream', () {
    test('emits on insert', () async {
      final stream = db.auraDao.watchPresets();

      final initial = await stream.first;
      expect(initial, isEmpty);

      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'New Preset',
      ));

      final afterInsert = await stream.first;
      expect(afterInsert, hasLength(1));
    });

    test('emits on active preset change', () async {
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-1',
        name: 'Chill',
      ));
      await db.auraDao.insertPreset(AuraPresetsCompanion.insert(
        id: 'preset-2',
        name: 'Hype',
      ));

      await db.auraDao.setActivePreset('preset-1');

      final presets = await db.auraDao.watchPresets().first;
      final activePreset = presets.firstWhere((final p) => p.isDefault == 1);
      expect(activePreset.id, 'preset-1');
    });
  });
}
