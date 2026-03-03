import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/moves.dart';
import 'tables/combos.dart';
import 'tables/combo_moves.dart';
import 'tables/reviews.dart';
import 'tables/battle_results.dart';
import 'tables/sync_log.dart';
import 'daos/moves_dao.dart';
import 'daos/combos_dao.dart';
import 'daos/reviews_dao.dart';
import 'daos/sync_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Moves, Combos, ComboMoves, Reviews, BattleResults, SyncLog],
  daos: [MovesDao, CombosDao, ReviewsDao, SyncDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(battleResults);
          }
          if (from < 3) {
            await m.createTable(syncLog);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'breakdex.db'));
    return NativeDatabase.createInBackground(file);
  });
}
