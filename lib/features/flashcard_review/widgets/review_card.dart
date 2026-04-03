import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/combos_dao.dart';
import '../../../core/design/spacing.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/models/review_card_display_settings.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;
import 'instrument_panel.dart';
import 'review_dashboard.dart';

/// Two-stage review card.
///
/// Stage 1 shows the actual video plus configurable learning information.
/// Stage 2 keeps the video in place and swaps the metadata panel out so the
/// footer can focus on grading controls.
///
/// The card returns a [Column] with two zones:
/// 1. **Video surface** (Expanded) — full-bleed video with only a textual
///    progress badge and a close button overlaid via a short top gradient scrim.
/// 2. **Instrument panel** (intrinsic height) — configurable metadata shown
///    only during the first stage.
class ReviewCard extends ConsumerStatefulWidget {
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
    this.canEditState = true,
    this.onRepick,
    this.combo,
    this.onEnd,
    this.loopEnabled = true,
    this.onLoopToggle,
    this.playbackSpeed = 1.0,
    this.onSpeedCycle,
  });

  final String title;
  final LearningState state;
  final ReviewCardDisplaySettings displaySettings;
  final bool showMetadataPanel;
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

  // ── Playback control props ──────────────────────────────────────────────

  /// Whether the video is looping.
  final bool loopEnabled;

  /// Toggles loop on/off.
  final VoidCallback? onLoopToggle;

  /// Current playback speed (0.5, 1.0, 1.5, 2.0).
  final double playbackSpeed;

  /// Cycles to the next speed preset.
  final VoidCallback? onSpeedCycle;

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
      return _buildCard(
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

        return _buildCard(
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

  /// Builds the two-zone card: [Expanded video surface] + [InstrumentPanel].
  Widget _buildCard(
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

    return Column(
      children: [
        // ── Zone B: Video surface (takes remaining space) ────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Video fills entire surface — minimal mode strips
                //    internal controls so the video is a clean viewport.
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
                        minimal: true,
                        looping: widget.loopEnabled,
                        playbackSpeed: widget.playbackSpeed,
                      );
                    },
                  ),
                ),

                // 2. Short top-only gradient scrim — just enough for
                //    the session counter and close button readability.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.30),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Top overlay — count badge + close button (48x48)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Spacer to balance close button width
                      const SizedBox(width: 48),
                      Expanded(
                        child: Center(
                          child: ReviewPositionBadge(
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Zone C: Instrument panel ─────────────────────────────────────
        InstrumentPanel(
          title: title,
          state: widget.state,
          displaySettings: widget.displaySettings,
          category: category,
          canEditState: widget.canEditState,
          showMetadata: widget.showMetadataPanel,
          onStatePillTap: widget.onStatePillTap,
          comboMoves: comboMoves,
          activeComboStepIndex: activeComboStepIndex,
          onStepSelected: isCombo
              ? (index) {
                  setState(() => _activeComboStepIndex = index);
                }
              : null,
          activeStep: activeStep,
          loopEnabled: widget.loopEnabled,
          onLoopToggle: widget.onLoopToggle,
          playbackSpeed: widget.playbackSpeed,
          onSpeedCycle: widget.onSpeedCycle,
        ),
      ],
    );
  }
}
