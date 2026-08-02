import 'package:flutter/material.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/shared/widgets/video_thumbnail_image.dart';

/// A parent introduces itself with its children's faces: up to
/// [maxThumbnails] first frames, then how many more are inside.
///
/// It renders children, never a new container type — a combo passes the video
/// paths of its moves and a category passes the video paths of the moves filed
/// under it, so the atom model (move → combo → set) is what is on screen and
/// the strip is only how it is drawn.
///
/// [totalCount] is the parent's real size, not `videoPaths.length`: a combo of
/// nine moves where only two have footage still says `+7`, because the
/// overflow answers "how much is in here", not "how much did we manage to
/// decode".
class ChildPreviewStrip extends StatelessWidget {
  const ChildPreviewStrip({
    super.key,
    required this.videoPaths,
    required this.totalCount,
    this.maxThumbnails = 4,
  });

  final List<String> videoPaths;
  final int totalCount;
  final int maxThumbnails;

  /// 4pt-grid landscape, so a strip reads as video rather than as avatars.
  static const thumbnailWidth = 40.0;
  static const thumbnailHeight = 28.0;

  @override
  Widget build(final BuildContext context) {
    // Nothing to introduce: an empty parent, or one whose children have no
    // footage yet. The caller keeps whatever count affordance it already had
    // rather than being handed an empty box to lay out around.
    if (videoPaths.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final shown = videoPaths.take(maxThumbnails).toList();
    final remaining = totalCount - shown.length;

    // Decorative: the row that owns this strip already says the count in its
    // semantics label, and four unlabelled thumbnails would only repeat it.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, path) in shown.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: thumbnailWidth,
                height: thumbnailHeight,
                child: VideoThumbnailImage(
                  videoPath: path,
                  maxWidth: VideoService.thumbnailWidthGrid,
                  missingIconSize: 14,
                ),
              ),
            ),
          ],
          if (remaining > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '+$remaining',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
