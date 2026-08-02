import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_category_activity.dart';
import 'package:flutter_test/flutter_test.dart';

Move _move({
  required final String id,
  required final String category,
  required final DateTime createdAt,
  final String? videoPath,
}) =>
    Move(
      id: id,
      name: 'move $id',
      category: category,
      count: 0,
      learningState: 'new',
      createdAt: createdAt,
      videoPath: videoPath,
    );

void main() {
  final jan = DateTime(2026, 1, 10);
  final jun = DateTime(2026, 6, 4);
  final dec = DateTime(2026, 12, 24);

  group('libraryCategoryActivities', () {
    test('counts each category and dates it by its newest move', () {
      final result = libraryCategoryActivities(
        moves: [
          _move(id: 'a', category: 'Power', createdAt: jan),
          _move(id: 'b', category: 'Power', createdAt: dec),
          _move(id: 'c', category: 'Power', createdAt: jun),
          _move(id: 'd', category: 'Footwork', createdAt: jun),
        ],
        categoryNames: {'Power', 'Footwork'},
      );

      expect(result.byCategory['Power']!.count, 3);
      // Newest wins regardless of arrival order — the max is not "the last one seen".
      expect(result.byCategory['Power']!.lastAddedAt, dec);
      expect(result.byCategory['Footwork']!.count, 1);
      expect(result.byCategory['Footwork']!.lastAddedAt, jun);
    });

    test('an empty category is present with a null date, not absent', () {
      final result = libraryCategoryActivities(
        moves: [_move(id: 'a', category: 'Power', createdAt: jan)],
        categoryNames: {'Power', 'Freezes'},
      );

      expect(result.byCategory.keys, containsAll(<String>['Power', 'Freezes']));
      expect(result.byCategory['Freezes'], LibraryCategoryActivity.empty);
      expect(result.byCategory['Freezes']!.lastAddedAt, isNull);
    });

    test('moves under an unknown category fall to uncategorized', () {
      final result = libraryCategoryActivities(
        moves: [
          _move(id: 'a', category: 'Power', createdAt: jan),
          _move(id: 'b', category: 'deleted-category', createdAt: jun),
          _move(id: 'c', category: '', createdAt: dec),
        ],
        categoryNames: {'Power'},
      );

      expect(result.uncategorized.count, 2);
      expect(result.uncategorized.lastAddedAt, dec);
      expect(result.byCategory.containsKey('deleted-category'), isFalse);
    });

    test('no moves at all leaves every bucket empty', () {
      final result = libraryCategoryActivities(
        moves: const [],
        categoryNames: {'Power'},
      );

      expect(result.byCategory['Power'], LibraryCategoryActivity.empty);
      expect(result.uncategorized, LibraryCategoryActivity.empty);
    });
  });

  group('categoryNamesByRecency', () {
    LibraryCategoryActivity dated(final DateTime? at) =>
        LibraryCategoryActivity(count: at == null ? 0 : 1, lastAddedAt: at);

    test('orders most-recently-added-to first', () {
      final ordered = categoryNamesByRecency(
        orderedNames: const ['Power', 'Freezes', 'Toprock'],
        byCategory: {
          'Power': dated(jan),
          'Freezes': dated(dec),
          'Toprock': dated(jun),
        },
      );

      expect(ordered, ['Freezes', 'Toprock', 'Power']);
    });

    test('empty categories sort last but are never dropped', () {
      final ordered = categoryNamesByRecency(
        orderedNames: const ['Empty', 'Power', 'AlsoEmpty'],
        byCategory: {
          'Empty': LibraryCategoryActivity.empty,
          'Power': dated(jan),
          'AlsoEmpty': LibraryCategoryActivity.empty,
        },
      );

      expect(ordered, ['Power', 'Empty', 'AlsoEmpty']);
      expect(ordered.length, 3);
    });

    // Wide enough to leave Dart's small-list insertion sort — which is stable by
    // accident — and reach the unstable path, so dropping the index tiebreak
    // actually shuffles these instead of passing by luck.
    final wide = [for (var i = 0; i < 40; i++) 'cat-$i'];

    test('equal dates keep the incoming order', () {
      final ordered = categoryNamesByRecency(
        orderedNames: wide,
        byCategory: {for (final name in wide) name: dated(jun)},
      );

      expect(ordered, wide);
    });

    test('the empty tail keeps the incoming order', () {
      final ordered = categoryNamesByRecency(
        orderedNames: wide,
        byCategory: {
          for (final name in wide) name: LibraryCategoryActivity.empty,
        },
      );

      expect(ordered, wide);
    });

    test('a name with no activity entry at all sorts last, not thrown away', () {
      final ordered = categoryNamesByRecency(
        orderedNames: const ['Ghost', 'Power'],
        byCategory: {'Power': dated(jan)},
      );

      expect(ordered, ['Power', 'Ghost']);
    });
  });

  // Task 8.3 — the tile introduces a category with its moves' faces.
  group('category preview moves', () {
    test('takes the newest filmed moves, skipping the unfilmed', () {
      final result = libraryCategoryActivities(
        moves: [
          _move(id: 'a', category: 'Power', createdAt: jan, videoPath: 'a.mp4'),
          _move(id: 'b', category: 'Power', createdAt: dec, videoPath: 'b.mp4'),
          // No footage: counted, never previewed as a hole.
          _move(id: 'c', category: 'Power', createdAt: jun),
        ],
        categoryNames: {'Power'},
      );

      final power = result.byCategory['Power']!;
      expect(power.count, 3);
      expect([for (final m in power.previewMoves) m.id], ['b', 'a']);
    });

    test('caps the strip and keeps the newest, not the first seen', () {
      final result = libraryCategoryActivities(
        moves: [
          for (var day = 1; day <= 6; day++)
            _move(
              id: 'm$day',
              category: 'Power',
              createdAt: DateTime(2026, 3, day),
              videoPath: 'm$day.mp4',
            ),
        ],
        categoryNames: {'Power'},
      );

      final power = result.byCategory['Power']!;
      expect(power.count, 6);
      expect(
        power.previewMoves.length,
        LibraryCategoryActivity.maxPreviewMoves,
      );
      expect([for (final m in power.previewMoves) m.id], [
        'm6',
        'm5',
        'm4',
        'm3',
      ]);
    });

    test('same-instant moves order by id, so a rebuild cannot reshuffle', () {
      final result = libraryCategoryActivities(
        moves: [
          _move(id: 'z', category: 'Power', createdAt: jun, videoPath: 'z.mp4'),
          _move(id: 'a', category: 'Power', createdAt: jun, videoPath: 'a.mp4'),
        ],
        categoryNames: {'Power'},
      );

      expect([for (final m in result.byCategory['Power']!.previewMoves) m.id], [
        'a',
        'z',
      ]);
    });

    test('an unfilmed category previews nothing but still counts', () {
      final result = libraryCategoryActivities(
        moves: [_move(id: 'a', category: 'Power', createdAt: jan)],
        categoryNames: {'Power'},
      );

      expect(result.byCategory['Power']!.count, 1);
      expect(result.byCategory['Power']!.previewMoves, isEmpty);
    });

    test('uncategorized gets a strip too', () {
      final result = libraryCategoryActivities(
        moves: [
          _move(id: 'a', category: 'Ghost', createdAt: jan, videoPath: 'a.mp4'),
        ],
        categoryNames: {'Power'},
      );

      expect([for (final m in result.uncategorized.previewMoves) m.id], ['a']);
    });
  });
}
