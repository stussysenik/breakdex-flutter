import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../helpers/test_data.dart';
import '../../helpers/test_database.dart';

void main() {
  group('CombosDao.watchAllWithMoveCounts', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('emits combos with aggregated move counts', () async {
      await seedMove(db, id: 'move-1', name: 'Windmill');
      await seedMove(db, id: 'move-2', name: 'Headspin');
      await seedCombo(db, id: 'combo-1', name: 'Power Set');
      await seedCombo(db, id: 'combo-2', name: 'Freeze Set');

      await db
          .into(db.comboMoves)
          .insert(
            ComboMovesCompanion.insert(
              id: 'cm-1',
              comboId: 'combo-1',
              moveId: 'move-1',
              sequenceIndex: 0,
            ),
          );
      await db
          .into(db.comboMoves)
          .insert(
            ComboMovesCompanion.insert(
              id: 'cm-2',
              comboId: 'combo-1',
              moveId: 'move-2',
              sequenceIndex: 1,
            ),
          );

      final results = await db.combosDao.watchAllWithMoveCounts().first;
      final counts = {for (final (combo, count) in results) combo.id: count};

      expect(counts['combo-1'], 2);
      expect(counts['combo-2'], 0);
    });
  });
}
