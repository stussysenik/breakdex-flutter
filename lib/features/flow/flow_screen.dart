import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/settings_gear_button.dart';
import 'providers/flow_graph_providers.dart';
import 'widgets/flow_coach_marks.dart';
import 'widgets/flow_graph_canvas.dart';

/// Root screen for the Flow tab — move transition mapping.
///
/// "Flow" is what breakers call it — the transitions between moves,
/// the way one move connects to the next. Features three view modes:
/// Map (force-directed constellation), Focus (ego graph), and Clusters
/// (category territory map). Filter by All/Moves/Combos/Sets.
class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(flowViewModeProvider);
    final filter = ref.watch(flowFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CoachMarkTrigger(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + gear
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenEdge,
                AppSpacing.md,
                AppSpacing.screenEdge,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flow',
                    style: AppTypography.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SettingsGearButton(),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Map | Focus | Clusters segment control
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: AppSegmentedControl<FlowViewMode>(
                items: const [
                  AppSegmentedControlItem(
                    value: FlowViewMode.map,
                    icon: Icons.bubble_chart_outlined,
                    label: 'Map',
                  ),
                  AppSegmentedControlItem(
                    value: FlowViewMode.focus,
                    icon: Icons.adjust_rounded,
                    label: 'Focus',
                  ),
                  AppSegmentedControlItem(
                    value: FlowViewMode.clusters,
                    icon: Icons.workspaces_outlined,
                    label: 'Clusters',
                  ),
                ],
                selectedValue: viewMode,
                onChanged: (mode) {
                  HapticFeedback.selectionClick();
                  ref.read(flowViewModeProvider.notifier).state = mode;
                },
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Filter chips: All | Moves | Combos | Sets — with node counts.
            Builder(builder: (context) {
              final graphData = ref.watch(flowGraphDataProvider);
              final nodeCount = graphData.nodes.length;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdge,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: FlowFilter.values.map((f) {
                    final isActive = f == filter;
                    // Currently all nodes are moves; combos/sets are future.
                    final count = switch (f) {
                      FlowFilter.all => nodeCount,
                      FlowFilter.moves => nodeCount,
                      FlowFilter.combos => 0,
                      FlowFilter.sets => 0,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(flowFilterProvider.notifier).state = f;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary
                                    .withValues(alpha: 0.06)
                                : colorScheme.surface
                                    .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.12)
                                  : colorScheme.outline
                                      .withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${f.name[0].toUpperCase()}${f.name.substring(1)} ($count)',
                            style: AppTypography.bodySmall.copyWith(
                              color: isActive
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.md),

            // Graph canvas — fills remaining space
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: FlowGraphCanvas(),
                ),
              ),
            ),

            // Bottom padding for tab bar
            SizedBox(
              height: kBottomNavigationBarHeight +
                  MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
        ),
      ),
    );
  }
}
