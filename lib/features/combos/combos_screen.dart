import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/daos/combo_plans_dao.dart';
import '../../core/database/daos/combos_dao.dart';
import '../../core/database/database.dart' show ComboPlansCompanion;
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../combo_detail/widgets/status_tag.dart';
import 'plan_combo_flow.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _libraryRowsProvider = StreamProvider<List<LibraryRow>>((final ref) {
  return ref.watch(combosDaoProvider).watchLibraryRows();
});

final _plansQueueProvider = StreamProvider<List<PlanWithCombo>>((final ref) {
  return ref.watch(comboPlansDaoProvider).watchPlansQueue();
});

final _activityRollupProvider = StreamProvider<List<DayActivity>>((final ref) {
  return ref.watch(combosDaoProvider).watchActivityRollup();
});

final _planCountByDayProvider = StreamProvider<List<(DateTime, int)>>((final ref) {
  return ref.watch(combosDaoProvider).watchPlanCountByDay();
});

final _progressStripProvider = StreamProvider<(int, int, int)>((final ref) {
  return ref.watch(combosDaoProvider).watchProgressStrip();
});

// ---------------------------------------------------------------------------
// CombosScreen — tab host
// ---------------------------------------------------------------------------

class CombosScreen extends ConsumerStatefulWidget {
  const CombosScreen({super.key});

