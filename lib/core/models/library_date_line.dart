/// How a row or tile spells out an item's date.
///
/// The recent past reads relatively because that is the tense a user thinks in;
/// everything else — including any date in the future, which a filmed date with
/// a wrong device clock can produce — reads absolutely. Same ruling, and the
/// same reason, as the month headers in `library_month_sections.dart`.
enum LibraryDateLineKind { today, yesterday, daysAgo, absolute }

/// A classified date line. [days] is the whole-day distance into the past and
/// is only meaningful for [LibraryDateLineKind.daysAgo].
typedef LibraryDateLineSpec = ({LibraryDateLineKind kind, int days});

/// First whole-day distance that reads absolutely (exclusive horizon).
const int libraryRelativeDateHorizonDays = 7;

/// Classifies [date] against [now] in **calendar days, local time**.
///
/// Calendar days, not elapsed hours: something filmed at 11pm is "yesterday" at
/// 1am, not "today", because that is the day the user remembers. Both instants
/// are normalized to local midnight and then compared as UTC day ordinals, so a
/// 23- or 25-hour day (DST) cannot shorten or stretch the count.
LibraryDateLineSpec libraryDateLine({
  required final DateTime date,
  required final DateTime now,
}) {
  final days = _dayKey(now).difference(_dayKey(date)).inDays;
  if (days < 0 || days >= libraryRelativeDateHorizonDays) {
    return (kind: LibraryDateLineKind.absolute, days: days);
  }
  return switch (days) {
    0 => (kind: LibraryDateLineKind.today, days: 0),
    1 => (kind: LibraryDateLineKind.yesterday, days: 1),
    _ => (kind: LibraryDateLineKind.daysAgo, days: days),
  };
}

/// The local calendar day of [t], as a DST-free ordinal.
DateTime _dayKey(final DateTime t) {
  final local = t.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}
