import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/moves.dart';
import 'tables/combos.dart';
import 'tables/combo_moves.dart';
import 'tables/reviews.dart';
import 'daos/moves_dao.dart';
import 'daos/combos_dao.dart';
import 'daos/reviews_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Moves, Combos, ComboMoves, Reviews],
  daos: [MovesDao, CombosDao, ReviewsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'breakdex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
