import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';

// ---------------------------------------------------------------------------
// Affinity model — the three-tier transition rating system.
// ---------------------------------------------------------------------------

/// The three aura affinities, inspired by Pokemon type effectiveness.
///
/// - **natural**: super effective — the transition flows effortlessly.
/// - **possible**: neutral — it works but requires deliberate setup.
/// - **stretch**: not very effective — forcing this transition is risky.
enum AuraAffinity {
  natural,
  possible,
  stretch;

  /// Parse from DB string, defaulting to [possible] for unknown values.
  static AuraAffinity fromString(final String value) => switch (value) {
        'natural' => AuraAffinity.natural,
        'stretch' => AuraAffinity.stretch,
        _ => AuraAffinity.possible,
      };

  /// The next affinity in the tap-cycle: natural -> possible -> stretch -> null.
  /// Returning null signals "delete this link."
  AuraAffinity? get next => switch (this) {
        AuraAffinity.natural => AuraAffinity.possible,
        AuraAffinity.possible => AuraAffinity.stretch,
        AuraAffinity.stretch => null,
      };

  /// Human-readable label for the affinity tier.
  String get label => switch (this) {
        AuraAffinity.natural => 'Natural',
        AuraAffinity.possible => 'Possible',
        AuraAffinity.stretch => 'Stretch',
      };

  /// Semantic color for the affinity dot.
  /// Green = flows naturally, yellow = workable, red = forced.
  Color color(final BuildContext context) {
    final semantic = AppSemanticTheme.of(context);
    return switch (this) {
      AuraAffinity.natural => semantic.isMonoOutline
          ? Theme.of(context).colorScheme.onSurface
          : const Color(0xFF1F8A70), // green — super effective
      AuraAffinity.possible => semantic.isMonoOutline
          ? Theme.of(context).colorScheme.secondary
          : const Color(0xFFB7911F), // amber — neutral
      AuraAffinity.stretch => semantic.isMonoOutline
          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
          : const Color(0xFFC23B2A), // red — not very effective
    };
  }
}

// ---------------------------------------------------------------------------
// AuraLinkTile — a single move-to-move transition row.
// ---------------------------------------------------------------------------

/// Displays a single aura link: "Toprock -> 6-Step" with an affinity dot.
///
/// **Interaction model** (fast, no modals):
/// - Tap the affinity dot to cycle: natural -> possible -> stretch -> delete.
/// - The parent handles the actual DB write via [onAffinityChanged] / [onDelete].
///
/// **Design**: Compact row layout for use in scrollable lists. The colored dot
/// serves as both status indicator and tap target, keeping the UI minimal.
class AuraLinkTile extends StatelessWidget {
  const AuraLinkTile({
    super.key,
    required this.fromMoveName,
    required this.toMoveName,
    required this.affinity,
    this.notes,
    required this.onAffinityChanged,
    required this.onDelete,
  });

  /// Display name of the origin move (e.g., "Toprock").
  final String fromMoveName;

  /// Display name of the destination move (e.g., "6-Step").
  final String toMoveName;

  /// Current affinity rating for this transition.
  final AuraAffinity affinity;

  /// Optional user notes about the transition.
  final String? notes;

  /// Called when the user taps to cycle the affinity to a new value.
  final ValueChanged<AuraAffinity> onAffinityChanged;

  /// Called when the user cycles past "stretch" — delete the link.
  final VoidCallback onDelete;

  void _cycleAffinity() {
    final next = affinity.next;
    if (next != null) {
      onAffinityChanged(next);
    } else {
      onDelete();
    }
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final affinityColor = affinity.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
      child: Row(
        children: [
          // Affinity dot — tap target for cycling.
          GestureDetector(
            onTap: _cycleAffinity,
            behavior: HitTestBehavior.opaque,
            child: Semantics(
              label: 'Affinity: ${affinity.label}. Tap to change.',
              button: true,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: AnimatedContainer(
                  duration: AppMotion.moderate01,
                  curve: AppMotion.productive,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: affinityColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: affinityColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Transition label: "From -> To"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: fromMoveName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  \u2192  ',
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                      TextSpan(
                        text: toMoveName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (notes != null && notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Affinity label pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: affinityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              affinity.label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: affinityColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
