/// First-login provisioning trigger: mirrors the
/// [hydrateOnLoginTriggerProvider] regression test (see
/// `hydrate_on_login_trigger_test.dart`) for the *outbound* provisioning path.
///
/// The trigger must (a) never modify another provider during its own build,
/// (b) fire `activateSync()` exactly once per user, (c) be a no-op with no
/// session, (d) set the persisted one-shot flag only on success, and (e) leave
/// the flag unset on throw so the next launch retries.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart' show syncServiceProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/sync_activation_providers.dart';
import 'package:breakdex/core/services/sync_service.dart';
import 'package:breakdex/core/sync/backfill/sync_backfill_service.dart';
import 'package:breakdex/core/sync/sync_backend.dart';

import '../../helpers/test_database.dart';

void main() {
  const user = AuthUser(id: 'user-1', email: 'a@b.c');

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  /// Builds a [SyncService] whose `activateSync()` counts calls (in
  /// [activations]) then runs the real implementation against a fake
  /// backfill. [error] makes the fake backfill throw.
  SyncService countingService({
    required List<int> activations,
    Object? error,
  }) =>
      _CountingSyncService(
        db: db,
        prefs: prefs,
        activations: activations,
        error: error,
      );

  test('trigger does not modify providers during its own build', () async {
    final activations = <int>[];
    final container = ProviderContainer(
      overrides: [
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream.value(user),
        ),
        syncServiceProvider.overrideWith(
          (final ref) => countingService(activations: activations),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentAppwriteUserProvider.future);

    // Pre-fix this read threw the framework assertion.
    expect(
      () => container.read(firstLoginProvisioningTrigger),
      returnsNormally,
    );

    // The deferred provision fires exactly once for the same user.
    await Future<void>.delayed(Duration.zero);
    container.read(firstLoginProvisioningTrigger);
    await Future<void>.delayed(Duration.zero);
    expect(activations, [1]);
  });

  test('no session → trigger is a no-op (never calls activateSync)', () async {
    final activations = <int>[];
    final container = ProviderContainer(
      overrides: [
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream<AuthUser?>.value(null),
        ),
        syncServiceProvider.overrideWith(
          (final ref) => countingService(activations: activations),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(firstLoginProvisioningTrigger),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
    expect(activations, isEmpty);
  });

  test('success → persisted one-shot flag set for user', () async {
    final activations = <int>[];
    final container = ProviderContainer(
      overrides: [
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream.value(user),
        ),
        syncServiceProvider.overrideWith(
          (final ref) => countingService(activations: activations),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentAppwriteUserProvider.future);
    container.read(firstLoginProvisioningTrigger);
    await Future<void>.delayed(Duration.zero);

    expect(activations, [1]);
    expect(
      prefs.getBool(provisionedFlagKey(user.id)),
      isTrue,
    );
  });

  test('throw → flag NOT set so the next launch retries', () async {
    final activations = <int>[];
    final container = ProviderContainer(
      overrides: [
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream.value(user),
        ),
        syncServiceProvider.overrideWith(
          (final ref) => countingService(
            activations: activations,
            error: StateError('backend down'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentAppwriteUserProvider.future);
    expect(
      () => container.read(firstLoginProvisioningTrigger),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);

    expect(activations, [1]);
    expect(prefs.getBool(provisionedFlagKey(user.id)), isNull);
  });
}

/// A [SyncService] that counts `activateSync()` calls then delegates to the
/// real implementation. The base `activateSync()` only touches the injected
/// [SyncBackfillService] and [prefs], so [authService]/[syncDao]/[db] can be
/// real (test) instances.
class _CountingSyncService extends SyncService {
  _CountingSyncService({
    required super.db,
    required super.prefs,
    required this.activations,
    Object? error,
  }) : super(

          syncDao: db.syncDao,
          syncBackfillService: _FakeBackfill(db: db, error: error),
        );

  final List<int> activations;

  @override
  Future<List<BackfillReport>> activateSync() {
    activations.add(1);
    return super.activateSync();
  }
}

/// Minimal fake backend — stored by [SyncBackfillService] but never called.
class _FakeBackend implements SyncBackend {
  @override
  String get providerType => 'fake';
  @override
  Future<void> push(
    SyncEntityType type, {
    List<SyncRecord> upserts = const [],
    List<SyncTombstone> deletes = const [],
  }) async {}
  @override
  Future<SyncDelta> pull(SyncEntityType type, {DateTime? since}) async =>
      const SyncDelta(upserts: [], deletes: []);
  @override
  Stream<SyncDelta> subscribe(SyncEntityType type) => const Stream.empty();
}

class _FakeBackfill extends SyncBackfillService {
  _FakeBackfill({required this.db, this.error})
      : super(_FakeBackend(), db.movesDao);

  final AppDatabase db;
  final Object? error;

  static const _ok = BackfillReport(
    entityType: SyncEntityType.move,
    recordCount: 0,
    batchCount: 0,
  );

  Future<BackfillReport> _one() {
    final err = error;
    if (err is Error) throw err;
    if (err != null) throw StateError(err.toString());
    return Future.value(_ok);
  }

  @override
  Future<BackfillReport> backfillMoves() => _one();
  @override
  Future<BackfillReport> backfillCombos() => _one();
  @override
  Future<BackfillReport> backfillComboMoves() => _one();
  @override
  Future<BackfillReport> backfillReviews() => _one();
  @override
  Future<BackfillReport> backfillDecks() => _one();
  @override
  Future<BackfillReport> backfillDeckMoves() => _one();
  @override
  Future<BackfillReport> backfillMoveNoteEntries() => _one();
  @override
  Future<BackfillReport> backfillComboNoteEntries() => _one();
}
