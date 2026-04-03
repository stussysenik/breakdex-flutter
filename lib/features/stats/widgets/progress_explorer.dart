import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/services/native_share_sheet.dart';
import '../../../core/services/stats_export_service.dart';
import '../../../core/utils/share_sheet.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../../../shared/widgets/settings_gear_button.dart';
import '../../../shared/widgets/wip_badge.dart';
import '../providers/stats_providers.dart';
import 'heat_map_grid.dart';
import 'stat_card.dart';

class ProgressExplorer extends StatefulWidget {
  const ProgressExplorer({super.key, required this.stats});

  final StatsBundle stats;

  @override
  State<ProgressExplorer> createState() => _ProgressExplorerState();
}

enum _ProgressSubjectMode { moves, combos }

enum _ProgressStructureMode { tree, graph }

class _ProgressExplorerState extends State<ProgressExplorer> {
  _ProgressSubjectMode _subjectMode = _ProgressSubjectMode.moves;
  _ProgressStructureMode _structureMode = _ProgressStructureMode.tree;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _ProgressHeader(stats: stats)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.md,
            AppSpacing.screenEdge,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _ProgressStartCard(stats: stats, subjectMode: _subjectMode),
                const SizedBox(height: AppSpacing.md),
                _ExplorerControls(
                  subjectMode: _subjectMode,
                  structureMode: _structureMode,
                  onSubjectChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _subjectMode = value);
                  },
                  onStructureChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _structureMode = value);
                  },
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.md,
            AppSpacing.screenEdge,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeading(
              title: _subjectMode == _ProgressSubjectMode.moves
                  ? 'Move Parents'
                  : 'Combo Parents',
              subtitle: _structureMode == _ProgressStructureMode.tree
                  ? 'Start from the parent, then open the exact child you want to drill.'
                  : 'See the parent-child graph first, then jump into the right detail.',
            ),
          ),
        ),
        ..._buildParentSlivers(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _DeepSignalsPanel(stats: stats)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  List<Widget> _buildParentSlivers(BuildContext context) {
    if (_subjectMode == _ProgressSubjectMode.moves) {
      final groups = widget.stats.moveProgressGroups;
      if (groups.isEmpty) {
        return _emptyParentSlivers(
          title: 'No moves yet',
          subtitle:
              'Add moves to the Arsenal and their parent structure will appear here.',
        );
      }

      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.md,
            AppSpacing.screenEdge,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = groups[index];
              final card = _structureMode == _ProgressStructureMode.tree
                  ? _MoveTreeGroupCard(group: group)
                  : _MoveGraphGroupCard(group: group);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == groups.length - 1 ? 0 : AppSpacing.md,
                ),
                child: card,
              );
            }, childCount: groups.length),
          ),
        ),
      ];
    }

    final groups = widget.stats.comboProgressGroups;
    if (groups.isEmpty) {
      return _emptyParentSlivers(
        title: 'No combos yet',
        subtitle:
            'Create a combo and its parent path will appear here with the moves it depends on.',
      );
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.md,
          AppSpacing.screenEdge,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final group = groups[index];
            final card = _structureMode == _ProgressStructureMode.tree
                ? _ComboTreeCard(group: group)
                : _ComboGraphCard(group: group);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == groups.length - 1 ? 0 : AppSpacing.md,
              ),
              child: card,
            );
          }, childCount: groups.length),
        ),
      ),
    ];
  }

  List<Widget> _emptyParentSlivers({
    required String title,
    required String subtitle,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.md,
          AppSpacing.screenEdge,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: _EmptyParentCard(title: title, subtitle: subtitle),
        ),
      ),
    ];
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.stats});

  final StatsBundle stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Progress',
                      style: AppTypography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const WipBadge(compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Parent-first practice map.',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Row(
          children: [
            _ShareButton(stats: stats),
            const SizedBox(width: AppSpacing.sm),
            const SettingsGearButton(),
          ],
        ),
      ],
    );
  }
}

class _ProgressStartCard extends StatelessWidget {
  const _ProgressStartCard({required this.stats, required this.subjectMode});

