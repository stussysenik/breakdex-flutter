import 'package:flutter/material.dart';

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../shared/widgets/state_pill.dart';
import '../../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

/// The center card showing video, move name, category, and tappable state pill.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.move,
    required this.onStatePillTap,
  });

  final Move move;
  final VoidCallback onStatePillTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = LearningState.fromString(move.learningState);

    // Responsive video height: use ~45% of available screen
    final screenHeight = MediaQuery.of(context).size.height;
    final videoHeight = (screenHeight * 0.38).clamp(200.0, 400.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video
        if (move.videoPath != null)
          RobustVideoPlayer(videoPath: move.videoPath!, height: videoHeight)
        else
          VideoPlaceholder(height: videoHeight),
        const SizedBox(height: AppSpacing.md),

        // Move name
        Text(
          move.name,
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Category label
        if (move.category != 'default')
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              move.category.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ),

        // Tappable state pill
        GestureDetector(
          onTap: onStatePillTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatePill(state: state),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: state.color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
