import 'package:flutter/material.dart';

import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/core/models/move_detail_caption.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';

/// The one caption under a move's name on the move detail screen.
///
/// Dumb by construction — the selected [MoveDetailCaption] is resolved by the
/// caller and handed in, so this renders a [MoveDetailCaptionSpec] and nothing
/// else. A date goes through the shared `LibraryDateLabel` so the detail screen
/// cannot drift from how the library words the same date; an identifier keeps
/// the monospace face it has always had, because it *is* machine text.
class MoveDetailCaptionLine extends StatelessWidget {
  const MoveDetailCaptionLine({super.key, required this.spec, this.now});

  final MoveDetailCaptionSpec spec;

  /// Injectable clock, forwarded to the shared date label so a test can pin the
  /// relative/absolute boundary.
  final DateTime? now;

  @override
  Widget build(final BuildContext context) => switch (spec) {
    MoveDetailCaptionNone() => const SizedBox.shrink(),
    MoveDetailCaptionDate(:final value) => LibraryDateLabel(
      date: value,
      source: LibraryDateSource.added,
      now: now,
    ),
    MoveDetailCaptionText(:final value) => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: Theme.of(context).colorScheme.secondary,
        fontFamily: 'monospace',
      ),
    ),
  };
}
