import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/reviewable_item.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/pressable.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';

class InstaxVideoCard extends ConsumerStatefulWidget {
  const InstaxVideoCard({
    super.key,
    required this.item,
    required this.isActive,
    this.muted = false,
    this.looping = true,
    this.onLongPress,
    this.onTap,
  });

  final ReviewableItem item;
  final bool isActive;
  final bool muted;
  final bool looping;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  ConsumerState<InstaxVideoCard> createState() => _InstaxVideoCardState();
}

class _InstaxVideoCardState extends ConsumerState<InstaxVideoCard> {
  @override
  void didUpdateWidget(final InstaxVideoCard old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      debugPrint(
        '[InstaxCard] activeChanged: ${widget.item.displayName} isActive=${widget.isActive}',
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final item = widget.item;
    final videoPath = item.videoPath;
    final hasVideo = videoPath != null;

    // TODO: Handle learning state for combos if available
    final learningState = item is ReviewableMove
        ? LearningState.fromString(item.move.learningState)
        : LearningState.newState;

    final labels = ref.watch(learningStateLabelsProvider);
    final label = resolveLearningStateLabel(labels, learningState);

    return Pressable(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdge,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.darkSeparator.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasVideo)
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RobustVideoPlayer(
                      key: ValueKey('instax-${item.entityType}-${item.entityId}'),
                      videoPath: videoPath,
                      autoPlay: widget.isActive,
                      minimal: true,
                      looping: widget.looping,
                      muted: widget.muted,
                      borderRadius: BorderRadius.zero,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: learningState.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.isActive)
                      Positioned.fill(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              )
            else
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: AppColors.darkFill,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white24),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'No video',
                        style: TextStyle(color: Colors.white24),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              color: AppColors.darkCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category != null && item.category != 'default') ...[
                    const SizedBox(height: 4),
                    Text(
                      item.category!,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

