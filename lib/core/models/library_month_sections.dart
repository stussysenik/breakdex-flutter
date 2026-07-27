import 'package:breakdex/core/models/library_sort.dart';

/// A run of library items that share one calendar month.
///
/// [year] and [month] are read in **local time**, so a section header says the
/// month the user was living in when the thing happened, not the month UTC was
/// in. Items keep the order they arrived in.
class LibraryMonthSection<T> {
  const LibraryMonthSection({
    required this.year,
    required this.month,
    required this.items,
  });

  final int year;
  final int month;
  final List<T> items;
}

/// Splits an already-sorted list into contiguous calendar-month runs.
///
/// This is a **projection of the active sort, never a re-sort** (design D3): a
/// new section starts wherever the local month changes from the previous item,
/// so the caller's ordering survives byte-for-byte. Under a date sort the runs
/// are contiguous by construction; under any other ordering this still returns
/// every item exactly once, in place, which is why the decision to group at all
/// lives in [libraryGroupsByMonth] rather than here.
List<LibraryMonthSection<T>> libraryMonthSections<T>(
  final List<T> items,
  final DateTime Function(T item) dateOf,
) {
  final sections = <LibraryMonthSection<T>>[];
  for (final item in items) {
    final date = dateOf(item).toLocal();
    final open = sections.isEmpty ? null : sections.last;
    if (open != null && open.year == date.year && open.month == date.month) {
      open.items.add(item);
    } else {
      sections.add(
        LibraryMonthSection<T>(
          year: date.year,
          month: date.month,
          items: <T>[item],
        ),
      );
    }
  }
  return sections;
}

/// How a month header reads relative to [now] (design D3).
///
/// The near past gets a relative label because that is the tense a user thinks
/// in; everything else — including any month in the future, which a filmed date
/// with a wrong device clock can produce — gets an absolute one.
enum LibraryMonthLabel { thisMonth, lastMonth, absolute }

/// Classifies a calendar month against [now], both read in local time.
///
/// Compares month ordinals rather than dates so the year edge is not a special
/// case: December 2025 is "last month" in January 2026 for the same reason June
/// is in July.
LibraryMonthLabel libraryMonthLabel({
  required final int year,
  required final int month,
  required final DateTime now,
}) {
  final local = now.toLocal();
  final delta = (local.year * 12 + local.month) - (year * 12 + month);
  return switch (delta) {
    0 => LibraryMonthLabel.thisMonth,
    1 => LibraryMonthLabel.lastMonth,
    _ => LibraryMonthLabel.absolute,
  };
}

/// Whether the library groups its feed into month sections right now.
///
/// Grouping is a projection of a date ordering, so A–Z never groups — bucketing
/// an alphabetical list by month is noise (design D3).
bool libraryGroupsByMonth(final LibrarySort sort) => sort.isDateDimension;
