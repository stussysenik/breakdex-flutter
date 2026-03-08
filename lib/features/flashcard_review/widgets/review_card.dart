import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/combos_dao.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/combo_step_line.dart';
import '../../../shared/widgets/state_pill.dart';
import '../../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

/// 60/30/10 review card — video dominates, metadata is compact.
///
/// Move cards remain simple. Combo cards reuse the same sequence step-line
/// from the combo detail screen so the learner can scrub each move while
/// still rating the combo as a single card.
class ReviewCard extends ConsumerStatefulWidget {
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
    this.combo,
  });

  final String title;
  final LearningState state;
  final String? category;
  final String? videoPath;
  final String? originalVideoName;
  final bool canEditState;
  final VoidCallback onStatePillTap;
  final double videoHeight;
  final VoidCallback? onRepick;
  final Combo? combo;

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
      return _buildSurface(
        context,
        video: hasVideo
            ? RobustVideoPlayer(
                key: ValueKey(widget.videoPath),
                videoPath: widget.videoPath!,
                height: widget.videoHeight,
                onRepick: widget.onRepick,
                originalVideoName: widget.originalVideoName,
                autoPlay: true,
              )
            : VideoPlaceholder(height: widget.videoHeight),
        metadata: _ReviewMetadata(
          title: widget.title,
          state: widget.state,
          category: widget.category,
          canEditState: widget.canEditState,
          onStatePillTap: widget.onStatePillTap,
        ),
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

        return _buildSurface(
          context,
          video: currentVideoPath != null && currentVideoPath.trim().isNotEmpty
              ? RobustVideoPlayer(
                  key: ValueKey(
                    '${widget.combo!.id}:$safeIndex:$currentVideoPath',
                  ),
                  videoPath: currentVideoPath,
                  height: widget.videoHeight,
                  originalVideoName:
                      currentStep?.originalVideoName ??
                      widget.originalVideoName,
                  autoPlay: true,
                )
              : VideoPlaceholder(height: widget.videoHeight),
          metadata: _ReviewMetadata(
            title: widget.title,
            state: widget.state,
            category: null,
            canEditState: false,
            onStatePillTap: widget.onStatePillTap,
            comboSteps: comboMoves,
            activeComboStepIndex: safeIndex,
            activeStep: currentStep,
            onComboStepSelected: (index) {
              setState(() => _activeComboStepIndex = index);
            },
          ),
        );
      },
    );
  }

  Widget _buildSurface(
    BuildContext context, {
    required Widget video,
    required Widget metadata,
  }) {
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
            child: video,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: metadata,
          ),
        ],
      ),
    );
  }
}

class _ReviewMetadata extends StatelessWidget {
  const _ReviewMetadata({
    required this.title,
    required this.state,
    required this.canEditState,
    required this.onStatePillTap,
    this.category,
    this.comboSteps = const <ComboMoveWithDetail>[],
    this.activeComboStepIndex = 0,
    this.activeStep,
    this.onComboStepSelected,
  });

  final String title;
  final LearningState state;
  final String? category;
  final bool canEditState;
  final VoidCallback onStatePillTap;
  final List<ComboMoveWithDetail> comboSteps;
  final int activeComboStepIndex;
  final Move? activeStep;
  final ValueChanged<int>? onComboStepSelected;

  bool get isCombo => comboSteps.isNotEmpty || onComboStepSelected != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);

    return Column(
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
        if (isCombo) ...[
          const SizedBox(height: AppSpacing.md),
          ComboStepLine(
            stepCount: comboSteps.length,
            activeIndex: activeComboStepIndex,
            onStepSelected: onComboStepSelected ?? (_) {},
          ),
          if (activeStep != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              activeStep!.name,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (activeStep!.category != 'default') ...[
              const SizedBox(height: 6),
              Text(
                activeStep!.category.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 1.4,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ] else if (category != null && category != 'default') ...[
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
    );
  }
}
