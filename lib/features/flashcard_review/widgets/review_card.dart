import 'package:flutter/material.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../shared/widgets/state_pill.dart';
import '../../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

/// 60/30/10 review card — video dominates, metadata is compact.
///
/// - 60% video: edge-to-edge, immersive
/// - 30% context band: move name + category + state pill
/// - 10% is reserved for the rating buttons (outside this widget)
///
/// [videoHeight] is computed by the parent via LayoutBuilder to represent
/// true 60% of the *available* viewport (after SafeArea, title, dashboard).
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.state,
    required this.onStatePillTap,
    required this.videoHeight,
    this.category,
    this.videoPath,
    this.originalVideoName,
    this.canEditState = true,
    this.onRepick,
  });

  final String title;
  final LearningState state;
  final String? category;
  final String? videoPath;
  final String? originalVideoName;
  final bool canEditState;
  final VoidCallback onStatePillTap;
  final double videoHeight;

  /// Called when the user taps "Re-import" on a missing video.
  /// Wired to open [VideoPickerSheet] from the review session.
  final VoidCallback? onRepick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);

    return Container(
      decoration: AppSurfaces.panel(
        context,
        raised: true,
        radius: AppRadius.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: videoPath != null
                ? RobustVideoPlayer(
                    videoPath: videoPath!,
                    height: videoHeight,
                    onRepick: onRepick,
                    originalVideoName: originalVideoName,
                    autoPlay: true,
                  )
                : VideoPlaceholder(height: videoHeight),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: canEditState ? onStatePillTap : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatePill(state: state),
                          if (canEditState) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 12,
                              color: semanticTheme
                                  .colorForState(state)
                                  .withValues(alpha: 0.72),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (category != null && category != 'default') ...[
                  const SizedBox(height: 6),
                  Text(
                    category!.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      letterSpacing: 1.5,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
