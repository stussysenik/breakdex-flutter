// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/shared/widgets/app_segmented_control.dart';
import 'package:breakdex/shared/widgets/wip_badge.dart';
import 'package:breakdex/features/flow/providers/flow_graph_providers.dart';
import 'package:breakdex/features/flow/widgets/flow_coach_marks.dart';
import 'package:breakdex/features/flow/widgets/flow_graph_canvas.dart';

/// Root screen for the Flow tab — move transition mapping.
///
/// The graph already exposes rich interactions in-canvas; this screen adds
/// enough structure around it to explain the current mode, the current scope,
/// and the currently selected move without burying the graph itself.
class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewMode = ref.watch(flowViewModeProvider);
    final graphSummary = ref.watch(flowGraphSummaryProvider);
    final selectedDetails = ref.watch(selectedFlowNodeDetailsProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryColors = {
      for (final category in categories) category.name: category.color,
    };
    final modeDescription = _FlowModeDescription.forMode(viewMode);

    // Flow does not scroll: the graph canvas takes whatever height is left and
    // pans inside itself. `SliverFillRemaining` gives the content band exactly
    // one viewport, so the column can still use Expanded — and the frame's
    // bottom inset replaces the hand-rolled nav-band spacer this screen carried.
    return AppScreen.slivers(
      title: 'Flow',
      actions: const [WipBadge(compact: true)],
      slivers: [
        SliverFillRemaining(
          child: CoachMarkTrigger(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WIP: use this to inspect connections and weak bridges, but expect the interaction model to keep tightening.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppLayout.itemGap),
                AppSegmentedControl<FlowViewMode>(
                  items: [
                    AppSegmentedControlItem(
                      value: FlowViewMode.map,
                      icon: AppIcon.graph.resolve(context),
                      label: 'Map',
                    ),
                    AppSegmentedControlItem(
                      value: FlowViewMode.focus,
                      icon: AppIcon.insight.resolve(context),
                      label: 'Focus',
                    ),
                    AppSegmentedControlItem(
                      value: FlowViewMode.clusters,
                      icon: AppIcon.grid.resolve(context),
                      label: 'Zones',
                    ),
                  ],
                  selectedValue: viewMode,
                  onChanged: (final mode) {
                    HapticFeedback.selectionClick();
                    ref.read(flowViewModeProvider.notifier).state = mode;
                  },
                ),
                const SizedBox(height: AppLayout.itemGap),
                _FlowModePanel(
                  description: modeDescription,
                  summary: graphSummary,
                ),
                const SizedBox(height: AppLayout.itemGap),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    primary: false,
                    child: AnimatedSwitcher(
                      duration: AppMotion.moderate02,
                      switchInCurve: AppMotion.entrance,
                      switchOutCurve: AppMotion.productive,
                      child: selectedDetails == null
                          ? _FlowGuidePanel(
                              key: const ValueKey('flow-guide'),
                              summary: graphSummary,
                            )
                          : _FlowSelectionInspector(
                              key: ValueKey(selectedDetails.node.id),
                              details: selectedDetails,
                              categoryColor:
                                  categoryColors[selectedDetails
                                      .node
                                      .category] ??
                                  colorScheme.primary,
                              isFocusMode: viewMode == FlowViewMode.focus,
                              onFocus: () {
                                ref.read(flowViewModeProvider.notifier).state =
                                    FlowViewMode.focus;
                              },
                              onOpen: () => context.push(
                                '/flow/move/${selectedDetails.node.id}',
                              ),
                              onClear: () {
                                if (viewMode == FlowViewMode.focus) {
                                  ref
                                          .read(flowViewModeProvider.notifier)
                                          .state =
                                      FlowViewMode.map;
                                }
                                ref.read(selectedNodeProvider.notifier).state =
                                    null;
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.itemGap),
                // The canvas sits on the frame's gutter like everything else;
                // the hairline inset is the panel's own border width, which is
                // why the two are the same constant rather than a loose `1`.
                Expanded(
                  child: DecoratedBox(
                    decoration: _panelDecoration(context),
                    child: const Padding(
                      padding: EdgeInsets.all(_panelBorderWidth),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.md),
                        ),
                        child: FlowGraphCanvas(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Width of the hairline border every flow panel draws. The canvas insets by
/// exactly this so the graph never paints over its own frame.
const double _panelBorderWidth = 1;

class _FlowModeDescription {
  const _FlowModeDescription({
    required this.icon,
    required this.title,
    required this.description,
    required this.hint,
  });

  final AppIcon icon;
  final String title;
  final String description;
  final String hint;

  static _FlowModeDescription forMode(
    final FlowViewMode mode,
  ) => switch (mode) {
    FlowViewMode.map => const _FlowModeDescription(
      icon: AppIcon.graph,
      title: 'Whole practice network',
      description:
          'See every move and transition together so gaps and hubs are obvious.',
      hint: 'Tap a node to inspect it. Double-tap opens move detail.',
    ),
    FlowViewMode.focus => const _FlowModeDescription(
      icon: AppIcon.insight,
      title: 'One-move inspection',
      description:
          'Center on one move and its immediate routes to plan a dedicated sprint.',
      hint: 'Best for checking entries, exits, and weak follow-ups.',
    ),
    FlowViewMode.clusters => const _FlowModeDescription(
      icon: AppIcon.grid,
      title: 'Category zones',
      description:
          'Group moves by category to see which families bridge and which stay isolated.',
      hint: 'Use this view to spot cross-category compatibility gaps.',
    ),
  };
}

class _FlowModePanel extends ConsumerWidget {
  const _FlowModePanel({required this.description, required this.summary});

  final _FlowModeDescription description;
  final FlowGraphSummary summary;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: _chipDecoration(
                  context,
                  highlight: colorScheme.primary,
                ),
                child: AppIconView(
                  description.icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.secondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricChip(
                icon: AppIcon.grid.resolve(context),
                label: ref.watch(entityNamesProvider).movePlural,
                value: '${summary.nodeCount}',
              ),
              _MetricChip(
                icon: AppIcon.link.resolve(context),
                label: 'Links',
                value: '${summary.edgeCount}',
              ),
              _MetricChip(
                icon: AppIcon.success.resolve(context),
                label: 'Mastered',
                value: '${summary.masteredCount}',
              ),
              _MetricChip(
                icon: AppIcon.grid.resolve(context),
                label: 'Zones',
                value: '${summary.categoryCount}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description.hint,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowGuidePanel extends StatelessWidget {
  const _FlowGuidePanel({super.key, required this.summary});

  final FlowGraphSummary summary;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moves are graphable now. Combo and set equations come next.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap a move to inspect routes. Long-press multiple moves to build a set directly from the graph.',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const _StatusChip(label: 'Moves live', highlighted: true),
              const _StatusChip(label: 'Combos next'),
              const _StatusChip(label: 'Sets next'),
              _StatusChip(label: '${summary.isolatedCount} unlinked'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowSelectionInspector extends StatelessWidget {
  const _FlowSelectionInspector({
    super.key,
    required this.details,
    required this.categoryColor,
    required this.isFocusMode,
    required this.onFocus,
    required this.onOpen,
    required this.onClear,
  });

  final SelectedFlowNodeDetails details;
  final Color categoryColor;
  final bool isFocusMode;
  final VoidCallback onFocus;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);
    final masteryColor = switch (details.node.masteryState) {
      2 => semanticTheme.stateMastery,
      1 => semanticTheme.stateLearning,
      _ => semanticTheme.stateNew,
    };
    final neighborPreview = details.neighborNames.take(4).join(' • ');
    final overflowCount = details.neighborNames.length > 4
        ? details.neighborNames.length - 4
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(context, highlight: categoryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.node.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _StatusChip(
                          label: details.node.category,
                          highlight: categoryColor,
                        ),
                        _StatusChip(
                          label: details.masteryLabel,
                          highlight: masteryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _IconActionButton(
                icon: AppIcon.close.resolve(context),
                label: 'Clear selection',
                onTap: onClear,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricChip(
                icon: AppIcon.down.resolve(context),
                label: 'In',
                value: '${details.incomingCount}',
              ),
              _MetricChip(
                icon: AppIcon.up.resolve(context),
                label: 'Out',
                value: '${details.outgoingCount}',
              ),
              _MetricChip(
                icon: AppIcon.discover.resolve(context),
                label: 'Routes',
                value: '${details.neighborCount}',
              ),
              _MetricChip(
                icon: AppIcon.sync.resolve(context),
                label: 'Cross-zone',
                value: '${details.crossCategoryCount}',
              ),
              _MetricChip(
                icon: AppIcon.forward.resolve(context),
                label: 'Natural',
                value: '${details.naturalTransitionCount}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TextActionChip(
                icon: AppIcon.insight.resolve(context),
                label: isFocusMode ? 'Focused' : 'Focus move',
                onTap: isFocusMode ? null : onFocus,
              ),
              _TextActionChip(
                icon: AppIcon.link.resolve(context),
                label: 'Open detail',
                onTap: onOpen,
              ),
            ],
          ),
          if (neighborPreview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              overflowCount > 0
                  ? 'Connects with $neighborPreview +$overflowCount more'
                  : 'Connects with $neighborPreview',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _chipDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.highlighted = false,
    this.highlight,
  });

  final String label;
  final bool highlighted;
  final Color? highlight;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = highlight ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _chipDecoration(
        context,
        highlight: highlighted || highlight != null ? tone : null,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: highlighted || highlight != null
              ? tone
              : colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TextActionChip extends StatelessWidget {
  const _TextActionChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: _chipDecoration(
              context,
              highlight: isEnabled ? colorScheme.primary : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isEnabled
                      ? colorScheme.primary
                      : colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isEnabled
                        ? colorScheme.primary
                        : colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: 34,
            height: 34,
            decoration: _chipDecoration(context),
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration(
  final BuildContext context, {
  final Color? highlight,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final borderColor = (highlight ?? colorScheme.outline).withValues(
    alpha: highlight == null ? 0.18 : 0.24,
  );

  return BoxDecoration(
    color: highlight == null
        ? colorScheme.surface
        : highlight.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: borderColor, width: _panelBorderWidth),
  );
}

BoxDecoration _chipDecoration(
  final BuildContext context, {
  final Color? highlight,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final borderColor = (highlight ?? colorScheme.outline).withValues(
    alpha: highlight == null ? 0.16 : 0.22,
  );

  return BoxDecoration(
    color: highlight == null
        ? colorScheme.surface
        : highlight.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: borderColor),
  );
}
