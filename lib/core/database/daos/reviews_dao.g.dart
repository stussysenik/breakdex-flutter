// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MovesTable get moves => attachedDatabase.moves;
  $ReviewsTable get reviews => attachedDatabase.reviews;
  ReviewsDaoManager get managers => ReviewsDaoManager(this);
}

class ReviewsDaoManager {
  final _$ReviewsDaoMixin _db;
  ReviewsDaoManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db.attachedDatabase, _db.moves);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db.attachedDatabase, _db.reviews);
}
