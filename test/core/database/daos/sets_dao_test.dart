import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/sets_dao.dart';

import '../../../helpers/test_database.dart';

int _idCounter = 0;
String _nextId() => 'set-test-${_idCounter++}';
String _nextItemId() => 'si-test-${_idCounter++}';

void main() {
  late AppDatabase db;
  late SetsDao dao;

  setUp(() {
    _idCounter = 0;
    db = createTestDatabase();
    dao = SetsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Sets CRUD', () {
    test('createSet inserts a set and returns its id', () async {
      final id = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Power Moves'),
      );

      final set = await dao.getById(id);
      expect(set.name, 'Power Moves');
      expect(set.learningState, 0);
    });

    test('createSet with description', () async {
      final id = await dao.createSet(
        SetsCompanion.insert(
          id: _nextId(),
          name: 'Foundations',
          description: const Value('Basic fundamental moves'),
        ),
      );

      final set = await dao.getById(id);
      expect(set.name, 'Foundations');
      expect(set.description, 'Basic fundamental moves');
    });

    test('getAll returns all sets', () async {
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set A'));
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set B'));
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set C'));

      final all = await dao.getAll();
      expect(all.map((final s) => s.name), containsAll(['Set A', 'Set B', 'Set C']));
      expect(all.length, 3);
    });

    test('getById returns the correct set', () async {
      final id = await dao.createSet(
        SetsCompanion.insert(id: 's-target', name: 'Target Set'),
      );

      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Other Set'));

      final set = await dao.getById(id);
      expect(set.name, 'Target Set');
    });

    test('updateSet modifies a set', () async {
      final id = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Old Name'),
      );

      await dao.updateSet(
        SetsCompanion.insert(id: id, name: 'New Name'),
      );

      final set = await dao.getById(id);
      expect(set.name, 'New Name');
    });

    test('deleteSet removes a set', () async {
      final id = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'To Delete'),
      );

      final count = await dao.deleteSet(id);
      expect(count, 1);

      await expectLater(
        () => dao.getById(id),
        throwsA(isA<StateError>()),
      );
    });

    test('watchAll emits updated list when a set is created', () async {
      final stream = dao.watchAll();
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Reactive Set'));

      final list = await stream.first;
      expect(list.any((final s) => s.name == 'Reactive Set'), isTrue);
    });
  });

  group('Set Items', () {
    late String setId;

    setUp(() async {
      setId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Item Set'),
      );
    });

    test('addSetItem adds an item to a set', () async {
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(),
          setId: setId,
          itemType: 'move',
          itemId: 'move-1',
          position: 0,
        ),
      );

      final items = await dao.watchSetItems(setId).first;
      expect(items.length, 1);
      expect(items.first.itemType, 'move');
      expect(items.first.itemId, 'move-1');
      expect(items.first.position, 0);
    });

    test('set items are ordered by position', () async {
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'move', itemId: 'm1',
          position: 2,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'move', itemId: 'm2',
          position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'move', itemId: 'm3',
          position: 1,
        ),
      );

      final items = await dao.watchSetItems(setId).first;
      expect(items.map((final i) => i.itemId), ['m2', 'm3', 'm1']);
    });

    test('removeSetItem removes and reindexes', () async {
      final si1 = _nextItemId();
      final si2 = _nextItemId();
      final si3 = _nextItemId();
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si1, setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si2, setId: setId, itemType: 'move', itemId: 'm2',
          position: 1,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si3, setId: setId, itemType: 'move', itemId: 'm3',
          position: 2,
        ),
      );

      await dao.removeSetItem(si2);

      final items = await dao.watchSetItems(setId).first;
      expect(items.length, 2);
      expect(items.map((final i) => i.position), [0, 1]);
      expect(items.map((final i) => i.itemId), containsAll(['m1', 'm3']));
    });

    test('reorderSetItem moves item to new position', () async {
      final si1 = _nextItemId();
      final si2 = _nextItemId();
      final si3 = _nextItemId();
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si1, setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si2, setId: setId, itemType: 'move', itemId: 'm2',
          position: 1,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: si3, setId: setId, itemType: 'move', itemId: 'm3',
          position: 2,
        ),
      );

      await dao.reorderSetItem(si3, 0);

      final items = await dao.watchSetItems(setId).first;
      expect(items.map((final i) => i.itemId), ['m1', 'm3', 'm2']);
      expect(items.map((final i) => i.position), [0, 1, 2]);
    });

    test('same PK insertion updates existing row', () async {
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: 'dup-pk', setId: setId, itemType: 'move', itemId: 'm-pk',
          position: 0,
        ),
      );
      // Same PK, different position — upsert behaviour
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: 'dup-pk', setId: setId, itemType: 'move', itemId: 'm-pk',
          position: 5,
        ),
      );

      final items = await dao.watchSetItems(setId).first;
      expect(items.length, 1);
      expect(items.first.position, 5);
    });

    test('unique index exists and fires on direct insert', () async {
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: 'uc-1', setId: setId, itemType: 'move', itemId: 'm-uc',
          position: 0,
        ),
      );
      // Direct insert bypassing upsert — unique index violation
      await expectLater(
        () => db.customStatement(
          'INSERT INTO set_items (id, set_id, item_type, item_id, position) '
          "VALUES ('uc-2', '$setId', 'move', 'm-uc', 3)",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('supports mixed item types in a set', () async {
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'move', itemId: 'windmill',
          position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'combo', itemId: 'basic-flow',
          position: 1,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'set', itemId: 'subset-id',
          position: 2,
        ),
      );

      final items = await dao.watchSetItems(setId).first;
      expect(items.length, 3);
      final types = items.map((final i) => i.itemType).toSet();
      expect(types, containsAll(['move', 'combo', 'set']));
    });
  });

  group('Cycle detection', () {
    test('self-reference is rejected', () async {
      final setId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Self Set'),
      );

      final valid = await dao.validateNoCycle(setId, setId);
      expect(valid, isFalse);
    });

    test('direct cycle A → B → A is rejected', () async {
      final aId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set A'));
      final bId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set B'));

      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: aId, itemType: 'set', itemId: bId,
          position: 0,
        ),
      );

      final valid = await dao.validateNoCycle(bId, aId);
      expect(valid, isFalse);
    });

    test('indirect cycle A → B → C → A is rejected', () async {
      final aId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set A'));
      final bId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set B'));
      final cId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set C'));

      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: aId, itemType: 'set', itemId: bId,
          position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: bId, itemType: 'set', itemId: cId,
          position: 0,
        ),
      );

      final valid = await dao.validateNoCycle(cId, aId);
      expect(valid, isFalse);
    });

    test('valid nesting (no cycle) is accepted', () async {
      final aId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set A'));
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set B'));
      final cId = await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Set C'));

      final valid = await dao.validateNoCycle(aId, cId);
      expect(valid, isTrue);
    });
  });

  group('Depth enforcement', () {
    test('depth 0 for empty set', () async {
      final setId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Root Set'),
      );

      final d = await dao.depth(setId);
      expect(d, 0);
    });

    test('depth 1 with direct children (non-set items)', () async {
      final setId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Parent Set'),
      );

      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );

      final d = await dao.depth(setId);
      expect(d, 0);
    });

    test('depth counts nested set levels', () async {
      final rootId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Root'),
      );
      final childId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Child'),
      );
      final grandchildId = await dao.createSet(
        SetsCompanion.insert(id: _nextId(), name: 'Grandchild'),
      );

      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: rootId, itemType: 'set',
          itemId: childId, position: 0,
        ),
      );
      await dao.addSetItem(
        SetItemsCompanion.insert(
          id: _nextItemId(), setId: childId, itemType: 'set',
          itemId: grandchildId, position: 0,
        ),
      );

      final d = await dao.depth(rootId);
      expect(d, 2);
    });
  });

  group('Name uniqueness', () {
    test('duplicate set name is rejected by trigger', () async {
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Unique Name'));

      await expectLater(
        () => dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Unique Name')),
        throwsA(isA<Exception>()),
      );
    });

    test('set name conflicting with move name is rejected', () async {
      await db.movesDao.insertMove(
        MovesCompanion.insert(id: 'm-conflict', name: 'Airflare'),
      );

      await expectLater(
        () => dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Airflare')),
        throwsA(isA<Exception>()),
      );
    });

    test('set name conflicting with combo name is rejected', () async {
      await db.combosDao.insertCombo(
        CombosCompanion.insert(id: 'c-conflict', name: 'Foundation Combo'),
      );

      await expectLater(
        () => dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Foundation Combo')),
        throwsA(isA<Exception>()),
      );
    });

    test('case-insensitive duplicate is rejected', () async {
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Power Moves'));

      await expectLater(
        () => dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'power moves')),
        throwsA(isA<Exception>()),
      );
    });

    test('whitespace-only differences are rejected', () async {
      await dao.createSet(SetsCompanion.insert(id: _nextId(), name: '  Power  '));

      await expectLater(
        () => dao.createSet(SetsCompanion.insert(id: _nextId(), name: 'Power')),
        throwsA(isA<Exception>()),
      );
    });
  });
}
