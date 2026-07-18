import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// Exercises the formatter through a real localized context — the classifier
/// itself is proven in test/core/models/library_date_line_test.dart, so what is
/// under test here is the wiring: which ARB key each arm reaches for, and that
/// the absolute arm renders a locale-formatted calendar date.
void main() {
  final now = DateTime(2026, 7, 18, 14, 30);

  Future<String> format(
    final WidgetTester tester,
    final DateTime date, {
    final Locale locale = const Locale('en'),
  }) async {
    late String result;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (final context) {
            result = formatLibraryDateLine(context, date, now: now);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('today reads as Today', (final tester) async {
    expect(await format(tester, DateTime(2026, 7, 18, 8)), 'Today');
  });

  testWidgets('the previous calendar day reads as Yesterday', (final tester) async {
    expect(await format(tester, DateTime(2026, 7, 17, 23, 50)), 'Yesterday');
  });

  testWidgets('the recent past counts days', (final tester) async {
    expect(await format(tester, DateTime(2026, 7, 15, 9)), '3 days ago');
  });

  testWidgets('the day before the horizon still counts days', (final tester) async {
    expect(await format(tester, DateTime(2026, 7, 12, 9)), '6 days ago');
  });

  testWidgets('past the horizon it names the date instead of counting', (
    final tester,
  ) async {
    final line = await format(tester, DateTime(2026, 7, 11, 9));
    expect(line, isNot(contains('ago')));
    expect(line, contains('2026'));
    expect(line, contains('11'));
  });

  testWidgets('a future date names its own date rather than reading as Today', (
    final tester,
  ) async {
    final line = await format(tester, DateTime(2026, 12, 25));
    expect(line, isNot('Today'));
    expect(line, contains('2026'));
    expect(line, contains('25'));
  });

  testWidgets('the absolute arm renders the local calendar day of a UTC instant', (
    final tester,
  ) async {
    // Drift hands back UTC for some columns; rendering the raw instant would
    // name the wrong day off UTC. Vacuous under TZ=UTC by construction.
    final local = DateTime(2025, 3, 9, 23, 30);
    expect(await format(tester, local.toUtc()), await format(tester, local));
  });
}
