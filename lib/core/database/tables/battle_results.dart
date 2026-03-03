import 'package:drift/drift.dart';

class BattleResults extends Table {
  TextColumn get id => text()();
  IntColumn get score => integer()();
  IntColumn get movesReviewed => integer()();
  IntColumn get goodCount => integer()();
  IntColumn get hardCount => integer()();
  IntColumn get againCount => integer()();
  IntColumn get longestStreak => integer()();
  TextColumn get difficulty => text()(); // EASY, MEDIUM, HARD
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
