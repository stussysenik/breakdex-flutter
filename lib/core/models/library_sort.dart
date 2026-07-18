import '../database/daos/combos_dao.dart';
import '../database/database.dart';

/// How the library is ordered. Three date dimensions plus A–Z (design D2).
///
/// Each date dimension resolves through an explicit fallback chain that always
/// terminates at `createdAt` (a non-nullable column), so [effectiveDate] is
/// total: no entity can ever fall out of the ordering for lack of a date.
enum LibrarySort {
  recentlyAdded,
  recentlyFilmed,
  recentlyPracticed,
  alphabetical;

  /// True when this sort orders by a date, i.e. everything but A–Z. Month
  /// grouping (design D3) is a projection of exactly these.
  bool get isDateDimension => this != LibrarySort.alphabetical;
}

/// Resolves the persisted `library_sort` value to a [LibrarySort].
///
/// Unlike `ViewMode`, this key has no legacy vocabulary to migrate — it ships
/// with one naming scheme. Tolerance here means an unknown or absent value
/// falls to [LibrarySort.recentlyAdded], today's behavior, so a preferences
/// row written by a future build can never strand an older one.
LibrarySort librarySortFromStored(final String? raw) =>
    LibrarySort.values.firstWhere(
      (final sort) => sort.name == raw,
      orElse: () => LibrarySort.recentlyAdded,
    );

extension MoveLibrarySort on Move {
  /// The date this move sorts by under [sort].
  ///
  /// A–Z has no date dimension; the added date stands in so surfaces that
  /// render "the date for the active sort" still have a defined answer.
  DateTime effectiveDate(final LibrarySort sort) => switch (sort) {
        LibrarySort.recentlyAdded || LibrarySort.alphabetical => createdAt,
        LibrarySort.recentlyFilmed => videoCreationDate ?? createdAt,
        LibrarySort.recentlyPracticed => updatedAt ?? createdAt,
      };
}

extension ComboLibrarySort on LibraryRow {
  /// The date this combo sorts by under [sort].
  ///
  /// A combo has no capture date, so "recently filmed" reads the added date
  /// rather than inventing one from member moves — the combo tab discloses the
  /// fallback instead of faking it (design D2).
  DateTime effectiveDate(final LibrarySort sort) => switch (sort) {
        LibrarySort.recentlyAdded ||
        LibrarySort.recentlyFilmed ||
        LibrarySort.alphabetical =>
          combo.createdAt,
        LibrarySort.recentlyPracticed =>
          lastEntryAt ?? combo.updatedAt ?? combo.createdAt,
      };
}

Comparator<Move> moveLibraryComparator(final LibrarySort sort) =>
    (final a, final b) => _compareKeys(
          sort,
          (name: a.name, date: a.effectiveDate(sort), id: a.id),
          (name: b.name, date: b.effectiveDate(sort), id: b.id),
        );

Comparator<LibraryRow> comboLibraryComparator(final LibrarySort sort) =>
    (final a, final b) => _compareKeys(
          sort,
          (name: a.combo.name, date: a.effectiveDate(sort), id: a.combo.id),
          (name: b.combo.name, date: b.effectiveDate(sort), id: b.combo.id),
        );

typedef _SortKey = ({String name, DateTime date, String id});

/// Date sorts run newest-first; A–Z runs name-first. Both break ties by name
/// then id, so equal dates (and duplicate names) still order deterministically.
int _compareKeys(final LibrarySort sort, final _SortKey a, final _SortKey b) {
  if (sort.isDateDimension) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
  }
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}
