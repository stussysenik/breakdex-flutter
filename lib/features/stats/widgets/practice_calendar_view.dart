// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';

/// PracticeCalendarView — backward-looking calendar showing daily practice activity.
/// 
/// Shows a month grid where each day cell indicates the intensity of practice
/// (review count) for that day. 
/// Tap a day to select it and update the details view.
class PracticeCalendarView extends ConsumerStatefulWidget {
  const PracticeCalendarView({super.key});

  @override
  ConsumerState<PracticeCalendarView> createState() => _PracticeCalendarViewState();
}

class _PracticeCalendarViewState extends ConsumerState<PracticeCalendarView> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(statsBundleProvider);

    return statsAsync.when(
      loading: () => const SizedBox(height: 300, child: Center(child: AppLoader())),
      error: (final e, _) => Center(child: Text('Error: $e')),
      data: (final stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: colorScheme.onSurface,
                ),
                Text(
                  _formatMonth(_displayedMonth),
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Menlo',
                  ),
                ),
                IconButton(
                  onPressed: _goToNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: colorScheme.onSurface,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _WeekdayHeaders(colorScheme: colorScheme),
            const SizedBox(height: AppSpacing.xs),
            _MonthGrid(
              month: _displayedMonth,
              dailyCounts: stats.dailyCounts,
              onDayTap: (final date) {
                HapticFeedback.selectionClick();
                ref.read(selectedDateProvider.notifier).state = date;
              },
            ),
          ],
        );
      },
    );
  }

  String _formatMonth(final DateTime month) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }
}

class _WeekdayHeaders extends StatelessWidget {
  const _WeekdayHeaders({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Menlo',
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.dailyCounts,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, int> dailyCounts;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final startOffset = (firstWeekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    
    final selectedDate = ref.watch(selectedDateProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Find max count in this month for intensity scaling
    int maxInMonth = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final count = dailyCounts[date] ?? 0;
      if (count > maxInMonth) maxInMonth = count;
    }
    if (maxInMonth == 0) maxInMonth = 1;

    return Column(
      children: [
        for (int row = 0; row < rowCount; row++) ...[
          if (row > 0) const SizedBox(height: 4),
          Row(
            children: [
              for (int col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(
                    context,
                    row: row,
                    col: col,
                    startOffset: startOffset,
                    daysInMonth: daysInMonth,
                    todayDate: todayDate,
                    selectedDate: selectedDate,
                    maxInMonth: maxInMonth,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    final BuildContext context, {
    required final int row,
    required final int col,
    required final int startOffset,
    required final int daysInMonth,
    required final DateTime todayDate,
    required final DateTime selectedDate,
    required final int maxInMonth,
  }) {
    final cellIndex = row * 7 + col;
    final dayNumber = cellIndex - startOffset + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 40);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final count = dailyCounts[date] ?? 0;
    final isSelected = date.year == selectedDate.year &&
                       date.month == selectedDate.month &&
                       date.day == selectedDate.day;
    final isToday = date == todayDate;

    return _DayCell(
      dayNumber: dayNumber,
      count: count,
      maxInMonth: maxInMonth,
      isSelected: isSelected,
      isToday: isToday,
      onTap: () => onDayTap(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.count,
    required this.maxInMonth,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int dayNumber;
  final int count;
  final int maxInMonth;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final intensity = count > 0 ? (count / maxInMonth).clamp(0.1, 1.0) : 0.0;
    final bgColor = count > 0 
        ? colorScheme.primary.withValues(alpha: intensity)
        : Colors.transparent;
    
    final textColor = count > 0 && intensity > 0.5 
        ? Colors.white 
        : colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xxs),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary 
                : isToday 
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$dayNumber',
          style: AppTypography.caption.copyWith(
            color: textColor,
            fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w400,
            fontFamily: 'Menlo',
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
