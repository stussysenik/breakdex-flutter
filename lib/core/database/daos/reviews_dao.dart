import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/reviews.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [Reviews])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Stream<List<Review>> watchAll() =>
      (select(reviews)..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
          .watch();

  Future<void> insertReview(ReviewsCompanion entry) =>
      into(reviews).insert(entry);

  Future<List<Review>> getByMoveId(String moveId) =>
      (select(reviews)..where((t) => t.moveId.equals(moveId))).get();
}
