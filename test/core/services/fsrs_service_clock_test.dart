import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/fsrs_service.dart';
import 'package:breakdex/core/utils/app_clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controllable clock pinned to a fixed instant — lets us assert that FSRS
/// scheduling decisions depend on the injected clock, not the system wall
/// clock. This is the payoff of routing FsrsService time through [AppClock]:
/// "due now" is now deterministic and testable.
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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // A review-state card whose next review is pinned to a fixed instant.
  final due = DateTime.utc(2026, 1, 1, 12);

  Future<void> insertReviewCard() async {
    await db.fsrsCardsDao.upsert(
      FsrsCardsCompanion.insert(
        entityId: 'm1',
        due: Value(due),
        fsrsState: const Value(2), // Review
      ),
    );
  }

  test('getDueSummary counts the card as due when the clock is past its due date', () async {
    await insertReviewCard();
    final svc = FsrsService(
      db.fsrsCardsDao,
      clock: _FakeClock(due.add(const Duration(days: 1))),
    );

    final summary = await svc.getDueSummary();

    expect(summary.totalDueNow, 1);
    expect(summary.reviewDue, 1);
  });

  test('getDueSummary treats the same card as not-yet-due when the clock is earlier', () async {
    await insertReviewCard();
    final svc = FsrsService(
      db.fsrsCardsDao,
      clock: _FakeClock(due.subtract(const Duration(days: 1))),
    );

    final summary = await svc.getDueSummary();

    expect(summary.totalDueNow, 0);
    expect(summary.dueTomorrow, 1);
  });
}
