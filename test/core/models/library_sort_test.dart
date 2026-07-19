import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(final int day) => DateTime(2026, 1, day);

Move _move({
  required final String id,
  required final String name,
  required final DateTime createdAt,
  final DateTime? videoCreationDate,
  final DateTime? updatedAt,
}) =>
    Move(
      id: id,
      name: name,
      category: 'default',
      count: 0,
      learningState: 'new',
      createdAt: createdAt,
      videoCreationDate: videoCreationDate,
      updatedAt: updatedAt,
    );

LibraryRow _combo({
  required final String id,
  required final String name,
  required final DateTime createdAt,
  final DateTime? updatedAt,
  final DateTime? lastEntryAt,
}) =>
    LibraryRow(
      combo: Combo(
        id: id,
        name: name,
        status: 'idea',
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
      transitionChain: '',
      moveCount: 0,
      jotCount: 0,
      lastEntryAt: lastEntryAt,
    );

void main() {
  group('LibrarySort', () {
    test('every sort but A–Z is a date dimension', () {
      expect(
        LibrarySort.values.where((final s) => s.isDateDimension).toSet(),
        {
          LibrarySort.recentlyAdded,
          LibrarySort.recentlyFilmed,
          LibrarySort.recentlyPracticed,
        },
      );
    });
  });

  group('Move.effectiveDate', () {
    final full = _move(
      id: 'm1',
      name: 'Windmill',
      createdAt: _at(1),
      videoCreationDate: _at(2),
      updatedAt: _at(3),
    );

    test('reads the field each dimension names', () {
      expect(full.effectiveDate(LibrarySort.recentlyAdded), _at(1));
      expect(full.effectiveDate(LibrarySort.recentlyFilmed), _at(2));
      expect(full.effectiveDate(LibrarySort.recentlyPracticed), _at(3));
    });

    test('A–Z stands in the added date so date display stays defined', () {
      expect(full.effectiveDate(LibrarySort.alphabetical), _at(1));
    });

    test('a legacy import with no capture date falls back to added', () {
      final legacy = _move(id: 'm2', name: 'Flare', createdAt: _at(5));
      expect(legacy.effectiveDate(LibrarySort.recentlyFilmed), _at(5));
      expect(legacy.effectiveDate(LibrarySort.recentlyPracticed), _at(5));
    });
  });

  group('LibraryRow.effectiveDate', () {
    test('practiced walks lastEntryAt → updatedAt → createdAt', () {
      expect(
        _combo(
          id: 'c1',
          name: 'A',
          createdAt: _at(1),
          updatedAt: _at(2),
          lastEntryAt: _at(3),
        ).effectiveDate(LibrarySort.recentlyPracticed),
        _at(3),
      );
      expect(
        _combo(id: 'c2', name: 'A', createdAt: _at(1), updatedAt: _at(2))
            .effectiveDate(LibrarySort.recentlyPracticed),
        _at(2),
      );
      expect(
        _combo(id: 'c3', name: 'A', createdAt: _at(1))
            .effectiveDate(LibrarySort.recentlyPracticed),
        _at(1),
      );
    });

    test('filmed reads the added date rather than inventing a capture date', () {
      final combo = _combo(id: 'c4', name: 'A', createdAt: _at(7));
      expect(combo.effectiveDate(LibrarySort.recentlyFilmed), _at(7));
    });
  });

  group('comparators', () {
    test('date sorts run newest first', () {
      final moves = [
        _move(id: 'a', name: 'Old', createdAt: _at(1)),
        _move(id: 'b', name: 'New', createdAt: _at(9)),
      ]..sort(moveLibraryComparator(LibrarySort.recentlyAdded));
      expect(moves.map((final m) => m.id), ['b', 'a']);
    });

    test('filmed sort orders by capture date, not import order', () {
      final moves = [
        _move(
          id: 'a',
          name: 'A',
          createdAt: _at(9),
          videoCreationDate: _at(1),
        ),
        _move(
          id: 'b',
          name: 'B',
          createdAt: _at(1),
          videoCreationDate: _at(9),
        ),
      ]..sort(moveLibraryComparator(LibrarySort.recentlyFilmed));
      expect(moves.map((final m) => m.id), ['b', 'a']);
    });

    test('equal dates break by name, then id — never arbitrary', () {
      final moves = [
        _move(id: 'z', name: 'Same', createdAt: _at(1)),
        _move(id: 'a', name: 'Same', createdAt: _at(1)),
        _move(id: 'm', name: 'Alpha', createdAt: _at(1)),
      ]..sort(moveLibraryComparator(LibrarySort.recentlyAdded));
      expect(moves.map((final m) => m.id), ['m', 'a', 'z']);
    });

    test('A–Z ignores dates and is case-insensitive', () {
      final moves = [
        _move(id: '1', name: 'zulu', createdAt: _at(9)),
        _move(id: '2', name: 'Alpha', createdAt: _at(1)),
        _move(id: '3', name: 'beta', createdAt: _at(5)),
      ]..sort(moveLibraryComparator(LibrarySort.alphabetical));
      expect(moves.map((final m) => m.name), ['Alpha', 'beta', 'zulu']);
    });

    test('combo comparator sorts by its own fallback chain', () {
      final combos = [
        _combo(id: 'c1', name: 'A', createdAt: _at(9)),
        _combo(id: 'c2', name: 'B', createdAt: _at(1), lastEntryAt: _at(20)),
      ]..sort(comboLibraryComparator(LibrarySort.recentlyPracticed));
      expect(combos.map((final r) => r.combo.id), ['c2', 'c1']);
    });
  });

  group('effectiveDateSource — the label may never outrun the data', () {
    test('a move names the dimension it actually resolved', () {
      final filmed = _move(
        id: '1',
        name: 'A',
        createdAt: _at(1),
        videoCreationDate: _at(5),
      );
      expect(
        filmed.effectiveDateSource(LibrarySort.recentlyFilmed),
        LibraryDateSource.filmed,
      );
      expect(
        filmed.effectiveDateSource(LibrarySort.recentlyAdded),
        LibraryDateSource.added,
      );
    });

    test('a fallback reports the source it fell back TO, not the one asked for',
        () {
      // The whole point: effectiveDate is total, so an unfilmed move still
      // sorts under "filmed" — by its createdAt. Labeling that date "Filmed"
      // would replace a UUID subtitle with a false one.
      final unfilmed = _move(id: '1', name: 'A', createdAt: _at(1));
      expect(unfilmed.effectiveDate(LibrarySort.recentlyFilmed), _at(1));
      expect(
        unfilmed.effectiveDateSource(LibrarySort.recentlyFilmed),
        LibraryDateSource.added,
      );

      final unpracticed = _move(id: '2', name: 'B', createdAt: _at(1));
      expect(
        unpracticed.effectiveDateSource(LibrarySort.recentlyPracticed),
        LibraryDateSource.added,
      );
    });

    test('A–Z labels the added date it stands in with', () {
      final move = _move(
        id: '1',
        name: 'A',
        createdAt: _at(1),
        videoCreationDate: _at(5),
      );
      expect(
        move.effectiveDateSource(LibrarySort.alphabetical),
        LibraryDateSource.added,
      );
    });

    test('a combo never claims a filmed date — it has no capture event', () {
      final combo = _combo(id: 'c1', name: 'A', createdAt: _at(1));
      expect(
        combo.effectiveDateSource(LibrarySort.recentlyFilmed),
        LibraryDateSource.added,
      );
      expect(
        _combo(id: 'c2', name: 'B', createdAt: _at(1), lastEntryAt: _at(20))
            .effectiveDateSource(LibrarySort.recentlyPracticed),
        LibraryDateSource.practiced,
      );
    });

    test('every source agrees with the date effectiveDate returned', () {
      for (final sort in LibrarySort.values) {
        for (final move in [
          _move(id: '1', name: 'A', createdAt: _at(1)),
          _move(id: '2', name: 'B', createdAt: _at(1), videoCreationDate: _at(5)),
          _move(id: '3', name: 'C', createdAt: _at(1), updatedAt: _at(9)),
        ]) {
          final date = move.effectiveDate(sort);
          final expected = switch (move.effectiveDateSource(sort)) {
            LibraryDateSource.added => move.createdAt,
            LibraryDateSource.filmed => move.videoCreationDate,
            LibraryDateSource.practiced => move.updatedAt,
          };
          expect(date, expected, reason: '$sort on move ${move.id}');
        }
      }
    });
  });
}
