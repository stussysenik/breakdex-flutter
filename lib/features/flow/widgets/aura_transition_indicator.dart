import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../providers/aura_providers.dart';
import 'aura_link_tile.dart';

// ---------------------------------------------------------------------------
// AuraTransitionIndicator — colored dot/pill between two moves in a set.
// ---------------------------------------------------------------------------

/// A compact visual indicator showing the aura affinity between two moves.
///
/// Designed to sit between move tiles in the Set Builder sequence. The colored
/// dot uses the same Pokemon-inspired scheme as [AuraLinkTile]:
///
/// - **Green** (natural): super effective — flows effortlessly.
/// - **Amber** (possible): neutral — requires setup.
/// - **Red** (stretch): not very effective — risky transition.
/// - **Gray** (unrated): no aura link exists yet between these moves.
///
/// When [showLabel] is true, the affinity name is displayed next to the dot
/// as a small pill — useful in expanded views where space allows.
class AuraTransitionIndicator extends ConsumerWidget {
  const AuraTransitionIndicator({
    super.key,
    required this.fromMoveId,
    required this.toMoveId,
    this.showLabel = false,
    this.size = 8,
  });

  /// The ID of the origin move in the transition.
  final String fromMoveId;

  /// The ID of the destination move in the transition.
  final String toMoveId;

  /// When true, shows the affinity label ("Natural", "Possible", etc.)
  /// next to the dot. Defaults to false for compact inline usage.
  final bool showLabel;

  /// Diameter of the affinity dot in logical pixels.
  final double size;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final affinityAsync = ref.watch(
      auraAffinityProvider((fromId: fromMoveId, toId: toMoveId)),
    );

    return affinityAsync.when(
      loading: () => _buildDot(context, null),
      error: (_, _) => _buildDot(context, null),
      data: (final affinityString) => _buildDot(context, affinityString),
    );
  }

  Widget _buildDot(final BuildContext context, final String? affinityString) {
    final affinity = affinityString != null
        ? AuraAffinity.fromString(affinityString)
        : null;
    final color = affinity?.color(context) ?? _unratedColor(context);

    if (!showLabel) {
      return Semantics(
        label: affinity != null
            ? 'Transition affinity: ${affinity.label}'
            : 'Transition: unrated',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // Expanded pill with label.
    final label = affinity?.label ?? 'Unrated';
    return Semantics(
      label: 'Transition affinity: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gray color for unrated transitions — indicates no aura link exists.
  Color _unratedColor(final BuildContext context) {
    return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35);
  }
}

// ---------------------------------------------------------------------------
// AuraTransitionArrow — vertical connector with dot for set builder lists.
// ---------------------------------------------------------------------------

/// A vertical connector line with an aura dot in the center, designed to sit
/// between two vertically-stacked move cards in the Set Builder.
///
/// ```
///  [ Move A ]
///     |
///     * (colored dot)
///     |
///  [ Move B ]
/// ```
class AuraTransitionArrow extends ConsumerWidget {
  const AuraTransitionArrow({
    super.key,
    required this.fromMoveId,
    required this.toMoveId,
    this.height = 32,
  });

  final String fromMoveId;
  final String toMoveId;
  final double height;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final affinityAsync = ref.watch(
      auraAffinityProvider((fromId: fromMoveId, toId: toMoveId)),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return affinityAsync.when(
      loading: () => _buildArrow(context, colorScheme.secondary.withValues(alpha: 0.35)),
      error: (_, _) => _buildArrow(context, colorScheme.secondary.withValues(alpha: 0.35)),
      data: (final affinityString) {
        final affinity = affinityString != null
            ? AuraAffinity.fromString(affinityString)
            : null;
        final color = affinity?.color(context) ??
            colorScheme.secondary.withValues(alpha: 0.35);
        return _buildArrow(context, color);
      },
    );
  }

  Widget _buildArrow(final BuildContext context, final Color dotColor) {
    final lineColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return SizedBox(
      height: height,
      width: 20,
      child: Column(
        children: [
          // Top line segment
          Expanded(
            child: Container(width: 1.5, color: lineColor),
          ),
          // Center dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.25),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Bottom line segment
          Expanded(
            child: Container(width: 1.5, color: lineColor),
          ),
        ],
      ),
    );
  }
}
