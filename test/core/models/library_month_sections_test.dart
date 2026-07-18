import 'package:breakdex/core/models/library_month_sections.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for a library item: all the bucketing cares about is a date.
typedef _Item = ({String name, DateTime date});

List<LibraryMonthSection<_Item>> _sections(final List<_Item> items) =>
    libraryMonthSections(items, (final i) => i.date);

List<String> _names(final LibraryMonthSection<_Item> section) =>
    section.items.map((final i) => i.name).toList();

void main() {
  group('libraryMonthSections', () {
    test('splits a sorted feed at every month change, order preserved', () {
      final sections = _sections([
        (name: 'jul-late', date: DateTime(2026, 7, 18)),
        (name: 'jul-early', date: DateTime(2026, 7, 2)),
        (name: 'jun', date: DateTime(2026, 6, 30)),
        (name: 'apr', date: DateTime(2026, 4, 1)),
      ]);

      expect(sections.map((final s) => (s.year, s.month)).toList(), [
        (2026, 7),
        (2026, 6),
        (2026, 4),
      ]);
      expect(_names(sections[0]), ['jul-late', 'jul-early']);
      expect(_names(sections[1]), ['jun']);
      expect(_names(sections[2]), ['apr']);
    });

    test('a month edge one second wide still splits', () {
      final sections = _sections([
        (name: 'august', date: DateTime(2026, 8, 1, 0, 0, 0)),
        (name: 'july', date: DateTime(2026, 7, 31, 23, 59, 59)),
      ]);

      expect(sections, hasLength(2));
      expect((sections[0].year, sections[0].month), (2026, 8));
      expect((sections[1].year, sections[1].month), (2026, 7));
    });

    test('the same month in different years never merges', () {
      final sections = _sections([
        (name: 'this-july', date: DateTime(2026, 7, 10)),
        (name: 'last-july', date: DateTime(2025, 7, 10)),
      ]);

      expect(sections, hasLength(2));
      expect(sections[0].year, 2026);
      expect(sections[1].year, 2025);
    });

    test('an empty feed has no sections', () {
      expect(_sections([]), isEmpty);
    });

    // Drift hands back UTC instants for some columns. Bucketing on the raw
    // instant would put a late-evening capture in the following month for
    // anyone west of UTC, so the section is read in local time.
    //
    // Honest caveat: under TZ=UTC this assertion is vacuous — the two inputs
    // are the same wall clock — so it discriminates only off UTC. It is here
    // because the normalization is load-bearing in production, not because it
    // is provable everywhere.
    test('a UTC instant buckets by its local month', () {
      final local = DateTime(2026, 7, 31, 23, 30);
      final asUtc = local.toUtc();

      final sections = _sections([(name: 'capture', date: asUtc)]);

      expect((sections.single.year, sections.single.month), (2026, 7));
    });
  });

  group('libraryMonthLabel', () {
    final now = DateTime(2026, 7, 18, 9, 30);

    test('the current month is relative', () {
      expect(
        libraryMonthLabel(year: 2026, month: 7, now: now),
        LibraryMonthLabel.thisMonth,
      );
    });

    test('the prior month is relative', () {
      expect(
        libraryMonthLabel(year: 2026, month: 6, now: now),
        LibraryMonthLabel.lastMonth,
      );
    });

    test('two months back is absolute', () {
      expect(
        libraryMonthLabel(year: 2026, month: 5, now: now),
        LibraryMonthLabel.absolute,
      );
    });

    test('December reads as last month from January', () {
      expect(
        libraryMonthLabel(year: 2025, month: 12, now: DateTime(2026, 1, 4)),
        LibraryMonthLabel.lastMonth,
      );
      expect(
        libraryMonthLabel(year: 2026, month: 1, now: DateTime(2026, 1, 4)),
        LibraryMonthLabel.thisMonth,
      );
    });

    test('the same month a year earlier is absolute, not relative', () {
      expect(
        libraryMonthLabel(year: 2025, month: 7, now: now),
        LibraryMonthLabel.absolute,
      );
    });

    // A wrong device clock can stamp a capture in the future; it must not
    // borrow "this month"'s label by way of a negative delta.
    test('a future month is absolute', () {
      expect(
        libraryMonthLabel(year: 2026, month: 8, now: now),
        LibraryMonthLabel.absolute,
      );
    });
  });

  group('libraryGroupsByMonth', () {
    test('every date dimension groups', () {
      expect(libraryGroupsByMonth(LibrarySort.recentlyAdded), isTrue);
      expect(libraryGroupsByMonth(LibrarySort.recentlyFilmed), isTrue);
      expect(libraryGroupsByMonth(LibrarySort.recentlyPracticed), isTrue);
    });

    test('A–Z does not group', () {
      expect(libraryGroupsByMonth(LibrarySort.alphabetical), isFalse);
    });
  });
}