  final StatsBundle stats;
  final _ProgressSubjectMode subjectMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final moveRecommendation = _recommendedMoveParent(stats);
    final comboRecommendation = _recommendedComboParent(stats);
    final highlight = subjectMode == _ProgressSubjectMode.moves
        ? moveRecommendation
        : comboRecommendation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.panel(
        context,
        raised: true,
        focused: true,
        radius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            highlight?.title ?? 'Build the parent map first',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            highlight?.subtitle ??
                'As you add moves and combos, this card will point to the next parent path to resume.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          if (highlight != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _MetaPill(label: highlight.reason),
                if (highlight.meta != null) _MetaPill(label: highlight.meta!),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QueueChip(
                label: 'Now',
                value: '${stats.dueSummary.totalDueNow}',
              ),
              _QueueChip(
                label: 'Today',
                value: '${stats.dueSummary.totalDueToday}',
              ),
              _QueueChip(
                label: 'Tomorrow',
                value: '${stats.dueSummary.dueTomorrow}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueChip extends StatelessWidget {
  const _QueueChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerControls extends StatelessWidget {
  const _ExplorerControls({
    required this.subjectMode,
    required this.structureMode,
    required this.onSubjectChanged,
    required this.onStructureChanged,
  });

  final _ProgressSubjectMode subjectMode;
  final _ProgressStructureMode structureMode;
  final ValueChanged<_ProgressSubjectMode> onSubjectChanged;
  final ValueChanged<_ProgressStructureMode> onStructureChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scope',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              const subjectItems = [
                AppSegmentedControlItem(
                  value: _ProgressSubjectMode.moves,
                  icon: Icons.sports_martial_arts_rounded,
                  label: 'Moves',
                ),
                AppSegmentedControlItem(
                  value: _ProgressSubjectMode.combos,
                  icon: Icons.linear_scale_rounded,
                  label: 'Combos',
                ),
              ];
              const structureItems = [
                AppSegmentedControlItem(
                  value: _ProgressStructureMode.tree,
                  icon: Icons.account_tree_outlined,
                  label: 'Tree',
                ),
                AppSegmentedControlItem(
                  value: _ProgressStructureMode.graph,
                  icon: Icons.hub_outlined,
                  label: 'Graph',
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    _ControlGroup<_ProgressSubjectMode>(
                      label: 'Track',
                      value: subjectMode,
                      items: subjectItems,
                      onChanged: onSubjectChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ControlGroup<_ProgressStructureMode>(
                      label: 'Read As',
                      value: structureMode,
                      items: structureItems,
                      onChanged: onStructureChanged,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ControlGroup<_ProgressSubjectMode>(
                      label: 'Track',
                      value: subjectMode,
                      items: subjectItems,
                      onChanged: onSubjectChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ControlGroup<_ProgressStructureMode>(
                      label: 'Read As',
                      value: structureMode,
                      items: structureItems,
                      onChanged: onStructureChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ControlGroup<T> extends StatelessWidget {
  const _ControlGroup({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<AppSegmentedControlItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppSegmentedControl<T>(
          items: items,
          selectedValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
        ),
      ],
    );
  }
}

class _MoveTreeGroupCard extends StatelessWidget {
  const _MoveTreeGroupCard({required this.group});

  final MoveProgressGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayCategoryName(group.category),
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${group.totalCount} moves · ${group.reviewedCount} reviewed · ${group.dueNowCount} ready now',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int index = 0; index < group.items.length; index++) ...[
            _MoveTreeRow(item: group.items[index]),
            if (index != group.items.length - 1)
              Divider(
                height: AppSpacing.md,
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }
}

class _MoveTreeRow extends StatelessWidget {
  const _MoveTreeRow({required this.item});

  final MoveProgressItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.push('/moves/move/${item.moveId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.moveName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      item.stateLabel,
                      item.reviewCount == 0
                          ? 'No reviews yet'
                          : '${item.reviewCount} reviews',
                      if (item.lastReviewedAt != null)
                        'Last ${DateFormat('MMM d').format(item.lastReviewedAt!.toLocal())}',
                    ].join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _MetaPill(
              label: _bucketLabel(item.dueBucket),
              accent: _dueBucketColor(context, item.dueBucket),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveGraphGroupCard extends StatelessWidget {
  const _MoveGraphGroupCard({required this.group});

  final MoveProgressGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_displayCategoryName(group.category)} graph',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${group.totalCount} child moves in a visual parent graph',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _ParentNode(
              label: _displayCategoryName(group.category),
              accent: colorScheme.primary,
              onTap: null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 2,
              height: 18,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in group.items)
                _ChildNode(
                  label: item.moveName,
                  accent: _dueBucketColor(context, item.dueBucket),
                  subtitle: item.statusLabel,
                  onTap: () => context.push('/moves/move/${item.moveId}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComboTreeCard extends StatelessWidget {
  const _ComboTreeCard({required this.group});

  final ComboProgressGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => context.push('/moves/combo/${group.comboId}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.comboName,
                    style: AppTypography.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      group.stateLabel,
                      group.statusLabel,
                      '${group.steps.length} steps',
                      if (group.reviewCount > 0) '${group.reviewCount} reviews',
                    ].join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int index = 0; index < group.steps.length; index++) ...[
            _ComboStepRow(
              step: group.steps[index],
              isLast: index == group.steps.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComboStepRow extends StatelessWidget {
  const _ComboStepRow({required this.step, required this.isLast});

  final ComboProgressStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.push('/moves/move/${step.moveId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${step.sequenceIndex + 1}',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.moveName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_displayCategoryName(step.category)} · ${step.stateLabel}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _MetaPill(
              label: _bucketLabel(step.dueBucket),
              accent: _dueBucketColor(context, step.dueBucket),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboGraphCard extends StatelessWidget {
  const _ComboGraphCard({required this.group});

  final ComboProgressGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.comboName,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Graph view for the combo parent and its step path.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ParentNode(
            label: group.comboName,
            accent: colorScheme.primary,
            onTap: () => context.push('/moves/combo/${group.comboId}'),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int index = 0; index < group.steps.length; index++) ...[
                  _StepNode(
                    index: group.steps[index].sequenceIndex + 1,
                    label: group.steps[index].moveName,
                    accent: _dueBucketColor(
                      context,
                      group.steps[index].dueBucket,
                    ),
                    onTap: () => context.push(
                      '/moves/move/${group.steps[index].moveId}',
                    ),
                  ),
                  if (index != group.steps.length - 1) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentNode extends StatelessWidget {
  const _ParentNode({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChildNode extends StatelessWidget {
  const _ChildNode({
    required this.label,
    required this.accent,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final int index;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: 136,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step $index',
              style: AppTypography.caption.copyWith(color: accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = accent ?? colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DeepSignalsPanel extends StatelessWidget {
  const _DeepSignalsPanel({required this.stats});

  final StatsBundle stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeDays = stats.dailyBreakdown
        .where((day) => day.reviewCount > 0)
        .length;

    return Container(
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          iconColor: colorScheme.secondary,
          collapsedIconColor: colorScheme.secondary,
          title: Text(
            'Superfan Analytics',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Optional deep metrics while Progress is still settling.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Streak',
                    value: '${stats.currentStreak}d',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(label: 'Active Days', value: '$activeDays'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatCard(
                    label: 'Review Events',
                    value: '${stats.reviewTimeline.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            HeatMapGrid(dailyCounts: stats.dailyCounts),
            if (stats.reviewTimeline.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recent Reactions',
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (
                int index = 0;
                index < stats.reviewTimeline.take(6).length;
                index++
              ) ...[
                _TimelineEntryTile(entry: stats.reviewTimeline[index]),
                if (index != stats.reviewTimeline.take(6).length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  const _TimelineEntryTile({required this.entry});

  final ReviewTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratingColor = switch (entry.rating) {
      'AGAIN' => AppColors.actionAgain,
      'HARD' => AppColors.actionHard,
      'GOOD' => AppColors.actionGood,
      'EASY' => AppColors.actionEasy,
      _ => colorScheme.secondary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: ratingColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.graduated
                      ? '${entry.rating} · graduated into review'
                      : '${entry.rating} · ${entry.entityType == 'combo' ? 'combo' : _displayCategoryName(entry.category)}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(entry.reviewedAt.toLocal()),
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyParentCard extends StatelessWidget {
  const _EmptyParentCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.panel(
        context,
        radius: AppRadius.md,
        raised: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationSummary {
  const _RecommendationSummary({
    required this.title,
    required this.subtitle,
    required this.reason,
    this.meta,
  });

  final String title;
  final String subtitle;
  final String reason;
  final String? meta;
}

_RecommendationSummary? _recommendedMoveParent(StatsBundle stats) {
  final ranked = <(MoveProgressGroup, MoveProgressItem)>[];
  for (final group in stats.moveProgressGroups) {
    for (final item in group.items) {
      ranked.add((group, item));
    }
  }
  if (ranked.isEmpty) return null;

  ranked.sort((a, b) {
    final dueCompare = _dueBucketPriority(
      a.$2.dueBucket,
    ).compareTo(_dueBucketPriority(b.$2.dueBucket));
    if (dueCompare != 0) return dueCompare;
    final reviewCompare = b.$2.reviewCount.compareTo(a.$2.reviewCount);
    if (reviewCompare != 0) return reviewCompare;
    final aTime = a.$2.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.$2.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  final group = ranked.first.$1;
  final item = ranked.first.$2;
  return _RecommendationSummary(
    title: _displayCategoryName(group.category),
    subtitle:
        'Start with ${item.moveName}. ${_moveResumeSubtitle(group, item)}',
    reason: _bucketReason(item.dueBucket),
    meta: '${item.stateLabel} · ${item.reviewCount} reviews',
  );
}

String _moveResumeSubtitle(MoveProgressGroup group, MoveProgressItem item) {
  return switch (item.dueBucket) {
    ProgressDueBucket.now =>
      '${group.dueNowCount} move${group.dueNowCount == 1 ? '' : 's'} ready now in this parent.',
    ProgressDueBucket.today =>
      '${group.dueTodayCount} move${group.dueTodayCount == 1 ? '' : 's'} up today in this parent.',
    ProgressDueBucket.tomorrow => 'This parent comes back tomorrow.',
    ProgressDueBucket.later => 'This parent looks stable for now.',
    ProgressDueBucket.unscheduled => 'This parent is still mostly unstarted.',
  };
}

_RecommendationSummary? _recommendedComboParent(StatsBundle stats) {
  final groups = [...stats.comboProgressGroups];
  if (groups.isEmpty) return null;

  groups.sort((a, b) {
    final dueCompare = _dueBucketPriority(
      a.dueBucket,
    ).compareTo(_dueBucketPriority(b.dueBucket));
    if (dueCompare != 0) return dueCompare;
    final reviewCompare = b.reviewCount.compareTo(a.reviewCount);
    if (reviewCompare != 0) return reviewCompare;
    final aTime = a.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.lastReviewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  final group = groups.first;
  ComboProgressStep? nextStep;
  for (final step in group.steps) {
    if (step.dueBucket == ProgressDueBucket.now) {
      nextStep = step;
      break;
    }
  }
  nextStep ??=
      group.steps
          .where((step) => step.dueBucket == ProgressDueBucket.today)
          .isNotEmpty
      ? group.steps
            .where((step) => step.dueBucket == ProgressDueBucket.today)
            .first
      : null;
  nextStep ??= group.steps.isEmpty ? null : group.steps.first;

  return _RecommendationSummary(
    title: group.comboName,
    subtitle: nextStep == null
        ? '${group.statusLabel}. Build the combo path first.'
        : 'Resume with ${nextStep.moveName}. ${group.steps.length} steps in this combo.',
    reason: _bucketReason(group.dueBucket),
    meta: '${group.stateLabel} · ${group.reviewCount} reviews',
  );
}

String _bucketReason(ProgressDueBucket bucket) => switch (bucket) {
  ProgressDueBucket.now => 'Best next move',
  ProgressDueBucket.today => 'Up today',
  ProgressDueBucket.tomorrow => 'Coming tomorrow',
  ProgressDueBucket.later => 'Stable for now',
  ProgressDueBucket.unscheduled => 'Still unstarted',
};

Color _dueBucketColor(BuildContext context, ProgressDueBucket bucket) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (bucket) {
    ProgressDueBucket.now => AppColors.actionAgain,
    ProgressDueBucket.today => AppColors.actionHard,
    ProgressDueBucket.tomorrow => AppColors.actionGood,
    ProgressDueBucket.later => colorScheme.secondary,
    ProgressDueBucket.unscheduled => colorScheme.secondary,
  };
}

int _dueBucketPriority(ProgressDueBucket bucket) => switch (bucket) {
  ProgressDueBucket.now => 0,
  ProgressDueBucket.today => 1,
  ProgressDueBucket.tomorrow => 2,
  ProgressDueBucket.later => 3,
  ProgressDueBucket.unscheduled => 4,
};

String _bucketLabel(ProgressDueBucket bucket) => switch (bucket) {
  ProgressDueBucket.now => 'Ready now',
  ProgressDueBucket.today => 'Today',
  ProgressDueBucket.tomorrow => 'Tomorrow',
  ProgressDueBucket.later => 'Later',
  ProgressDueBucket.unscheduled => 'Unscheduled',
};

String _displayCategoryName(String raw) {
  if (raw == 'default') return 'Unsorted';
  return raw
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.stats});

  final StatsBundle stats;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final summary = StatsExportService.generateTextSummary(widget.stats);
      final origin = sharePositionOrigin(context);
      await NativeShareSheet.shareText(
        text: summary,
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _sharing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share, size: 22),
      tooltip: 'Share progress',
      onPressed: _sharing ? null : _share,
    );
  }
}
