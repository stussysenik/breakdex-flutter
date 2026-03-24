import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/combos_dao.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/combo_step_line.dart';
import '../../../shared/widgets/state_pill.dart';
import '../../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;
import 'review_dashboard.dart';

/// Immersive review card — video fills the card, metadata overlaid via
/// gradient scrim. Designed for a 70/30 split where the card fills ~70%
/// of the screen and the rating strip takes ~30%.
///
/// Move cards show the video full-bleed with name, state pill, and category
/// overlaid on a bottom gradient. Combo cards add the step-line timeline
/// so the learner can scrub each move while rating the combo as one card.
class ReviewCard extends ConsumerStatefulWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.state,
    required this.onStatePillTap,
    required this.currentIndex,
    required this.totalItems,
    this.category,
    this.videoPath,
    this.originalVideoName,
    this.canEditState = true,
    this.onRepick,
    this.combo,
    this.onEnd,
  });

  final String title;
  final LearningState state;
  final String? category;
  final String? videoPath;
  final String? originalVideoName;
  final bool canEditState;
  final VoidCallback onStatePillTap;
  final VoidCallback? onRepick;
  final Combo? combo;

  /// Current card index in the session (0-based).
  final int currentIndex;

  /// Total number of cards in the session.
  final int totalItems;

  /// Callback to end the review session (shown as top-right button).
  final VoidCallback? onEnd;

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  int? _activeComboStepIndex;

  @override
  void didUpdateWidget(covariant ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.combo?.id != widget.combo?.id) {
      _activeComboStepIndex = null;
    }
  }

  int _preferredStepIndex(List<ComboMoveWithDetail> comboMoves) {
    if (_activeComboStepIndex != null && comboMoves.isNotEmpty) {
      return _activeComboStepIndex!.clamp(0, comboMoves.length - 1);
    }

    final firstPlayable = comboMoves.indexWhere(
      (entry) =>
          entry.move.videoPath != null &&
          entry.move.videoPath!.trim().isNotEmpty,
    );
    return firstPlayable >= 0 ? firstPlayable : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo == null) {
      final hasVideo =
          widget.videoPath != null && widget.videoPath!.trim().isNotEmpty;
      return _buildImmersiveCard(
        context,
        videoPath: hasVideo ? widget.videoPath : null,
        originalVideoName: widget.originalVideoName,
        title: widget.title,
        category: widget.category,
      );
    }

    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(widget.combo!.id);

    return StreamBuilder<List<ComboMoveWithDetail>>(
      stream: comboMovesStream,
      builder: (context, snapshot) {
        final comboMoves = snapshot.data ?? const <ComboMoveWithDetail>[];
        final safeIndex = comboMoves.isEmpty
            ? 0
            : _preferredStepIndex(comboMoves);
        final currentStep = comboMoves.isEmpty
            ? null
            : comboMoves[safeIndex].move;
        final rawStepVideoPath = currentStep?.videoPath;
        final stepVideoPath =
            rawStepVideoPath != null && rawStepVideoPath.trim().isNotEmpty
            ? rawStepVideoPath
            : null;
        final currentVideoPath = stepVideoPath ?? widget.combo!.activeVideoPath;
        final hasVideo =
            currentVideoPath != null && currentVideoPath.trim().isNotEmpty;

        return _buildImmersiveCard(
          context,
          videoPath: hasVideo ? currentVideoPath : null,
          originalVideoName:
              currentStep?.originalVideoName ?? widget.originalVideoName,
          title: widget.title,
          category: null, // combos don't show category
          comboMoves: comboMoves,
          activeComboStepIndex: safeIndex,
          activeStep: currentStep,
        );
      },
    );
  }

  /// Builds the immersive Stack-based card: video fills background,
  /// gradient scrim at bottom, metadata overlaid, progress dots at top.
  Widget _buildImmersiveCard(
    BuildContext context, {
    required String? videoPath,
    required String? originalVideoName,
    required String title,
    String? category,
    List<ComboMoveWithDetail> comboMoves = const [],
    int activeComboStepIndex = 0,
    Move? activeStep,
  }) {
    final isCombo = comboMoves.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video fills entire card
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (videoPath == null) {
                  return VideoPlaceholder(height: constraints.maxHeight);
                }
                return RobustVideoPlayer(
                  key: ValueKey(
                    isCombo
                        ? '${widget.combo!.id}:$activeComboStepIndex:$videoPath'
                        : videoPath,
                  ),
                  videoPath: videoPath,
                  height: constraints.maxHeight,
                  borderRadius: BorderRadius.zero,
                  onRepick: widget.onRepick,
                  originalVideoName: originalVideoName,
                  autoPlay: true,
                );
              },
            ),
          ),

          // 2. Gradient scrim — transparent top, dark bottom for metadata
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.15, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Top overlay — progress dots + end button
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Spacer to balance end button width
                const SizedBox(width: 44),
                Expanded(
                  child: Center(
                    child: ProgressDots(
                      currentIndex: widget.currentIndex,
                      total: widget.totalItems,
                    ),
                  ),
                ),
                if (widget.onEnd != null)
                  GestureDetector(
                    onTap: widget.onEnd,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'End',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),

          // 4. Bottom overlay — metadata
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Combo step line (above title when present)
                if (isCombo) ...[
                  ComboStepLine(
                    stepCount: comboMoves.length,
                    activeIndex: activeComboStepIndex,
                    onStepSelected: (index) {
                      setState(() => _activeComboStepIndex = index);
                    },
                    overlay: true,
                    stepNames: comboMoves
                        .map((cm) => cm.move.name)
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Title row + state pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: widget.canEditState ? widget.onStatePillTap : null,
                      child: StatePill(
                        state: widget.state,
                        overlay: true,
                      ),
                    ),
                  ],
                ),

                // Category label
                if (category != null && category != 'default') ...[
                  const SizedBox(height: 4),
                  Text(
                    category.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Active step name for combos
                if (isCombo && activeStep != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activeStep.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
