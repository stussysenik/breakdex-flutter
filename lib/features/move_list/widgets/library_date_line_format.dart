import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/models/library_date_line.dart';
import '../../../l10n/gen/app_localizations.dart';

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
