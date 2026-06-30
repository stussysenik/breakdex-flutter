import 'package:breakdex/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the move-log reactivity fix.
///
/// `LogsSection` previously read move logs via `getByMoveId().asStream()` —
/// a one-shot Future-as-stream that never re-emitted after a write, so the
/// detail screen only refreshed on a leave-and-return. `watchByMoveId` is a
/// live Drift stream: a single subscription must re-emit on every
/// add / delete so the UI updates instantly.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (final rawDb) {
          rawDb.execute('PRAGMA foreign_keys=ON');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('watchByMoveId re-emits on every add and delete (single subscription)',
      () async {
    const moveId = 'move-1';
    await db.into(db.moves).insert(
          MovesCompanion.insert(id: moveId, name: 'Six Step'),
        );

    final dao = db.moveNoteEntriesDao;

    final emittedLengths = <int>[];
    final sub =
        dao.watchByMoveId(moveId).listen((final rows) => emittedLengths.add(rows.length));

    // Initial emission for an empty log.
    await pumpEventQueue();

    await dao.addEntry(id: 'n1', moveId: moveId, body: 'worked the run-up');
    await pumpEventQueue();

    await dao.addEntry(id: 'n2', moveId: moveId, body: 'cleaner landing');
    await pumpEventQueue();

    await dao.deleteEntry('n1');
    await pumpEventQueue();

    await sub.cancel();

    // 0 (initial) → 1 (add) → 2 (add) → 1 (delete): proves live re-emission.
    expect(emittedLengths, [0, 1, 2, 1]);
  });
}
