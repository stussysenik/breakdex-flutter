// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:breakdex/core/platform/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/fsrs_service.dart';
import 'package:breakdex/core/models/reviewable_item.dart';

/// A row in the schedule item list showing an item's name, state, and SRS data.
///
/// Each row shows:
/// - Colored state indicator bar (left edge)
/// - Video thumbnail (if available)
/// - Item name + category
/// - SRS detail line: stability, difficulty, retrievability, reps
/// - Entity type icon (move vs combo)
class ScheduledItemRow extends ConsumerWidget {
  const ScheduledItemRow({super.key, required this.item, required this.onTap});

  final ReviewableItemWithCard item;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = item.card;
    final visibleState = learningStateFromFsrsState(card?.fsrsState);
    final stateColor = context.stateColor(visibleState);
    final labels = ref.watch(learningStateLabelsProvider);
    final retPct = (item.retrievability * 100).round();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // State color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.sm),
                    bottomLeft: Radius.circular(AppRadius.sm),
                  ),
                ),
              ),

              // Thumbnail
              if (item.item.videoPath != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildThumbnail(item.item.videoPath!),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: colorScheme.surface,
                    ),
                    child: Icon(
                      item.item is ReviewableCombo
                          ? Icons.linear_scale_rounded
                          : Icons.sports_martial_arts,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),

              // Name + SRS detail
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Entity type icon
                          Icon(
                            item.item is ReviewableCombo
                                ? Icons.linear_scale_rounded
                                : Icons.sports_martial_arts,
                            size: 12,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.item.displayName,
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // SRS detail line
                      if (card != null)
                        Text(
                          'S:${_fmtStability(card.stability)} '
                          'D:${card.difficulty.toStringAsFixed(1)} '
                          'R:$retPct% '
                          'reps:${card.reps}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${resolveLearningStateLabel(labels, visibleState)} — not yet reviewed',
                          style: AppTypography.caption.copyWith(
                            color: stateColor,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Category chip (moves only)
              if (item.item.category != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    item.item.category!,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                      fontSize: 10,
                    ),
                  ),
                ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(final String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Center(child: Icon(Icons.videocam_off, size: 20));
    }
    // Video thumbnail placeholder — actual thumbnail generation would
    // require a video_thumbnail package, so we show a styled placeholder
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 20, color: Colors.white54),
      ),
    );
  }

  static String _fmtStability(final double s) {
    if (s < 1) return '${(s * 24).round()}h';
    if (s < 30) return '${s.round()}d';
    return '${(s / 30).toStringAsFixed(1)}mo';
  }
}
