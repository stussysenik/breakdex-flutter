import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/services/categories_service.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/wip_badge.dart';
import 'providers/flow_graph_providers.dart';
import 'widgets/flow_coach_marks.dart';
import 'widgets/flow_graph_canvas.dart';

/// Root screen for the Flow tab — move transition mapping.
///
/// The graph already exposes rich interactions in-canvas; this screen adds
/// enough structure around it to explain the current mode, the current scope,
/// and the currently selected move without burying the graph itself.
class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewMode = ref.watch(flowViewModeProvider);
    final graphSummary = ref.watch(flowGraphSummaryProvider);
    final selectedDetails = ref.watch(selectedFlowNodeDetailsProvider);
    final categories = ref.watch(categoriesProvider);
    final categoryColors = {
      for (final category in categories) category.name: category.color,
    };
    final modeDescription = _FlowModeDescription.forMode(viewMode);

    return Scaffold(
      body: CoachMarkTrigger(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdge,
                  AppSpacing.md,
                  AppSpacing.screenEdge,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Flow',
                                style: AppTypography.titleLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const WipBadge(compact: true),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'WIP: use this to inspect connections and weak bridges, but expect the interaction model to keep tightening.',
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
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: AppSegmentedControl<FlowViewMode>(
                  items: const [
                    AppSegmentedControlItem(
                      value: FlowViewMode.map,
                      icon: CupertinoIcons.graph_square_fill,
                      label: 'Map',
                    ),
                    AppSegmentedControlItem(
                      value: FlowViewMode.focus,
                      icon: CupertinoIcons.scope,
                      label: 'Focus',
                    ),
                    AppSegmentedControlItem(
                      value: FlowViewMode.clusters,
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      label: 'Zones',
                    ),
                  ],
                  selectedValue: viewMode,
                  onChanged: (mode) {
                    HapticFeedback.selectionClick();
                    ref.read(flowViewModeProvider.notifier).state = mode;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: _FlowModePanel(
                  description: modeDescription,
                  summary: graphSummary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                  ),
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
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DecoratedBox(
                    decoration: _panelDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: const FlowGraphCanvas(),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height:
                    kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowModeDescription {
  const _FlowModeDescription({
    required this.icon,
    required this.title,
    required this.description,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String description;
  final String hint;

  static _FlowModeDescription forMode(FlowViewMode mode) => switch (mode) {
    FlowViewMode.map => const _FlowModeDescription(
      icon: CupertinoIcons.graph_square_fill,
      title: 'Whole practice network',
      description:
          'See every move and transition together so gaps and hubs are obvious.',
      hint: 'Tap a node to inspect it. Double-tap opens move detail.',
    ),
    FlowViewMode.focus => const _FlowModeDescription(
      icon: CupertinoIcons.scope,
      title: 'One-move inspection',
      description:
          'Center on one move and its immediate routes to plan a dedicated sprint.',
      hint: 'Best for checking entries, exits, and weak follow-ups.',
    ),
    FlowViewMode.clusters => const _FlowModeDescription(
      icon: CupertinoIcons.square_grid_2x2_fill,
      title: 'Category zones',
      description:
          'Group moves by category to see which families bridge and which stay isolated.',
      hint: 'Use this view to spot cross-category compatibility gaps.',
    ),
  };
}

class _FlowModePanel extends StatelessWidget {
  const _FlowModePanel({required this.description, required this.summary});

  final _FlowModeDescription description;
  final FlowGraphSummary summary;

  @override
  Widget build(BuildContext context) {
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
                child: Icon(
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
                icon: CupertinoIcons.circle_grid_3x3_fill,
                label: 'Moves',
                value: '${summary.nodeCount}',
              ),
              _MetricChip(
                icon: CupertinoIcons.arrow_branch,
                label: 'Links',
                value: '${summary.edgeCount}',
              ),
              _MetricChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Mastered',
                value: '${summary.masteredCount}',
              ),
              _MetricChip(
                icon: CupertinoIcons.square_grid_2x2_fill,
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
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
                icon: Icons.close_rounded,
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
                icon: Icons.call_received_rounded,
                label: 'In',
                value: '${details.incomingCount}',
              ),
              _MetricChip(
                icon: Icons.call_made_rounded,
                label: 'Out',
                value: '${details.outgoingCount}',
              ),
              _MetricChip(
                icon: Icons.hub_outlined,
                label: 'Routes',
                value: '${details.neighborCount}',
              ),
              _MetricChip(
                icon: Icons.compare_arrows_rounded,
                label: 'Cross-zone',
                value: '${details.crossCategoryCount}',
              ),
              _MetricChip(
                icon: Icons.trending_flat_rounded,
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
                icon: CupertinoIcons.scope,
                label: isFocusMode ? 'Focused' : 'Focus move',
                onTap: isFocusMode ? null : onFocus,
              ),
              _TextActionChip(
                icon: Icons.open_in_new_rounded,
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = highlight ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  Widget build(BuildContext context) {
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

BoxDecoration _panelDecoration(BuildContext context, {Color? highlight}) {
  final colorScheme = Theme.of(context).colorScheme;
  final borderColor = (highlight ?? colorScheme.outline).withValues(
    alpha: highlight == null ? 0.18 : 0.24,
  );

  return BoxDecoration(
    color: highlight == null
        ? colorScheme.surface
        : highlight.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: borderColor),
  );
}

BoxDecoration _chipDecoration(BuildContext context, {Color? highlight}) {
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
