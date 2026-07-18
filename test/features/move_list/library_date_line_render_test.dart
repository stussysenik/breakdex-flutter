import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// What 3.2 wires up: every library surface discloses a date, and the date it
/// discloses is the one the **active sort** ordered by. The formatter itself is
/// proven in library_date_line_format_test.dart; what is under test here is the
/// junction — that each surface reaches for `effectiveDate(sort)` and not for
/// whichever date happened to be nearest to hand.
///
/// The screen's Drift streams are replaced wholesale by overriding
/// `libraryMovesProvider`/`libraryCombosProvider` (both plain `Provider`s over
/// `AsyncValue`), so no live stream is pumped and none of the flake documented
/// in docs/stale-tests-post-redesign.md applies.
/// The combo grid cell subscribes to `watchComboMoves` for its preview. Backed
/// by Drift that is a live query stream, whose teardown leaves a pending timer
/// and flakes the test; the date line under assertion does not depend on it, so
/// the stream is stubbed empty rather than the surface left unasserted.
class _StubComboRepository implements ComboRepository {
  @override
  Stream<List<ComboMoveWithDetail>> watchComboMoves(final String comboId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

void main() {
  late SharedPreferences prefs;

  // Three distinct dates, so a surface reading the wrong dimension names a
  // visibly wrong day rather than coincidentally the right one. They are
  // anchored to the wall clock rather than pinned to literals: the production
  // call sites do not inject `now`, so a fixed date would decay into a
  // different arm of the formatter the day after it was written.
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  final created = midnight.add(const Duration(hours: 9));
  // 10pm the previous calendar day — "Yesterday" only under calendar-day
  // arithmetic, which is the ruling 3.1 pinned.
  final filmed = midnight.subtract(const Duration(hours: 2));
  final practiced = midnight.subtract(const Duration(days: 4)).add(
        const Duration(hours: 12),
      );

  final move = Move(
    id: 'move-1',
    name: 'Six Step',
    category: 'default',
    learningState: 'learning',
    count: 0,
    createdAt: created,
    videoCreationDate: filmed,
    updatedAt: practiced,
  );

  final comboRow = LibraryRow(
    combo: Combo(
      id: 'combo-1',
      name: 'Opening Round',
      status: 'active',
      createdAt: created,
      updatedAt: practiced,
    ),
    transitionChain: '',
    moveCount: 3,
    jotCount: 0,
    lastEntryAt: practiced,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpLibrary(
    final WidgetTester tester, {
    required final LibrarySort sort,
    required final ViewMode viewMode,
    required final bool combosTab,
  }) async {
    await prefs.setString('library_sort', sort.name);
    await prefs.setString('arsenal_view_mode', viewMode.name);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // The screen's auth header otherwise reaches for a real Appwrite
          // session, leaving a live network timer pending at teardown.
          currentAppwriteUserProvider.overrideWith(
            (final ref) => const Stream<AuthUser?>.empty(),
          ),
          comboRepositoryProvider.overrideWithValue(_StubComboRepository()),
          libraryMovesProvider.overrideWithValue(
            AsyncValue.data(combosTab ? const <Move>[] : [move]),
          ),
          libraryCombosProvider.overrideWithValue(
            AsyncValue.data(combosTab ? [comboRow] : const <LibraryRow>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MoveListScreen(),
        ),
      ),
    );
    await tester.pump();

    // The segment provider is private, so the combo tab is reached the way a
    // user reaches it — by tapping the control.
    if (combosTab) {
      await tester.tap(find.text('Combos'));
      await tester.pump();
    }

    // flutter_animate stagger: settle the entry animations so the frame under
    // assertion is the finished one, not a mid-fade scaffold.
    await tester.pumpAndSettle();
  }

  /// The date line rendered anywhere in the tree, as text.
  List<String> dateLines(final WidgetTester tester) => tester
      .widgetList<LibraryDateLabel>(find.byType(LibraryDateLabel))
      .map(
        (final label) => (tester.widget<Text>(
          find.descendant(
            of: find.byWidget(label),
            matching: find.byType(Text),
          ),
        )).data!,
      )
      .toList();

  group('move surfaces', () {
    for (final viewMode in [ViewMode.scan, ViewMode.glance]) {
      testWidgets('$viewMode shows the added date under Added', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyAdded,
          viewMode: viewMode,
          combosTab: false,
        );

        expect(dateLines(tester), isNotEmpty);
        expect(dateLines(tester).first, 'Today');
      });

      testWidgets('$viewMode follows the sort to the filmed date', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyFilmed,
          viewMode: viewMode,
          combosTab: false,
        );

        // Filmed at 10pm the previous calendar day — the surface must not
        // fall back to the added date, which reads "Today".
        expect(dateLines(tester).first, 'Yesterday');
      });

      testWidgets('$viewMode follows the sort to the practiced date', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyPracticed,
          viewMode: viewMode,
          combosTab: false,
        );

        expect(dateLines(tester).first, '4 days ago');
      });
    }
  });

  group('combo surfaces', () {
    for (final viewMode in [ViewMode.scan, ViewMode.glance]) {
      testWidgets('$viewMode shows the added date under Added', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyAdded,
          viewMode: viewMode,
          combosTab: true,
        );

        expect(dateLines(tester), isNotEmpty);
        expect(dateLines(tester).first, 'Today');
      });

      // The one combo date the sliver boundary could lose: `lastEntryAt` lives
      // on the LibraryRow, not on the Combo, so a surface that resolves from
      // the sort alone downstream would silently show `updatedAt` instead.
      testWidgets('$viewMode shows the last-entry date under Practiced', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyPracticed,
          viewMode: viewMode,
          combosTab: true,
        );

        expect(dateLines(tester).first, '4 days ago');
      });

      // A combo has no capture date; "filmed" resolves to the added date
      // rather than inventing one (design D2, same ruling 2.3 disclosed).
      testWidgets('$viewMode falls back to the added date under Filmed', (
        final tester,
      ) async {
        await pumpLibrary(
          tester,
          sort: LibrarySort.recentlyFilmed,
          viewMode: viewMode,
          combosTab: true,
        );

        expect(dateLines(tester).first, 'Today');
      });
    }
  });
}