  @override
  ConsumerState<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends ConsumerState<CombosScreen> {
  int _tabIndex = 0;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
              vertical: AppSpacing.sm,
            ),
            child: AppSegmentedControl<int>(
              // No icons: three segments + icons truncate the labels on
              // phone widths ("Planne…").
              items: const [
                AppSegmentedControlItem(value: 0, label: 'Library'),
                AppSegmentedControlItem(value: 1, label: 'Planned'),
                AppSegmentedControlItem(value: 2, label: 'Calendar'),
              ],
              selectedValue: _tabIndex,
              onChanged: (final v) {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _tabIndex = v);
              },
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          ComboLibraryView(),
          ComboPlannedView(),
          ComboCalendarView(),
        ],
      ),
      // The + button is the single entry point for adding on each tab:
      // Library → create a combo, Planned → plan a combo. (Calendar plans
      // per-day via its own inline affordance.)
      floatingActionButton: _tabIndex == 2
          ? null
          // Lift above the shell's bottom nav (house pattern, see
          // move_list_screen) — otherwise the FAB renders behind it.
          : Padding(
              padding: EdgeInsets.only(
                bottom: kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom +
                    AppSpacing.sm,
              ),
              child: Semantics(
                identifier: 'combos-fab',
                button: true,
                label: _tabIndex == 1 ? 'Plan a combo' : 'Create combo',
                child: FloatingActionButton(
                  tooltip: _tabIndex == 1 ? 'Plan a combo' : 'Create combo',
                  onPressed: () async {
                    if (_tabIndex == 1) {
                      await planComboFlow(context, ref);
                    } else {
                      await context.push('/create-combo');
                    }
                  },
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Library View — month-grouped, stream-driven
// ---------------------------------------------------------------------------

class ComboLibraryView extends ConsumerWidget {
  const ComboLibraryView({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final rowsAsync = ref.watch(_libraryRowsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return rowsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (final e, _) => Center(
        child: Text('Error loading combos', style: TextStyle(color: colorScheme.error)),
      ),
      data: (final rows) {
        if (rows.isEmpty) return _LibraryEmptyState(colorScheme: colorScheme);

        final grouped = <String, List<LibraryRow>>{};
        for (final row in rows) {
          final monthKey = DateFormat('MMMM yyyy').format(row.combo.createdAt).toUpperCase();
          grouped.putIfAbsent(monthKey, () => []).add(row);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            80,
          ),
          itemCount: grouped.length,
          itemBuilder: (final context, final sectionIndex) {
            final entry = grouped.entries.elementAt(sectionIndex);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    'CREATED IN ${entry.key}',
                    style: AppTypography.sectionHeader.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
                ...entry.value.map(
                  (final row) => _LibraryRow(
                    row: row,
                    colorScheme: colorScheme,
                    onTap: () => context.push('/breakdex/combo/${row.combo.id}'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        );
      },
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.row,
    required this.colorScheme,
    required this.onTap,
  });

  final LibraryRow row;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final style = statusStyle(row.combo.status);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
        child: Row(
          children: [
            // Leading bar
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color: style.dashed ? colorScheme.outline : style.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.combo.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (row.transitionChain.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      row.transitionChain,
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Text(
                        '${row.moveCount} moves',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      if (row.jotCount > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '· ${row.jotCount} jots',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                      if (row.lastEntryAt != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '· ${relativeTime(row.lastEntryAt!)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatusBadge(
              status: row.combo.status,
              style: style,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.style,
    required this.colorScheme,
  });

  final String status;
  final ({Color color, bool filled, bool dashed}) style;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    final borderColor = style.dashed ? colorScheme.outline : style.color;
    final textColor = style.filled ? Colors.white : (style.dashed ? colorScheme.secondary : style.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: style.filled ? style.color : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xxs),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: colorScheme.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No combos yet',
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chain moves together into sequences.\nTap + to create your first combo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Planned View — progress strip + numbered queue + reorder
// ---------------------------------------------------------------------------

class ComboPlannedView extends ConsumerStatefulWidget {
  const ComboPlannedView({super.key});

  @override
  ConsumerState<ComboPlannedView> createState() => _ComboPlannedViewState();
}

class _ComboPlannedViewState extends ConsumerState<ComboPlannedView> {
  @override
  Widget build(final BuildContext context) {
    final plansAsync = ref.watch(_plansQueueProvider);
    final progressAsync = ref.watch(_progressStripProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final plans = plansAsync.valueOrNull ?? const <PlanWithCombo>[];
    final progress = progressAsync.valueOrNull ?? (0, 0, 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.sm,
        AppSpacing.screenEdge,
        80,
      ),
      children: [
        _ProgressStrip(
          landed: progress.$1,
          practiced: progress.$2,
          totalPlans: progress.$3,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (plans.isEmpty)
          Center(
            child: Text(
              'No plans yet — tap + to plan a combo',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ..._buildQueue(plans, colorScheme),
      ],
    );
  }

  List<Widget> _buildQueue(final List<PlanWithCombo> plans, final ColorScheme colorScheme) {
    return [
      Text(
        'QUEUE',
        style: AppTypography.sectionHeader.copyWith(color: colorScheme.secondary),
      ),
      const SizedBox(height: AppSpacing.sm),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: plans.length,
        onReorder: (final oldIndex, final newIndex) async {
          // Reassign all positions sequentially after the move.
          final dao = ref.read(comboPlansDaoProvider);
          final reordered = List<PlanWithCombo>.from(plans);
          final item = reordered.removeAt(oldIndex);
          final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
          reordered.insert(insertAt, item);
          for (var i = 0; i < reordered.length; i++) {
            await dao.updatePosition(reordered[i].plan.id, i);
          }
        },
        itemBuilder: (final context, final index) {
          final pw = plans[index];
          final planDate = DateFormat('MMM d').format(pw.plan.planDate);
          final completed = pw.plan.completedAt != null;

          return Dismissible(
            key: ValueKey(pw.plan.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removePlan(pw),
            background: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.delete_outline, color: colorScheme.error),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
              child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: completed ? colorScheme.onPrimary : colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                pw.combo.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Planned $planDate${completed ? ' — completed' : ''}',
                style: AppTypography.caption.copyWith(
                  color: completed
                      ? colorScheme.primary
                      : colorScheme.secondary,
                ),
              ),
              onTap: () => context.push('/breakdex/combo/${pw.combo.id}'),
              trailing: completed
                  ? Icon(Icons.check_circle, color: colorScheme.primary, size: 20)
                  : null,
              ),
            ),
          );
        },
      ),
    ];
  }

  /// Removes a plan from the queue with an UNDO affordance — a plan is a
  /// lightweight scheduling entry, so removal stays reversible and the
  /// dancer is never stuck with a queue they can't clear.
  Future<void> _removePlan(final PlanWithCombo pw) async {
    final dao = ref.read(comboPlansDaoProvider);
    await dao.deletePlan(pw.plan.id);
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${pw.combo.name}" from queue'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(dao.insertPlan(
            ComboPlansCompanion.insert(
              id: pw.plan.id,
              comboId: pw.plan.comboId,
              planDate: pw.plan.planDate,
              position: Value(pw.plan.position),
              completedAt: Value(pw.plan.completedAt),
            ),
          )),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.landed,
    required this.practiced,
    required this.totalPlans,
    required this.colorScheme,
  });

  final int landed;
  final int practiced;
  final int totalPlans;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(context, radius: AppRadius.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Landed', value: '$landed', colorScheme: colorScheme),
          _Stat(label: 'Practiced', value: '$practiced', colorScheme: colorScheme),
          _Stat(label: 'Plans', value: '$totalPlans', colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan picker sheet
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Calendar View — past heat + future plan dots
// ---------------------------------------------------------------------------

class ComboCalendarView extends ConsumerStatefulWidget {
  const ComboCalendarView({super.key});

  @override
  ConsumerState<ComboCalendarView> createState() => _ComboCalendarViewState();
}

class _ComboCalendarViewState extends ConsumerState<ComboCalendarView> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(final BuildContext context) {
    final activityAsync = ref.watch(_activityRollupProvider);
    final planCountAsync = ref.watch(_planCountByDayProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activities = activityAsync.valueOrNull ?? const <DayActivity>[];
    final planCounts = planCountAsync.valueOrNull ?? const <(DateTime, int)>[];

    final activityMap = {for (final a in activities) DateFormat('yyyy-MM-dd').format(a.day): a};
    final planMap = {for (final p in planCounts) DateFormat('yyyy-MM-dd').format(p.$1): p.$2};
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      children: [
        // Month header with navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              }),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Day-of-week headers
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((final d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Calendar grid
        _buildCalendarGrid(
          activityMap,
          planMap,
          today,
          colorScheme,
          context,
        ),
        const SizedBox(height: AppSpacing.sm),
        _CalendarLegend(colorScheme: colorScheme),
        const SizedBox(height: AppSpacing.lg),
        // Day detail section
        if (_selectedDate != null) ...[
          Divider(color: colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          _DayDetail(
            date: _selectedDate!,
            colorScheme: colorScheme,
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  DateTime? _selectedDate;

  Widget _buildCalendarGrid(
    final Map<String, DayActivity> activityMap,
    final Map<String, int> planMap,
    final String today,
    final ColorScheme colorScheme,
    final BuildContext context,
  ) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // Sunday = 0

    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final activity = activityMap[dateKey];
      final planCount = planMap[dateKey] ?? 0;
      final isToday = dateKey == today;
      final isFuture = date.isAfter(DateTime.now());
      final isSelected = _selectedDate != null &&
          DateFormat('yyyy-MM-dd').format(_selectedDate!) == dateKey;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dayColor(activity, colorScheme),
              border: isToday
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : isSelected
                      ? Border.all(color: colorScheme.onSurface, width: 1.5)
                      : planCount > 0
                          ? Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.55),
                            )
                          : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: AppTypography.bodySmall.copyWith(
                    color: _dayTextColor(activity, isFuture, colorScheme),
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                // Plan dots — up to 3, one per pending plan on this day.
                SizedBox(
                  height: 5,
                  child: planCount > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var d = 0; d < planCount.clamp(1, 3); d++)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Pad to complete last week
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: cells.sublist(i, min(i + 7, cells.length)).map((final cell) {
            return Expanded(child: AspectRatio(aspectRatio: 1, child: cell));
          }).toList(),
        ),
      );
    }

    return Column(children: rows);
  }

  Color _dayColor(
    final DayActivity? activity,
    final ColorScheme colorScheme,
  ) {
    if (activity != null) {
      final intensity = (activity.jotCount + activity.takeCount).clamp(0, 5);
      return colorScheme.primary.withValues(alpha: 0.1 + (intensity * 0.15));
    }
    return Colors.transparent;
  }

  Color _dayTextColor(
    final DayActivity? activity,
    final bool isFuture,
    final ColorScheme colorScheme,
  ) {
    if (activity != null) return colorScheme.primary;
    if (isFuture) return colorScheme.secondary.withValues(alpha: 0.4);
    return colorScheme.onSurface;
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    Widget item(final Widget swatch, final String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch,
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: colorScheme.secondary),
          ),
        ],
      );
    }

    Widget circle({final Color? fill, final Border? border}) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: border),
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.center,
      children: [
        item(circle(fill: colorScheme.primary.withValues(alpha: 0.4)), 'practiced'),
        item(
          circle(border: Border.all(color: colorScheme.primary.withValues(alpha: 0.55))),
          'planned',
        ),
        item(circle(border: Border.all(color: colorScheme.primary, width: 2)), 'today'),
      ],
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date, required this.colorScheme});

  final DateTime date;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final plansAsync = ref.watch(plansForDateProvider(date));
    final isFuture = date.isAfter(DateTime.now());
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final plans = plansAsync.valueOrNull ?? const <PlanWithCombo>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(date),
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isFuture || isToday)
          TextButton.icon(
            onPressed: () => planComboFlow(context, ref, presetDate: date),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Plan a combo'),
          ),
        if (plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              isFuture ? 'Nothing planned for this day.' : 'No activity recorded.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ...plans.map((final pw) => ListTile(
                dense: true,
                title: Text(
                  pw.combo.name,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                ),
                subtitle: pw.plan.completedAt != null
                    ? Text('Completed', style: TextStyle(color: colorScheme.primary, fontSize: 12))
                    : Text(pw.combo.status.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(color: colorScheme.secondary)),
                trailing: pw.plan.completedAt != null
                    ? Icon(Icons.check_circle, color: colorScheme.primary, size: 18)
                    : null,
                onTap: () => context.push('/breakdex/combo/${pw.combo.id}'),
              )),
      ],
    );
  }
}

final plansForDateProvider = StreamProvider.family<List<PlanWithCombo>, DateTime>(
  (final ref, final date) => ref.watch(comboPlansDaoProvider).watchPlansForDate(date),
);
