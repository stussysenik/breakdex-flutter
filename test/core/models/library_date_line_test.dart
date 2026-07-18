import 'package:breakdex/core/models/library_date_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed afternoon so every case is read against one wall clock rather than
  // the wall clock of whenever the suite happens to run.
  final now = DateTime(2026, 7, 18, 14, 30);

  group('libraryDateLine — the relative arm', () {
    test('the same calendar day is today, however far apart the clocks are', () {
      expect(
        libraryDateLine(date: DateTime(2026, 7, 18, 0, 1), now: now).kind,
        LibraryDateLineKind.today,
      );
      expect(
        libraryDateLine(date: DateTime(2026, 7, 18, 23, 59), now: now).kind,
        LibraryDateLineKind.today,
      );
    });

    test('yesterday is the previous calendar day, not 24 elapsed hours', () {
      // 23h55m before `now`, yet a different calendar day: elapsed-time
      // arithmetic would call this "today".
      final spec = libraryDateLine(date: DateTime(2026, 7, 17, 14, 35), now: now);
      expect(spec.kind, LibraryDateLineKind.yesterday);
      expect(spec.days, 1);
    });

    test('two hours earlier can still be yesterday across midnight', () {
      final justAfterMidnight = DateTime(2026, 7, 18, 0, 30);
      expect(
        libraryDateLine(
          date: DateTime(2026, 7, 17, 22, 30),
          now: justAfterMidnight,
        ).kind,
        LibraryDateLineKind.yesterday,
      );
    });

    test('two through six days back count the days', () {
      for (var d = 2; d <= 6; d++) {
        final spec = libraryDateLine(
          date: now.subtract(Duration(days: d)),
          now: now,
        );
        expect(spec.kind, LibraryDateLineKind.daysAgo, reason: '$d days back');
        expect(spec.days, d, reason: '$d days back');
      }
    });

    test('a month boundary does not interrupt the day count', () {
      // 3 days back from Aug 2 is Jul 30 — the arithmetic is on day ordinals,
      // not on the day-of-month number.
      final spec = libraryDateLine(
        date: DateTime(2026, 7, 30, 9),
        now: DateTime(2026, 8, 2, 9),
      );
      expect(spec.kind, LibraryDateLineKind.daysAgo);
      expect(spec.days, 3);
    });
  });

  group('libraryDateLine — the absolute arm', () {
    test('the horizon is exclusive: day 6 is relative, day 7 is absolute', () {
      expect(
        libraryDateLine(date: now.subtract(const Duration(days: 6)), now: now).kind,
        LibraryDateLineKind.daysAgo,
      );
      expect(
        libraryDateLine(date: now.subtract(const Duration(days: 7)), now: now).kind,
        LibraryDateLineKind.absolute,
      );
    });

    test('the distant past is absolute', () {
      expect(
        libraryDateLine(date: DateTime(2019, 3, 4), now: now).kind,
        LibraryDateLineKind.absolute,
      );
    });

    test('a future date is absolute, never today', () {
      // A wrong device clock can stamp a filmed date ahead of now. It must not
      // borrow the relative arm through a negative delta (same ruling as the
      // month headers in library_month_sections.dart).
      final spec = libraryDateLine(date: DateTime(2026, 9, 1), now: now);
      expect(spec.kind, LibraryDateLineKind.absolute);
    });

    test('tomorrow is absolute too, not "1 day ago" with a flipped sign', () {
      expect(
        libraryDateLine(date: now.add(const Duration(days: 1)), now: now).kind,
        LibraryDateLineKind.absolute,
      );
    });
  });

  group('libraryDateLine — time zones', () {
    test('a UTC instant is classified against the local calendar', () {
      // Drift hands back UTC for some columns. Reading the raw instant would
      // put a late-evening capture on the following day for anyone east of
      // UTC and the previous one west of it. Vacuous under TZ=UTC — the two
      // inputs are the same wall clock there — so this discriminates only off
      // UTC; it is here because the behavior is load-bearing in production.
      final local = DateTime(2026, 7, 18, 23, 30);
      expect(
        libraryDateLine(date: local.toUtc(), now: now).kind,
        libraryDateLine(date: local, now: now).kind,
      );
    });

    test('the horizon holds across a whole-day span regardless of clock shifts', () {
      // Day keys are UTC-normalized ordinals, so a 23- or 25-hour local day
      // (DST) cannot round a 7-day gap down to 6 and leak into the relative arm.
      for (var d = 7; d <= 40; d++) {
        expect(
          libraryDateLine(date: now.subtract(Duration(days: d)), now: now).kind,
          LibraryDateLineKind.absolute,
          reason: '$d days back',
        );
      }
    });
  });
}
