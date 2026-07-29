import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/review_card_display_settings.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';
import 'package:breakdex/features/flashcard_review/widgets/instrument_panel.dart';
import 'package:breakdex/features/flashcard_review/widgets/review_position_badge.dart';
import 'package:breakdex/core/design/icons.dart';

class ReviewCard extends ConsumerWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.state,
    required this.displaySettings,
    required this.showMetadataPanel,
    required this.onStatePillTap,
    required this.currentIndex,
    required this.totalItems,
    this.category,
    this.videoPath,
    this.originalVideoName,
    this.contentHash,
    this.notes,
    this.canEditState = true,
    this.onRepick,
    this.combo,
    this.onEnd,
    this.onTitleTap,
    this.loopEnabled = true,
    this.onLoopToggle,
    this.playbackSpeed = 1.0,
    this.onSpeedCycle,
    this.activeComboStepIndex,
    this.onStepSelected,
  });

  final String title;
  final LearningState state;
  final ReviewCardDisplaySettings displaySettings;
  final bool showMetadataPanel;
  final String? category;
  final String? videoPath;
  final String? originalVideoName;
  final String? contentHash;

  /// Learner's own notes for the move (collapsed behind an expand affordance in
  /// the instrument panel). For combos the active step's notes are used instead.
  final String? notes;
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

  /// Called when the learner taps the move/combo name to navigate to detail.
  final VoidCallback? onTitleTap;

  // ── Playback control props ──────────────────────────────────────────────

  /// Whether the video is looping.
  final bool loopEnabled;

  /// Toggles loop on/off.
  final VoidCallback? onLoopToggle;

  /// Current playback speed (0.5, 1.0, 1.5, 2.0).
  final double playbackSpeed;

  /// Cycles to the next speed preset.
  final VoidCallback? onSpeedCycle;

  /// Active step in a combo — managed by parent.
  final int? activeComboStepIndex;

  /// Callback when a step is selected in a combo.
  final ValueChanged<int>? onStepSelected;

  int _preferredStepIndex(final List<ComboMoveWithDetail> comboMoves) {
    if (activeComboStepIndex != null && comboMoves.isNotEmpty) {
      return activeComboStepIndex!.clamp(0, comboMoves.length - 1);
    }

    final firstPlayable = comboMoves.indexWhere(
      (final entry) =>
          entry.move.videoPath != null &&
          entry.move.videoPath!.trim().isNotEmpty,
    );
    return firstPlayable >= 0 ? firstPlayable : 0;
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Live-customizable frame fill (null → classic white), applied without restart.
    final fill = ref.watch(reviewFillColorProvider) ?? Colors.white;

    if (combo == null) {
      final hasVideo = videoPath != null && videoPath!.trim().isNotEmpty;
      return _buildCard(
        context,
        fill: fill,
        videoPath: hasVideo ? videoPath : null,
        originalVideoName: originalVideoName,
        title: title,
        category: category,
        notes: notes,
      );
    }

    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(combo!.id);

    return StreamBuilder<List<ComboMoveWithDetail>>(
      stream: comboMovesStream,
      builder: (final context, final snapshot) {
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

        return _buildCard(
          context,
          fill: fill,
          videoPath: stepVideoPath,
          originalVideoName: currentStep?.originalVideoName,
          title: currentStep?.name ?? title,
          category: category ?? currentStep?.category,
          notes: currentStep?.notes,
          comboMoves: comboMoves,
          activeComboStepIndex: safeIndex,
          activeStep: currentStep,
        );
      },
    );
  }

  Widget _buildCard(
    final BuildContext context, {
    required final Color fill,
    required final String? videoPath,
    required final String? originalVideoName,
    required final String title,
    required final String? category,
    final String? notes,
    final List<ComboMoveWithDetail> comboMoves = const [],
    final int activeComboStepIndex = 0,
    final Move? activeStep,
  }) {
    final isCombo = combo != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Zone A: Instax-style Video Stage ──────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.75, // Physical Instax Mini aspect ratio (3:4)
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        fill, // Instax frame — user-customizable, default white
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    48,
                  ), // Bottom-heavy frame
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.darkFill,
                      borderRadius: BorderRadius.circular(AppRadius.xxs),
                    ),
                    child: Stack(
                      children: [
                        // 1. Video Surface
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (final context, final constraints) {
                              if (videoPath == null) {
                                return const VideoPlaceholder(
                                  icon: AppIcon.videoOff,
                                );
                              }

                              return RobustVideoPlayer(
                                key: ValueKey(
                                  isCombo
                                      ? '${combo!.id}:$activeComboStepIndex:$videoPath:${activeStep?.contentHash}'
                                      : '$videoPath:$contentHash',
                                ),
                                videoPath: videoPath,
                                height: constraints.maxHeight,
                                borderRadius: BorderRadius.zero,
                                onRepick: onRepick,
                                originalVideoName: originalVideoName,
                                autoPlay: true,
                                minimal: true,
                                looping: loopEnabled,
                                playbackSpeed: playbackSpeed,
                              );
                            },
                          ),
                        ),

                        // 2. Short top-only gradient scrim
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.20),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Top overlay — count badge + close button
                        Positioned(
                          top: 8,
                          left: 12,
                          right: 12,
                          child: Row(
                            children: [
                              const SizedBox(width: 40),
                              Expanded(
                                child: Center(
                                  child: ReviewPositionBadge(
                                    currentIndex: currentIndex,
                                    total: totalItems,
                                  ),
                                ),
                              ),
                              if (onEnd != null)
                                GestureDetector(
                                  onTap: onEnd,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.20,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const AppIconView(
                                      AppIcon.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Zone C: Instrument panel ─────────────────────────────────────
        InstrumentPanel(
          title: title,
          state: state,
          displaySettings: displaySettings,
          category: category,
          notes: notes,
          canEditState: canEditState,
          showMetadata: showMetadataPanel,
          onStatePillTap: onStatePillTap,
          onTitleTap: onTitleTap,
          comboMoves: comboMoves,
          activeComboStepIndex: activeComboStepIndex,
          onStepSelected: onStepSelected,
          activeStep: activeStep,
          loopEnabled: loopEnabled,
          onLoopToggle: onLoopToggle,
          playbackSpeed: playbackSpeed,
          onSpeedCycle: onSpeedCycle,
        ),
      ],
    );
  }
}
