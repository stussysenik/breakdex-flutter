// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';

class BeatGridItem {
  const BeatGridItem({
    required this.label,
    required this.count,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;
}

/// Proportional beat timeline for a combo: one block per move, width
/// proportional to its beat count, with a per-beat tick row underneath that
/// shares the blocks' flex space so ticks align with block boundaries at any
/// width. Every 4th beat is emphasized (breaking is counted in 4s).
class BeatGrid extends StatelessWidget {
  const BeatGrid({super.key, required this.items, this.showSummary = true});

  final List<BeatGridItem> items;
  final bool showSummary;

  int get _total => items.fold(0, (final sum, final item) => sum + item.count);

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = _total;
    if (items.isEmpty || total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BEAT GRID',
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$total BEATS',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Proportional beat blocks
        SizedBox(
          height: 48,
          child: Row(
            children: [for (final item in items) _BeatBlock(item: item)],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // Per-beat ticks — same flex space as the blocks, so boundaries align.
        _TickRow(total: total, colorScheme: colorScheme),
        if (showSummary) ...[
          const SizedBox(height: AppSpacing.xs),
          // FittedBox: shrinks (never grows) so the summary can't overflow
          // at narrow widths.
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${items.length} move${items.length == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '·',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$total beat${total == 1 ? '' : 's'} total',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TickRow extends StatelessWidget {
  const _TickRow({required this.total, required this.colorScheme});

  final int total;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    // Beat numbers only under emphasized ticks (1, 5, 9, …) and only when
    // there's room — past 32 beats the labels would collide.
    final showNumbers = total <= 32;

    return SizedBox(
      height: showNumbers ? 18 : 6,
      child: Row(
        children: [
          for (int beat = 0; beat < total; beat++)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 1,
                    height: beat % 4 == 0 ? 6 : 3,
                    color: beat % 4 == 0
                        ? colorScheme.secondary.withValues(alpha: 0.7)
                        : colorScheme.outline.withValues(alpha: 0.35),
                  ),
                  if (showNumbers && beat % 4 == 0)
                    Text(
                      '${beat + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.secondary.withValues(alpha: 0.7),
                        fontSize: 9,
                        height: 1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BeatBlock extends StatelessWidget {
  const _BeatBlock({required this.item});

  final BeatGridItem item;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: item.count,
      child: Semantics(
        label: '${item.label}, ${item.count} beats',
        button: item.onTap != null,
        selected: item.isActive,
        child: GestureDetector(
          onTap: item.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  item.onTap!.call();
                },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.fast02,
            curve: AppMotion.entrance,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: item.isActive
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
              border: item.isActive
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
            ),
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                // Narrow blocks keep the count and drop the name — never
                // shrink text below the legibility floor to make it fit.
                final showLabel = constraints.maxWidth >= 44;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item.count}',
                      style: AppTypography.caption.copyWith(
                        color: item.isActive
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (showLabel) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: item.isActive
                              ? colorScheme.onPrimary.withValues(alpha: 0.85)
                              : colorScheme.secondary,
                          fontSize: 10,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
