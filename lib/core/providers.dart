import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'database/daos/moves_dao.dart';
import 'database/daos/combos_dao.dart';
import 'database/daos/reviews_dao.dart';
import 'data/repositories.dart';
import 'data/drift_repositories.dart';
import 'services/video_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// DAO providers (internal, used by repository implementations)
final movesDaoProvider = Provider<MovesDao>((ref) {
  return ref.watch(databaseProvider).movesDao;
});

final combosDaoProvider = Provider<CombosDao>((ref) {
  return ref.watch(databaseProvider).combosDao;
});

final reviewsDaoProvider = Provider<ReviewsDao>((ref) {
  return ref.watch(databaseProvider).reviewsDao;
});

// Repository providers (public API — use these in screens)
final moveRepositoryProvider = Provider<MoveRepository>((ref) {
  return DriftMoveRepository(ref.watch(movesDaoProvider));
});

final comboRepositoryProvider = Provider<ComboRepository>((ref) {
  return DriftComboRepository(ref.watch(combosDaoProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return DriftReviewRepository(ref.watch(reviewsDaoProvider));
});

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});
