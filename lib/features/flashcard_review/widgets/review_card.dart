import 'package:flutter/material.dart';

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
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
    required this.move,
    required this.isRevealed,
    required this.onStatePillTap,
    required this.videoHeight,
    this.onRepick,
  });

  final Move move;
  final bool isRevealed;
  final VoidCallback onStatePillTap;
  final double videoHeight;

  /// Called when the user taps "Re-import" on a missing video.
  /// Wired to open [VideoPickerSheet] from the review session.
  final VoidCallback? onRepick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = LearningState.fromString(move.learningState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video — 60% visual weight, edge-to-edge
        move.videoPath != null
              ? (isRevealed
                  ? RobustVideoPlayer(
                      videoPath: move.videoPath!,
                      height: videoHeight,
                      onRepick: onRepick,
                      originalVideoName: move.originalVideoName,
                      autoPlay: true,
                    )
                  : Container(
                      height: videoHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.help_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ))
              : VideoPlaceholder(height: videoHeight),
        const SizedBox(height: 6),

        // Context band — compact, close to video
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
          child: Row(
            children: [
              // Move name (dominant, left-aligned)
              Expanded(
                child: Text(
                  isRevealed ? move.name : '???',
                  style: AppTypography.titleSmall.copyWith(
                    color: isRevealed 
                        ? colorScheme.onSurface 
                        : colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Category + state pills
              if (move.category != 'default')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    isRevealed ? move.category.toUpperCase() : '???',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onStatePillTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatePill(state: state),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: state.color.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
