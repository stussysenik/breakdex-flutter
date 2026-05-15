import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/combos_dao.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/models/review_card_display_settings.dart';
import '../../../shared/widgets/combo_step_line.dart';
import '../../../shared/widgets/state_pill.dart';

/// Instrument panel — metadata and playback controls that sit between the
/// video player and the rating buttons in the redesigned review card.
///
/// For **move cards** the panel is compact (~72pt): title, state pill,
/// category label, loop toggle, and speed selector.
///
/// For **combo cards** the panel grows (~120pt) to include the
/// [ComboStepLine] timeline so the learner can scrub through each move
/// while reviewing the combo as one card.
///
/// The panel has a subtle bottom border to visually separate it from the
/// rating strip below. Background color matches the surface so it reads
/// as a distinct "instrument cluster" rather than floating metadata.
class InstrumentPanel extends StatelessWidget {
  const InstrumentPanel({
    super.key,
    required this.title,
    required this.state,
    required this.displaySettings,
    this.category,
    this.canEditState = true,
    this.showMetadata = true,
    this.onStatePillTap,
    this.onTitleTap,
    // Combo props
    this.comboMoves = const [],
    this.activeComboStepIndex = 0,
    this.onStepSelected,
    this.activeStep,
    // Playback controls
    this.loopEnabled = true,
    this.onLoopToggle,
    this.playbackSpeed = 1.0,
    this.onSpeedCycle,
  });

  /// Display name for the move or combo being reviewed.
  final String title;

  /// Current FSRS learning state — rendered via [StatePill].
  final LearningState state;

  /// Configurable visibility for the stage-1 learning information.
  final ReviewCardDisplaySettings displaySettings;

  /// Optional category label (e.g. "POWER MOVES"). Hidden when null or
  /// equal to `'default'` to avoid visual noise.
  final String? category;

  /// Whether the state pill is tappable (opens the state picker sheet).
  final bool canEditState;

  /// Stage 2 hides the metadata panel so the learner only sees grading.
  final bool showMetadata;

  /// Called when the learner taps the [StatePill] to manually override
  /// the learning state.
  final VoidCallback? onStatePillTap;

  /// Called when the learner taps the move/combo name title to navigate
  /// to the detail screen.
  final VoidCallback? onTitleTap;

  // ── Combo-specific props ──────────────────────────────────────────────

  /// Ordered list of moves in the combo. When non-empty the panel renders
  /// the [ComboStepLine] timeline between the title row and the controls.
  final List<ComboMoveWithDetail> comboMoves;

  /// Zero-based index of the currently active combo step.
  final int activeComboStepIndex;

  /// Callback when the learner taps a step in the [ComboStepLine].
  final ValueChanged<int>? onStepSelected;

  /// The [Move] record for the active combo step — its name is shown in
  /// the secondary label below the timeline.
  final Move? activeStep;

  // ── Playback control props ────────────────────────────────────────────

  /// Whether the video player is set to loop the current clip.
  final bool loopEnabled;

  /// Toggles the loop state. The icon changes between `repeat_one` (active)
  /// and `repeat` (inactive) to give a clear visual cue.
  final VoidCallback? onLoopToggle;

  /// Current playback speed multiplier (e.g. 0.5, 1.0, 1.5, 2.0).
  final double playbackSpeed;

  /// Cycles to the next speed in the predefined list. The button label
  /// updates to show the current speed ("1x", "0.5x", etc.).
  final VoidCallback? onSpeedCycle;

  bool get _isCombo => comboMoves.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!showMetadata) return const SizedBox.shrink();

    final showTitle = displaySettings.showTitle;
    final showState = displaySettings.showState;
    final showCategory =
        !_isCombo &&
        displaySettings.showCategory &&
        category != null &&
        category != 'default';
    final showComboTimeline = _isCombo && displaySettings.showComboTimeline;
    final showActiveStepLabel =
        _isCombo && displaySettings.showComboStepName && activeStep != null;
    final showPlaybackControls = displaySettings.showPlaybackControls;

    if (!(showTitle ||
        showState ||
        showCategory ||
        showComboTimeline ||
        showActiveStepLabel ||
        showPlaybackControls)) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdge,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: Title + State Pill ────────────────────────────────
            if (showTitle || showState)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showTitle)
                    Expanded(
                      child: GestureDetector(
                        onTap: onTitleTap,
                        child: Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (showTitle && showState)
                    const SizedBox(width: AppSpacing.sm),
                  if (showState)
                    GestureDetector(
                      onTap: canEditState ? onStatePillTap : null,
                      child: StatePill(state: state, overlay: false),
                    ),
                ],
              ),

            // ── Combo: step line timeline ────────────────────────────────
            if (showComboTimeline) ...[
              const SizedBox(height: AppSpacing.sm),
              ComboStepLine(
                stepCount: comboMoves.length,
                activeIndex: activeComboStepIndex,
                onStepSelected: onStepSelected ?? (_) {},
                overlay: false,
                stepNames:
                    comboMoves.map((cm) => cm.move.name).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            if ((showTitle || showState) &&
                (showCategory || showActiveStepLabel || showPlaybackControls))
              const SizedBox(height: AppSpacing.xs),

            // ── Row 2: Secondary label + playback controls ───────────────
            if (showCategory || showActiveStepLabel || showPlaybackControls)
              Row(
                children: [
                  if (showActiveStepLabel)
                    Expanded(
                      child: Text(
                        activeStep!.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (showCategory)
                    Expanded(
                      child: Text(
                        category!.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                          letterSpacing: 1.5,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (showPlaybackControls) ...[
                    _InstrumentButton(
                      icon: loopEnabled
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      isActive: loopEnabled,
                      onTap: onLoopToggle,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _SpeedButton(
                      speed: playbackSpeed,
                      onTap: onSpeedCycle,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal icon toggle button with no background fill.
///
/// Uses a generous 48x40pt touch target (exceeding the 44pt minimum
/// recommended by Apple HIG) while keeping the icon visually small (20pt)
/// so the panel feels lightweight.
class _InstrumentButton extends StatelessWidget {
  const _InstrumentButton({
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: SizedBox(
        width: 48,
        height: 40,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Speed selector button that shows the current multiplier ("1x", "0.5x").
///
/// The label turns [ColorScheme.primary] when the speed differs from 1.0x
/// to draw attention to the non-default state — a subtle but effective
/// indicator borrowed from pro video editing tools.
class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.speed,
    this.onTap,
  });

  final double speed;
  final VoidCallback? onTap;

  /// Format the speed as a compact label: "1x", "0.5x", "1.5x", "2x".
  String get _label {
    // Avoid trailing zeros: 1.0 → "1x", 0.5 → "0.5x"
    final formatted =
        speed == speed.roundToDouble() ? speed.toInt().toString() : '$speed';
    return '${formatted}x';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDefault = speed == 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: SizedBox(
        width: 48,
        height: 40,
        child: Center(
          child: Text(
            _label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDefault ? colorScheme.secondary : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
