import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real import from the field: the camera gave no name, so the pipeline
/// stored the asset UUID. This is what the category row used to subtitle with.
const _uuidName = '3f2a9c14-77b1-4e0d-9a55-0c6b8d21e4af.mov';

Move _move({
  required final DateTime createdAt,
  final DateTime? videoCreationDate,
  final DateTime? updatedAt,
}) => Move(
  id: '1',
  name: 'Windmill',
  category: 'default',
  count: 0,
  learningState: 'new',
  createdAt: createdAt,
  videoCreationDate: videoCreationDate,
  updatedAt: updatedAt,
  originalVideoName: _uuidName,
);

/// Pumps the subtitle exactly as `_MoveRow` composes it. The row itself is
/// private to the category screen, and pumping that screen would boot live
/// Drift streams (the documented widget-test flake class), so this covers the
/// composition — date and caption both resolved from the same move and sort —
/// rather than the screen's layout around it.
Future<void> _pumpSubtitle(
  final WidgetTester tester,
  final Move move,
  final LibrarySort sort, {
  required final DateTime now,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: LibraryDateLabel(
        date: move.effectiveDate(sort),
        source: move.effectiveDateSource(sort),
        now: now,
      ),
    ),
  ),
);

void main() {
  final now = DateTime(2026, 1, 10);

  testWidgets('a UUID-named move subtitles with a date, never the UUID', (
    final tester,
  ) async {
    await _pumpSubtitle(
      tester,
      _move(createdAt: DateTime(2026, 1, 7)),
      LibrarySort.recentlyAdded,
      now: now,
    );

    expect(find.text('Added 3 days ago'), findsOneWidget);
    expect(find.textContaining(_uuidName), findsNothing);
    expect(find.textContaining('3f2a9c14'), findsNothing);
  });

  testWidgets('a filmed date is captioned "Filmed"', (final tester) async {
    await _pumpSubtitle(
      tester,
      _move(
        createdAt: DateTime(2026, 1, 7),
        videoCreationDate: DateTime(2026, 1, 9),
      ),
      LibrarySort.recentlyFilmed,
      now: now,
    );

    expect(find.text('Filmed Yesterday'), findsOneWidget);
  });

  testWidgets('an unfilmed move under the filmed sort says Added, not Filmed', (
    final tester,
  ) async {
    // The caption tracks the resolved source. Saying "Filmed" here would
    // replace one dishonest subtitle with another.
    await _pumpSubtitle(
      tester,
      _move(createdAt: DateTime(2026, 1, 10)),
      LibrarySort.recentlyFilmed,
      now: now,
    );

    expect(find.text('Added Today'), findsOneWidget);
    expect(find.textContaining('Filmed'), findsNothing);
  });

  testWidgets('an unpracticed move under the practiced sort says Added', (
    final tester,
  ) async {
    await _pumpSubtitle(
      tester,
      _move(createdAt: DateTime(2026, 1, 9)),
      LibrarySort.recentlyPracticed,
      now: now,
    );

    expect(find.text('Added Yesterday'), findsOneWidget);
    expect(find.textContaining('Practiced'), findsNothing);
  });

  testWidgets('an uncaptioned label still renders the bare date', (
    final tester,
  ) async {
    // Tiles pass no source; that path must keep working unchanged.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LibraryDateLabel(date: DateTime(2026, 1, 9), now: now),
        ),
      ),
    );

    expect(find.text('Yesterday'), findsOneWidget);
  });
}
