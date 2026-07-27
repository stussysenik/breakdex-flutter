import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/library_date_line.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';

/// The one localized date line the library shows on rows and tiles.
///
/// Every surface that discloses an item's date goes through here — a move row,
/// a move tile, a combo row, a combo tile — so "3 days ago" cannot come out
/// four subtly different ways, and so a new locale changes one call site.
///
/// [date] is the item's effective date for the **active** sort; resolving which
/// dimension that is belongs to the caller, not here. [now] is injectable so a
/// test can pin the relative/absolute boundary instead of racing the wall clock.
String formatLibraryDateLine(
  final BuildContext context,
  final DateTime date, {
  final DateTime? now,
}) {
  final l10n = AppLocalizations.of(context);
  final spec = libraryDateLine(date: date, now: now ?? DateTime.now());
  return switch (spec.kind) {
    LibraryDateLineKind.today => l10n.libraryDateToday,
    LibraryDateLineKind.yesterday => l10n.libraryDateYesterday,
    LibraryDateLineKind.daysAgo => l10n.libraryDateDaysAgo(spec.days),
    // Absolute reads in the user's locale and in their calendar day, so a UTC
    // instant is not rendered a day off west of UTC.
    LibraryDateLineKind.absolute => DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date.toLocal()),
  };
}

/// [formatLibraryDateLine] captioned with the dimension the date came from.
///
/// [source] is the resolved source, not the active sort — see
/// [LibraryDateSource]. Passing the sort's dimension instead would caption an
/// unfilmed move's added date "Filmed", which is the failure this exists to
/// prevent.
String formatLibraryDateLineWithSource(
  final BuildContext context,
  final DateTime date,
  final LibraryDateSource source, {
  final DateTime? now,
}) {
  final l10n = AppLocalizations.of(context);
  final formatted = formatLibraryDateLine(context, date, now: now);
  return switch (source) {
    LibraryDateSource.added => l10n.libraryDateAdded(formatted),
    LibraryDateSource.filmed => l10n.libraryDateFilmed(formatted),
    LibraryDateSource.practiced => l10n.libraryDatePracticed(formatted),
  };
}

/// The date line as the library actually renders it, on rows and on tiles.
///
/// One widget rather than four copies of "caption, secondary, one line": the
/// surfaces differ only in the color they can afford — a row sits on `surface`
/// and defers to the theme, a grid tile sits on a video thumbnail and has to
/// pass a light [color] to stay legible.
class LibraryDateLabel extends StatelessWidget {
  const LibraryDateLabel({
    super.key,
    required this.date,
    this.source,
    this.color,
    this.now,
  });

  /// The item's effective date for the **active** sort. Which dimension that
  /// is belongs to the caller — this widget renders whatever it is handed.
  final DateTime date;

  /// When set, captions the date with the dimension it came from ("Added 3
  /// days ago"). Tiles that sit under a name in a dense grid leave this null
  /// and show the bare date; a row that replaced a filename subtitle sets it,
  /// because there the date has to explain itself.
  final LibraryDateSource? source;

  /// Overrides the default `onSurface`-secondary color for tiles that render
  /// over imagery.
  final Color? color;

  /// Injectable clock, so a test can pin the relative/absolute boundary.
  final DateTime? now;

  @override
  Widget build(final BuildContext context) => Text(
    source == null
        ? formatLibraryDateLine(context, date, now: now)
        : formatLibraryDateLineWithSource(context, date, source!, now: now),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.caption.copyWith(
      color: color ?? Theme.of(context).colorScheme.secondary,
    ),
  );
}
