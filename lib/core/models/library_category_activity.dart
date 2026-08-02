import 'package:breakdex/core/database/database.dart';

/// What a category tile knows about itself: how many moves it holds and when it
/// was most recently added to (design D5).
class LibraryCategoryActivity {
  const LibraryCategoryActivity({
    required this.count,
    required this.lastAddedAt,
    this.previewMoves = const <Move>[],
  });

  static const empty = LibraryCategoryActivity(count: 0, lastAddedAt: null);

  /// How many faces a category tile introduces itself with (task 8.3).
  static const maxPreviewMoves = 4;

  final int count;

  /// The newest `createdAt` among this category's moves — "most recently added
  /// to", per the spec. Null only when the category holds nothing, which is the
  /// state 4.2 sorts last rather than hides.
  final DateTime? lastAddedAt;

  /// Up to [maxPreviewMoves] of this category's moves that actually have
  /// footage, newest first — the representative strip a tile shows before you
  /// open it (task 8.3).
  ///
  /// Newest-first because the tile is already ordered by "most recently added
  /// to": the strip then shows the same moves the date line is talking about.
  /// A move with no `videoPath` is skipped rather than drawn as a hole, so a
  /// category of nine where two are filmed previews those two and still counts
  /// nine.
  final List<Move> previewMoves;

  LibraryCategoryActivity _withMove(final Move move) => LibraryCategoryActivity(
        count: count + 1,
        lastAddedAt: lastAddedAt == null || move.createdAt.isAfter(lastAddedAt!)
            ? move.createdAt
            : lastAddedAt,
        previewMoves: _previewWith(move),
      );

  /// Insert [move] into the newest-first preview list, capped at
  /// [maxPreviewMoves]. Ties break on `id` so two moves added in the same
  /// second cannot swap places between rebuilds — the same stability the
  /// recency sort needed.
  List<Move> _previewWith(final Move move) {
    if (move.videoPath == null) return previewMoves;
    final next = [...previewMoves, move]..sort((final a, final b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return next.length > maxPreviewMoves
        ? next.sublist(0, maxPreviewMoves)
        : next;
  }

  @override
  bool operator ==(final Object other) =>
      other is LibraryCategoryActivity &&
      other.count == count &&
      other.lastAddedAt == lastAddedAt &&
      _sameIds(other.previewMoves, previewMoves);

  static bool _sameIds(final List<Move> a, final List<Move> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        count,
        lastAddedAt,
        Object.hashAll([for (final m in previewMoves) m.id]),
      );

  @override
  String toString() =>
      'LibraryCategoryActivity(count: $count, lastAddedAt: $lastAddedAt, '
      'previewMoves: ${previewMoves.length})';
}

typedef LibraryCategoryActivities = ({
  Map<String, LibraryCategoryActivity> byCategory,
  LibraryCategoryActivity uncategorized,
});

/// Counts and dates every category in one pass over [moves] — the same walk
/// that already produced the counts, with a `max` alongside (design D5): no new
/// query, no new column.
///
/// Every name in [categoryNames] appears in the result, so a category nobody
/// has filed a move under is [LibraryCategoryActivity.empty] rather than absent.
/// A move whose category is not a known name falls to `uncategorized`, matching
/// how the screen already routes it.
LibraryCategoryActivities libraryCategoryActivities({
  required final Iterable<Move> moves,
  required final Set<String> categoryNames,
}) {
  final byCategory = <String, LibraryCategoryActivity>{
    for (final name in categoryNames) name: LibraryCategoryActivity.empty,
  };
  var uncategorized = LibraryCategoryActivity.empty;

  for (final move in moves) {
    final known = byCategory[move.category];
    if (known != null) {
      byCategory[move.category] = known._withMove(move);
    } else {
      uncategorized = uncategorized._withMove(move);
    }
  }

  return (byCategory: byCategory, uncategorized: uncategorized);
}

/// [orderedNames] re-ordered most-recently-added-to first.
///
/// A category nobody has filed anything under has no date, and sorts **last**
/// rather than disappearing — the grid is how you find a category to file into,
/// so hiding the empty ones would hide exactly the ones you are looking for.
///
/// Ties and the empty tail fall back to the incoming order, which is the order
/// the user created their categories in. That fallback is load-bearing rather
/// than cosmetic: `List.sort` is not stable in Dart, so without an explicit
/// tiebreak two categories last added to on the same instant — or every empty
/// category — could swap places on any rebuild.
List<String> categoryNamesByRecency({
  required final List<String> orderedNames,
  required final Map<String, LibraryCategoryActivity> byCategory,
}) {
  final indexed = orderedNames.indexed.toList()
    ..sort((final a, final b) {
      final aDate = byCategory[a.$2]?.lastAddedAt;
      final bDate = byCategory[b.$2]?.lastAddedAt;
      if (aDate == null || bDate == null) {
        if (aDate != null) return -1;
        if (bDate != null) return 1;
        return a.$1.compareTo(b.$1);
      }
      final byDate = bDate.compareTo(aDate);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
  return [for (final (_, name) in indexed) name];
}
