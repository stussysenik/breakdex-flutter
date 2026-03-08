import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/database/database.dart';

import '../../helpers/test_database.dart';

void main() {
  group('reviewable constraints', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('move and combo names stay globally unique', () async {
      await db
          .into(db.moves)
          .insert(MovesCompanion.insert(id: 'move-1', name: 'Windmill'));

      expect(
        () => db
            .into(db.combos)
            .insert(CombosCompanion.insert(id: 'combo-1', name: ' windmill ')),
        throwsA(isA<Exception>()),
      );
    });

    test('same move cannot be added to one combo twice', () async {
      await db
          .into(db.moves)
          .insert(MovesCompanion.insert(id: 'move-1', name: 'Halo'));
      await db
          .into(db.combos)
          .insert(CombosCompanion.insert(id: 'combo-1', name: 'Halo Run'));

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

      expect(
        () => db
            .into(db.comboMoves)
            .insert(
              ComboMovesCompanion.insert(
                id: 'cm-2',
                comboId: 'combo-1',
                moveId: 'move-1',
                sequenceIndex: 1,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
