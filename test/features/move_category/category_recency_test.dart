import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakdex/core/data/repositories.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/move_category/move_category_screen.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// What 4.2 wires up: the category grid orders by most-recent activity, each
/// tile discloses the date it was ordered by, and a category nobody has filed
/// anything under sorts last while still being visible — the grid is how you
/// find a category to file into.
///
/// The ordering itself is proven in test/core/models/library_category_activity_test.dart;
/// what is under test here is the junction — that the screen reaches for the
/// aggregate's date rather than rendering the stored category order.
///
/// `moveRepositoryProvider` is stubbed rather than backed by Drift: a live
/// `watchAll()` query stream leaves a pending timer at teardown, the flake class
/// documented in docs/stale-tests-post-redesign.md.
class _StubMoveRepository implements MoveRepository {
  _StubMoveRepository(this.moves);

  final List<Move> moves;

  @override
  Stream<List<Move>> watchAll() => Stream.value(moves);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

void main() {
  late SharedPreferences prefs;

  // Anchored to the wall clock, not pinned to literals: the screen does not
  // inject `now`, so a fixed date would decay into a different arm of the
  // formatter the day after this was written.
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  final today = midnight.add(const Duration(hours: 9));
  final yesterday = midnight.subtract(const Duration(hours: 2));
  final daysAgo = midnight.subtract(const Duration(days: 4));

  Move move({
    required final String id,
    required final String category,
    required final DateTime createdAt,
  }) =>
      Move(
        id: id,
        name: 'move $id',
        category: category,
        learningState: 'NEW',
        count: 0,
        createdAt: createdAt,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Consumes the AppBar's known overflow so it cannot mask this file's
  /// assertions, and rethrows anything else.
  ///
  /// The custom `leading` — a chevron plus the word "Back" — does not fit the
  /// toolbar's fixed 56px leading slot. That predates 4.2 (verified by pumping
  /// this screen with the change stashed: same three overflows) and belongs to
  /// neither this task nor this file. It is drained by shape rather than
  /// swallowed wholesale, so any *other* exception still fails the test.
  void drainKnownOverflow(final WidgetTester tester) {
    for (var caught = tester.takeException();
        caught != null;
        caught = tester.takeException()) {
      if (!caught.toString().contains('A RenderFlex overflowed')) {
        fail('Unexpected exception while pumping the category grid: $caught');
      }
    }
  }

  Future<void> pumpCategories(
    final WidgetTester tester, {
    required final List<Move> moves,
  }) async {
    // Stored in an order that is deliberately NOT the recency order, so the
    // screen rendering the persisted sequence fails instead of coincidentally
    // agreeing.
    await prefs.setString(
      'categories',
      jsonEncode(
        const [
          Category(name: 'Toprock', colorValue: 0xFF42BE65),
          Category(name: 'Freezes', colorValue: 0xFF8A3FFC),
          Category(name: 'Power', colorValue: 0xFFDA1E28),
        ].map((final c) => c.toJson()).toList(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          moveRepositoryProvider.overrideWithValue(_StubMoveRepository(moves)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MoveCategoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    drainKnownOverflow(tester);
  }

  /// The category names as the grid actually stacks them, top to bottom.
  List<String> renderedOrder(final WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((final t) => t.data)
      .whereType<String>()
      .where(
        (final s) => const {
          'Toprock',
          'Freezes',
          'Power',
        }.contains(s),
      )
      .toList();

  testWidgets('categories order most-recently-added-to first', (tester) async {
    await pumpCategories(
      tester,
      moves: [
        move(id: 'a', category: 'Toprock', createdAt: daysAgo),
        move(id: 'b', category: 'Freezes', createdAt: today),
        move(id: 'c', category: 'Power', createdAt: yesterday),
      ],
    );

    expect(renderedOrder(tester), ['Freezes', 'Power', 'Toprock']);
  });

  testWidgets('each tile discloses the date it was ordered by', (tester) async {
    await pumpCategories(
      tester,
      moves: [
        move(id: 'a', category: 'Toprock', createdAt: daysAgo),
        move(id: 'b', category: 'Freezes', createdAt: today),
        move(id: 'c', category: 'Power', createdAt: yesterday),
      ],
    );

    final lines = tester
        .widgetList<LibraryDateLabel>(find.byType(LibraryDateLabel))
        .map((final l) => l.date)
        .toList();

    expect(lines, [today, yesterday, daysAgo]);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('4 days ago'), findsOneWidget);
  });

  testWidgets('an empty category sorts last and says so, never hidden',
      (tester) async {
    await pumpCategories(
      tester,
      moves: [
        move(id: 'b', category: 'Freezes', createdAt: today),
        move(id: 'c', category: 'Power', createdAt: yesterday),
      ],
    );

    // Toprock holds nothing: still on screen, and at the bottom.
    expect(renderedOrder(tester), ['Freezes', 'Power', 'Toprock']);
    // Uncategorized is empty too, so the copy appears on both tiles.
    expect(find.text('Nothing here yet'), findsNWidgets(2));
  });
}
