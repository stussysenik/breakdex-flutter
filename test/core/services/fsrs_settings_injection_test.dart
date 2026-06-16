import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/fsrs_settings.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/fsrs_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/utils/app_clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clock pinned to a fixed instant so interval comparisons are deterministic.
class _FakeClock implements AppClock {
  _FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  Duration get monotonic => Duration.zero;
}

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 6, 1, 12);
  final clock = _FakeClock(now);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // A matured Review-state card: retention is what governs its next interval.
  Future<void> seedReviewCard() async {
    await db.fsrsCardsDao.upsert(
      FsrsCardsCompanion.insert(
        entityId: 'm1',
        stability: const Value(30.0),
        difficulty: const Value(5.0),
        due: Value(now.subtract(const Duration(days: 1))),
        lastReview: Value(now.subtract(const Duration(days: 30))),
        fsrsState: const Value(2),
      ),
    );
  }

  test(
    'non-default retention yields a different (shorter) next interval than defaults',
    () async {
      await seedReviewCard();

      // Fuzzing off on both so the comparison is deterministic.
      final baseSettings =
          FsrsSettings.defaults.copyWith(enableFuzzing: false);
      final tightSettings = baseSettings.copyWith(desiredRetention: 0.97);

      final baseSvc =
          FsrsService(db.fsrsCardsDao, clock: clock, settings: baseSettings);
      final tightSvc =
          FsrsService(db.fsrsCardsDao, clock: clock, settings: tightSettings);

      final basePreview = await baseSvc.previewIntervals('m1');
      final tightPreview = await tightSvc.previewIntervals('m1');

      final baseGood = basePreview[ReviewRating.good]!;
      final tightGood = tightPreview[ReviewRating.good]!;

      expect(baseGood, isNot(equals(tightGood)),
          reason: 'injection is wired — retention changes the schedule');
      expect(tightGood < baseGood, true,
          reason: 'higher retention ⇒ more frequent (shorter) reviews');
    },
  );

  test(
    'editing settings through the provider never writes the stored fsrs_cards row',
    () async {
      await seedReviewCard();
      final before = await db.fsrsCardsDao.getByEntityId('m1');

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          appClockProvider.overrideWithValue(clock),
        ],
      );
      addTearDown(container.dispose);

      // Build the service (reads settings), then edit a parameter.
      container.read(fsrsServiceProvider);
      await container
          .read(fsrsSettingsProvider.notifier)
          .setDesiredRetention(0.97);
      // Service rebuilds from the new settings.
      container.read(fsrsServiceProvider);

      final after = await db.fsrsCardsDao.getByEntityId('m1');
      expect(after!.stability, before!.stability);
      expect(after.difficulty, before.difficulty);
      expect(after.due, before.due);
      expect(after.fsrsState, before.fsrsState);
    },
  );
}
