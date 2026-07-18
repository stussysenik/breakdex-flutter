import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Drives the month headers directly instead of pumping the library screen,
/// which reads live Drift streams that flake widget tests. `now` is injected
/// so the relative/absolute boundary is pinned rather than racing the clock.
void main() {
  Future<void> pumpSlivers(
    final WidgetTester tester,
    final Widget sliver,
  ) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CustomScrollView(slivers: [sliver])),
        ),
      );

  group('LibraryMonthHeader', () {
    final today = DateTime(2026, 7, 18);

    Future<void> pumpHeader(
      final WidgetTester tester, {
      required final int year,
      required final int month,
    }) =>
        pumpSlivers(
          tester,
          LibraryMonthHeader(year: year, month: month, now: today),
        );

    testWidgets('the current month reads relatively', (final tester) async {
      await pumpHeader(tester, year: 2026, month: 7);
      expect(find.text('THIS MONTH'), findsOneWidget);
    });

    testWidgets('the prior month reads relatively', (final tester) async {
      await pumpHeader(tester, year: 2026, month: 6);
      expect(find.text('LAST MONTH'), findsOneWidget);
    });

    testWidgets('older months read absolutely, with the year', (
      final tester,
    ) async {
      await pumpHeader(tester, year: 2026, month: 4);
      expect(find.text('APRIL 2026'), findsOneWidget);
    });

    // A month a year back must not borrow the relative label of the same
    // month number.
    testWidgets('the same month last year is absolute', (final tester) async {
      await pumpHeader(tester, year: 2025, month: 7);
      expect(find.text('JULY 2025'), findsOneWidget);
      expect(find.text('THIS MONTH'), findsNothing);
    });
  });

  group('librarySectionedSliver', () {
    // Two months, so a header that renders once for the whole feed is
    // distinguishable from one that renders per section.
    final items = <({String name, DateTime date})>[
      (name: 'july-late', date: DateTime(2026, 7, 18)),
      (name: 'july-early', date: DateTime(2026, 7, 2)),
      (name: 'june', date: DateTime(2026, 6, 30)),
    ];

    Widget build({
      required final LibrarySort sort,
      required final ViewMode viewMode,
    }) =>
        librarySectionedSliver<({String name, DateTime date})>(
          items: items,
          sort: sort,
          viewMode: viewMode,
          dateOf: (final i) => i.date,
          now: DateTime(2026, 7, 18),
          sliverOf: (final section) => SliverList.list(
            children: [for (final i in section) Text(i.name)],
          ),
        );

    testWidgets('scan mode under a date sort gets one header per month', (
      final tester,
    ) async {
      await pumpSlivers(
        tester,
        build(sort: LibrarySort.recentlyAdded, viewMode: ViewMode.scan),
      );

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('LAST MONTH'), findsOneWidget);
      // Every item still renders exactly once — grouping is a projection of
      // the ordering, not a filter.
      for (final item in items) {
        expect(find.text(item.name), findsOneWidget);
      }
    });

    testWidgets('sections keep the feed order they arrived in', (
      final tester,
    ) async {
      await pumpSlivers(
        tester,
        build(sort: LibrarySort.recentlyAdded, viewMode: ViewMode.scan),
      );

      double topOf(final String text) =>
          tester.getTopLeft(find.text(text)).dy;

      expect(topOf('THIS MONTH'), lessThan(topOf('july-late')));
      expect(topOf('july-late'), lessThan(topOf('july-early')));
      expect(topOf('july-early'), lessThan(topOf('LAST MONTH')));
      expect(topOf('LAST MONTH'), lessThan(topOf('june')));
    });

    testWidgets('glance mode groups too', (final tester) async {
      await pumpSlivers(
        tester,
        build(sort: LibrarySort.recentlyFilmed, viewMode: ViewMode.glance),
      );

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('LAST MONTH'), findsOneWidget);
    });

    // Design D3 names both exclusions explicitly so an executor doesn't
    // "finish" the third mode for symmetry.
    testWidgets('study mode never groups', (final tester) async {
      await pumpSlivers(
        tester,
        build(sort: LibrarySort.recentlyAdded, viewMode: ViewMode.study),
      );

      expect(find.text('THIS MONTH'), findsNothing);
      expect(find.text('LAST MONTH'), findsNothing);
      expect(find.text('june'), findsOneWidget);
    });

    testWidgets('A–Z never groups, in any view mode', (final tester) async {
      for (final mode in [ViewMode.scan, ViewMode.glance]) {
        await pumpSlivers(
          tester,
          build(sort: LibrarySort.alphabetical, viewMode: mode),
        );

        expect(find.text('THIS MONTH'), findsNothing);
        expect(find.text('LAST MONTH'), findsNothing);
        expect(find.text('july-late'), findsOneWidget);
      }
    });

    testWidgets('headers disappear when the sort leaves the date dimension', (
      final tester,
    ) async {
      await pumpSlivers(
        tester,
        build(sort: LibrarySort.recentlyAdded, viewMode: ViewMode.scan),
      );
      expect(find.text('THIS MONTH'), findsOneWidget);

      await pumpSlivers(
        tester,
        build(sort: LibrarySort.alphabetical, viewMode: ViewMode.scan),
      );
      expect(find.text('THIS MONTH'), findsNothing);
    });
  });
}
