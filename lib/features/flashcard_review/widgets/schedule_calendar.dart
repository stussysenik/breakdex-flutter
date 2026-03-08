import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../providers/review_providers.dart';

/// Forward-looking month calendar for the Schedule review mode.
///
/// Unlike [StatsCalendar] which only looks backward (past review counts),
/// this calendar looks *forward* to show upcoming due dates. Each day cell
/// shows colored dots indicating the FSRS state of items due that day:
/// - Pink: New cards
/// - Blue: Learning/Relearning cards
/// - Purple: Review (mastered) cards
class ScheduleCalendar extends ConsumerStatefulWidget {
  const ScheduleCalendar({super.key, required this.dueCounts});

  /// Pre-computed due counts per day (keyed by midnight DateTime).
  final Map<DateTime, int> dueCounts;

  @override
  ConsumerState<ScheduleCalendar> createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends ConsumerState<ScheduleCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(reviewCalendarSelectedDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Month header text
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final headerText =
        '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';

    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final startOffset = (firstDay.weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: Icon(Icons.chevron_left,
                    color: colorScheme.onSurface, size: 24),
              ),
              Text(
                headerText,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface, size: 24),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Day-of-week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Day grid
          ...List.generate(_rowCount(startOffset, daysInMonth), (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final dayIndex = row * 7 + col - startOffset + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final date = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    dayIndex,
                  );
                  final count = widget.dueCounts[date] ?? 0;
                  final isToday = date == today;
                  final isSelected = date == selectedDate;
                  final isPast = date.isBefore(today);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(
                                reviewCalendarSelectedDateProvider.notifier)
                            .state = date;
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayIndex',
                              style: AppTypography.caption.copyWith(
                                color: isPast && count == 0
                                    ? colorScheme.secondary
                                        .withValues(alpha: 0.3)
                                    : count > 0
                                        ? colorScheme.onSurface
                                        : colorScheme.secondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            // Intensity dot — size & opacity scale with count.
                            if (count > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: _dotSize(count),
                                height: _dotSize(count),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _dotColor(count, isPast, Theme.of(context).colorScheme.primary),
                                ),
                              )
                            else
                              const SizedBox(height: 2),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _rowCount(int startOffset, int daysInMonth) {
    return ((startOffset + daysInMonth + 6) / 7).floor();
  }

  /// Proportional dot size based on due count intensity.
  double _dotSize(int count) {
    if (count >= 6) return 8.0;
    if (count >= 3) return 6.0;
    return 4.0;
  }

  /// Badge color: overdue items are red, future items use accent.
  Color _dotColor(int count, bool isPast, Color primary) {
    if (isPast) return AppColors.actionAgain.withValues(alpha: 0.7);
    if (count >= 8) return primary;
    if (count >= 4) return primary.withValues(alpha: 0.7);
    return primary.withValues(alpha: 0.4);
  }
}
