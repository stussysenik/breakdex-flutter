import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/data/drift_repositories.dart';
import 'package:breakdex/core/data/sync_aware_repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/sets_dao.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SetsDao dao;
  late SetRepository directRepo;
  late SetRepository syncAwareRepo;

  setUp(() {
    db = createTestDatabase();
    dao = SetsDao(db);
    directRepo = DriftSetRepository(dao);
    syncAwareRepo = SyncAwareSetRepository(directRepo, db.syncDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftSetRepository CRUD', () {
    test('insert and getById', () async {
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'Power Moves'),
      );

      final set = await directRepo.getById('s1');
      expect(set.name, 'Power Moves');
      expect(set.learningState, 0);
    });

    test('getAll returns all sets', () async {
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'A'),
      );
      await directRepo.insert(
        SetsCompanion.insert(id: 's2', name: 'B'),
      );

      final all = await directRepo.getAll();
      expect(all.length, 2);
      expect(all.map((s) => s.name), containsAll(['A', 'B']));
    });

    test('update modifies a set', () async {
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'Old'),
      );
      await directRepo.update(
        SetsCompanion.insert(id: 's1', name: 'New'),
      );

      final set = await directRepo.getById('s1');
      expect(set.name, 'New');
    });

    test('delete removes a set', () async {
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'Gone'),
      );
      await directRepo.delete('s1');

      await expectLater(
        () => directRepo.getById('s1'),
        throwsA(isA<StateError>()),
      );
    });

    test('watchAll stream emits on insert', () async {
      final stream = directRepo.watchAll();
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'Reactive'),
      );

      final list = await stream.first;
      expect(list.any((s) => s.id == 's1'), isTrue);
    });

    test('watchById stream emits on update', () async {
      await directRepo.insert(
        SetsCompanion.insert(id: 's1', name: 'Old'),
      );

      final stream = directRepo.watchById('s1');
      await directRepo.update(
        SetsCompanion.insert(id: 's1', name: 'Updated'),
      );

      final set = await stream.first;
      expect(set.name, 'Updated');
    });
  });

  group('DriftSetRepository items', () {
    late String setId;

    setUp(() async {
      setId = 'set-1';
      await directRepo.insert(
        SetsCompanion.insert(id: setId, name: 'Test Set'),
      );
    });

    test('addItem and watchItems', () async {
      final stream = directRepo.watchItems(setId);

      await directRepo.addItem(
        SetItemsCompanion.insert(
          id: 'si-1', setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );

      final items = await stream.first;
      expect(items.length, 1);
      expect(items.first.itemId, 'm1');
    });

    test('removeItem', () async {
      await directRepo.addItem(
        SetItemsCompanion.insert(
          id: 'si-1', setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );
      await directRepo.removeItem('si-1');

      final items = await directRepo.watchItems(setId).first;
      expect(items.isEmpty, isTrue);
    });

    test('reorderItem', () async {
      await directRepo.addItem(
        SetItemsCompanion.insert(
          id: 'si-1', setId: setId, itemType: 'move', itemId: 'm1',
          position: 0,
        ),
      );
      await directRepo.addItem(
        SetItemsCompanion.insert(
          id: 'si-2', setId: setId, itemType: 'move', itemId: 'm2',
          position: 1,
        ),
      );

      await directRepo.reorderItem('si-2', 0);

      final items = await directRepo.watchItems(setId).first;
      expect(items.first.itemId, 'm1');
    });

    test('validateNoCycle', () async {
      final valid =
          await directRepo.validateNoCycle('parent', 'unrelated-child');
      expect(valid, isTrue);

      final self = await directRepo.validateNoCycle('same', 'same');
      expect(self, isFalse);
    });
  });

  group('SyncAwareSetRepository', () {
    test('insert logs to sync log', () async {
      await syncAwareRepo.insert(
        SetsCompanion.insert(id: 's-sync', name: 'Sync Set'),
      );

      final pendingCount = await db.syncDao.watchPendingCount().first;
      expect(pendingCount, 1);
    });

    test('update logs to sync log', () async {
      await syncAwareRepo.insert(
        SetsCompanion.insert(id: 's-sync', name: 'Sync Set'),
      );
      await syncAwareRepo.update(
        SetsCompanion.insert(id: 's-sync', name: 'Updated'),
      );

      final count = await db.syncDao.watchPendingCount().first;
      expect(count, 2);
    });

    test('delete logs to sync log', () async {
      await syncAwareRepo.insert(
        SetsCompanion.insert(id: 's-sync', name: 'Sync Set'),
      );
      await syncAwareRepo.delete('s-sync');

      final count = await db.syncDao.watchPendingCount().first;
      expect(count, 2);
    });

    test('reads delegate to inner repo', () async {
      await syncAwareRepo.insert(
        SetsCompanion.insert(id: 's-read', name: 'Read Test'),
      );
      // Reset pending count expectation
      final set = await syncAwareRepo.getById('s-read');
      expect(set.name, 'Read Test');

      final all = await syncAwareRepo.getAll();
      expect(all.length, 1);
    });

    test('addItem and removeItem log to sync', () async {
      await syncAwareRepo.insert(
        SetsCompanion.insert(id: 's-items', name: 'Item Set'),
      );

      await syncAwareRepo.addItem(
        SetItemsCompanion.insert(
          id: 'si-sync', setId: 's-items', itemType: 'move',
          itemId: 'm1', position: 0,
        ),
      );
      await syncAwareRepo.removeItem('si-sync');

      final count = await db.syncDao.watchPendingCount().first;
      expect(count, 3);
    });
  });
}
