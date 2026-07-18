import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_category_activity.dart';
import 'package:flutter_test/flutter_test.dart';

Move _move({
  required final String id,
  required final String category,
  required final DateTime createdAt,
}) =>
    Move(
      id: id,
      name: 'move $id',
      category: category,
      count: 0,
      learningState: 'new',
      createdAt: createdAt,
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
}
