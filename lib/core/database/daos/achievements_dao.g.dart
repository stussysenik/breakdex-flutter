// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_dao.dart';

// ignore_for_file: type=lint
mixin _$AchievementsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MovesTable get moves => attachedDatabase.moves;
  $AchievementsTable get achievements => attachedDatabase.achievements;
  AchievementsDaoManager get managers => AchievementsDaoManager(this);
}

class AchievementsDaoManager {
  final _$AchievementsDaoMixin _db;
  AchievementsDaoManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db.attachedDatabase, _db.achievements);
}
