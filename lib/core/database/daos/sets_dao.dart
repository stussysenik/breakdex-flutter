import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sets.dart';
import '../tables/set_items.dart';

part 'sets_dao.g.dart';

@DriftAccessor(tables: [Sets, SetItems])
class SetsDao extends DatabaseAccessor<AppDatabase> with _$SetsDaoMixin {
  SetsDao(super.db);

  Future<String> createSet(final SetsCompanion entry) {
    return into(sets).insertReturning(entry).then((final row) => row.id);
  }

  Future<bool> updateSet(final SetsCompanion entry) {
    return update(sets).replace(entry);
  }

  Future<int> deleteSet(final String id) {
    return (delete(sets)..where((final t) => t.id.equals(id))).go();
  }

  Future<BreakdexSet> getById(final String id) {
    return (select(sets)..where((final t) => t.id.equals(id))).getSingle();
  }

  Future<List<BreakdexSet>> getAll() {
    return select(sets).get();
  }

  Stream<List<BreakdexSet>> watchAll() {
    return select(sets).watch();
  }

  Stream<BreakdexSet> watchById(final String id) {
    return (select(sets)..where((final t) => t.id.equals(id))).watchSingle();
  }

  Future<void> addSetItem(final SetItemsCompanion entry) async {
    await into(setItems).insertOnConflictUpdate(entry);
  }

  Future<void> removeSetItem(final String id) async {
    final item = await (select(setItems)..where((final t) => t.id.equals(id))).getSingle();
    await (delete(setItems)..where((final t) => t.id.equals(id))).go();
    await _reindexSetItems(item.setId);
  }

  Future<void> reorderSetItem(final String itemId, final int newPosition) async {
    final item = await (select(setItems)..where((final t) => t.id.equals(itemId))).getSingle();
    await (update(setItems)..where((final t) => t.id.equals(itemId))).write(
      SetItemsCompanion(position: Value(newPosition)),
    );
    await _reindexSetItems(item.setId);
  }

  Stream<List<SetItem>> watchSetItems(final String setId) {
    return (select(setItems)
      ..where((final t) => t.setId.equals(setId))
      ..orderBy([(final t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Future<bool> validateNoCycle(final String setId, final String childSetId) async {
    if (setId == childSetId) return false;

    // Walk UP from childSetId to find if setId is an ancestor (would create
    // a cycle if setId is already reachable as a parent of childSetId).
    final visited = <String>{setId};
    final queue = <String>[childSetId];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!visited.add(current)) continue;
      if (current == setId) return false;
      final parentItems = await (select(setItems)
        ..where((final t) => t.itemId.equals(current) & t.itemType.equals('set')))
          .get();
      for (final item in parentItems) {
        queue.add(item.setId);
      }
    }

    // Walk DOWN from childSetId to find if setId is a descendant (would
    // create a cycle if setId is already contained by childSetId).
    final descQueue = <String>[childSetId];
    final descVisited = <String>{childSetId};
    while (descQueue.isNotEmpty) {
      final current = descQueue.removeAt(0);
      final childItems = await (select(setItems)
        ..where((final t) => t.setId.equals(current) & t.itemType.equals('set')))
          .get();
      for (final item in childItems) {
        if (item.itemId == setId) return false;
        if (descVisited.add(item.itemId)) {
          descQueue.add(item.itemId);
        }
      }
    }

    return true;
  }

  Future<int> depth(final String setId) async {
    var maxDepth = 0;
    final visited = <String>{setId};
    final queue = <(String, int)>[(setId, 0)];
    while (queue.isNotEmpty) {
      final (current, depth) = queue.removeAt(0);
      if (depth > maxDepth) maxDepth = depth;
      if (depth >= 5) continue;
      final childItems = await (select(setItems)
        ..where((final t) => t.setId.equals(current) & t.itemType.equals('set')))
          .get();
      for (final item in childItems) {
        if (visited.add(item.itemId)) {
          queue.add((item.itemId, depth + 1));
        }
      }
    }
    return maxDepth;
  }

  Future<void> _reindexSetItems(final String setId) async {
    final items = await (select(setItems)
      ..where((final t) => t.setId.equals(setId))
      ..orderBy([(final t) => OrderingTerm(expression: t.position)]))
        .get();
    for (var i = 0; i < items.length; i++) {
      if (items[i].position != i) {
        await (update(setItems)..where((final t) => t.id.equals(items[i].id))).write(
          SetItemsCompanion(position: Value(i)),
        );
      }
    }
  }
}
