import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database.dart';
import 'database/daos/moves_dao.dart';
import 'database/daos/combos_dao.dart';
import 'database/daos/reviews_dao.dart';
import 'database/daos/sync_dao.dart';
import 'data/repositories.dart';
import 'data/drift_repositories.dart';
import 'data/sync_aware_repositories.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/video_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'models/sync_progress.dart';

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

final syncDaoProvider = Provider<SyncDao>((ref) {
  return ref.watch(databaseProvider).syncDao;
});

// Auth
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

final isLoggedInProvider = Provider<bool>((ref) {
  try {
    return ref.watch(authServiceProvider).isLoggedIn;
  } catch (_) {
    return false;
  }
});

// Repository providers (public API — use these in screens)
// When logged in, repos are wrapped with sync-aware decorators that log changes.
final moveRepositoryProvider = Provider<MoveRepository>((ref) {
  final inner = DriftMoveRepository(ref.watch(movesDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareMoveRepository(inner, ref.watch(syncDaoProvider));
});

final comboRepositoryProvider = Provider<ComboRepository>((ref) {
  final inner = DriftComboRepository(ref.watch(combosDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareComboRepository(inner, ref.watch(syncDaoProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final inner = DriftReviewRepository(ref.watch(reviewsDaoProvider));
  if (!ref.watch(isLoggedInProvider)) return inner;
  return SyncAwareReviewRepository(inner, ref.watch(syncDaoProvider));
});

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

// Sync
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    authService: ref.watch(authServiceProvider),
    syncDao: ref.watch(syncDaoProvider),
    db: ref.watch(databaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  return ref.watch(syncServiceProvider).progressStream;
});

final pendingChangesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncDaoProvider).watchPendingCount();
});

// Connectivity + auto-sync
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

final autoSyncEnabledProvider =
    NotifierProvider<AutoSyncNotifier, bool>(AutoSyncNotifier.new);

class AutoSyncNotifier extends Notifier<bool> {
  static const _key = 'auto_sync_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newValue = !state;
    await prefs.setBool(_key, newValue);
    state = newValue;
  }
}

// Auto-sync trigger — watches connectivity + setting + pending count
final syncTriggerProvider = Provider<void>((ref) {
  final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;
  final autoSync = ref.watch(autoSyncEnabledProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final pendingCount = ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;

  if (isOnline && autoSync && isLoggedIn && pendingCount > 0) {
    ref.read(syncServiceProvider).sync();
  }
});
