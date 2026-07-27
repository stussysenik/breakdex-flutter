// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';

/// Month x day activity matrix with explicit 01-31 headers.
///
/// Rows represent recent months, columns represent day numbers. Invalid
/// dates (for example February 30) are rendered as empty placeholders.
class HeatMapGrid extends ConsumerWidget {
  const HeatMapGrid({super.key, required this.dailyCounts});

  final Map<DateTime, int> dailyCounts;

  static const double _labelWidth = 74;
  static const double _cellSize = 24;
  static const double _gap = 4;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final months = List<DateTime>.generate(
      6,
      (final index) => DateTime(currentMonth.year, currentMonth.month - index),
    ).reversed.toList();
    final maxCount = dailyCounts.values.fold<int>(0, (final max, final value) {
      return value > max ? value : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Month x Day',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tap any day to inspect the exact reviews captured at that time.',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(colorScheme: colorScheme),
              const SizedBox(height: AppSpacing.sm),
              for (final month in months) ...[
                _MonthRow(
                  month: month,
                  dailyCounts: dailyCounts,
                  maxCount: maxCount > 0 ? maxCount : 1,
                  selectedDate: selectedDate,
                  onSelect: (final date) {
                    HapticFeedback.selectionClick();
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
                ),
                if (month != months.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            for (final level in [0.0, 0.25, 0.5, 0.75, 1.0])
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    colorScheme.surfaceContainerHighest,
                    colorScheme.primary,
                    level,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'More',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: HeatMapGrid._labelWidth,
          child: Text(
            'Month',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (int day = 1; day <= 31; day++) ...[
          Container(
            width: HeatMapGrid._cellSize,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: HeatMapGrid._gap),
            child: Text(
              day.toString().padLeft(2, '0'),
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.month,
    required this.dailyCounts,
    required this.maxCount,
    required this.selectedDate,
    required this.onSelect,
  });

  final DateTime month;
  final Map<DateTime, int> dailyCounts;
  final int maxCount;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Row(
      children: [
        SizedBox(
          width: HeatMapGrid._labelWidth,
          child: Text(
            '${_monthLabel(month.month)} ${month.year}',
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (int day = 1; day <= 31; day++) ...[
          _DayCell(
            date: day <= daysInMonth ? DateTime(month.year, month.month, day) : null,
            count: day <= daysInMonth
                ? dailyCounts[DateTime(month.year, month.month, day)] ?? 0
                : null,
            maxCount: maxCount,
            isSelected: day <= daysInMonth &&
                selectedDate.year == month.year &&
                selectedDate.month == month.month &&
                selectedDate.day == day,
            isToday: day <= daysInMonth &&
                DateTime(month.year, month.month, day) == todayDate,
            onTap: onSelect,
          ),
        ],
      ],
    );
  }

  String _monthLabel(final int month) => switch (month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    _ => 'Dec',
  };
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.count,
    required this.maxCount,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime? date;
  final int? count;
  final int maxCount;
  final bool isSelected;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = date != null;
    final intensity = enabled && (count ?? 0) > 0
        ? ((count ?? 0) / maxCount).clamp(0.12, 1.0)
        : 0.0;
    final background = !enabled
        ? Colors.transparent
        : Color.lerp(
            colorScheme.surfaceContainerHighest,
            colorScheme.primary,
            intensity,
          );

    return Container(
      width: HeatMapGrid._cellSize,
      height: HeatMapGrid._cellSize,
      margin: const EdgeInsets.only(right: HeatMapGrid._gap),
      child: enabled
          ? Material(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: InkWell(
                onTap: () => onTap(date!),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.onSurface
                          : isToday
                              ? colorScheme.primary.withValues(alpha: 0.7)
                              : Colors.transparent,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: (count ?? 0) > 0
                      ? Text(
                          count! > 9 ? '9+' : '$count',
                          style: AppTypography.caption.copyWith(
                            color: intensity > 0.5
                                ? Colors.white
                                : colorScheme.onSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
    );
  }
}
