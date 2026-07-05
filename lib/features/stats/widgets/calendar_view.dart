// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../lab/providers/lab_providers.dart';

// ---------------------------------------------------------------------------
// LabCalendarView — month-grid calendar showing daily Lab activity.
// ---------------------------------------------------------------------------

/// A calendar view showing daily activity across the whole Lab system.
///
/// Displays a month grid (not the Stats heatmap) where each day cell shows
/// colored dots for different activity types:
/// - **Blue dot** = reviews that day
/// - **Purple dot** = lab entries that day
/// - **Green dot** = milestones completed that day
///
/// Tap a day to see a bottom sheet listing that day's activities.
/// Swipe left/right to navigate months.
class LabCalendarView extends ConsumerStatefulWidget {
  const LabCalendarView({super.key});

  @override
  ConsumerState<LabCalendarView> createState() => _LabCalendarViewState();
}

class _LabCalendarViewState extends ConsumerState<LabCalendarView> {
  /// The month displayed when the widget first mounts — acts as the fixed
  /// anchor for page-index-to-month calculations.
  late final DateTime _anchorMonth;

  /// The currently visible month (updated on page change for the header).
  late DateTime _displayedMonth;

  late PageController _pageController;

  /// We use a PageView with a large initial page to allow "infinite" scrolling.
  static const int _initialPage = 600;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorMonth = DateTime(now.year, now.month);
    _displayedMonth = _anchorMonth;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Compute the month for a given page index relative to the anchor month.
  /// The anchor never changes, so this mapping is stable across page swipes.
  DateTime _monthForPage(final int page) {
    final offset = page - _initialPage;
    return DateTime(_anchorMonth.year, _anchorMonth.month + offset);
  }

  void _onPageChanged(final int page) {
    setState(() {
      _displayedMonth = _monthForPage(page);
    });
  }

  void _goToPreviousMonth() {
    _pageController.previousPage(
      duration: AppMotion.moderate02,
      curve: AppMotion.productive,
    );
  }

  void _goToNextMonth() {
    _pageController.nextPage(
      duration: AppMotion.moderate02,
      curve: AppMotion.productive,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _goToPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 28,
                color: colorScheme.onSurface,
              ),
              Text(
                _formatMonth(_displayedMonth),
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: _goToNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 28,
                color: colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weekday headers
          _WeekdayHeaders(colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.xs),

          // Page view for swiping months
          SizedBox(
            // 6 rows max * cell height + spacing
            height: 6 * 52.0 + 5 * AppSpacing.xs,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (final context, final page) {
                final month = _monthForPage(page);
                return _MonthGrid(
                  month: month,
                  onDayTap: (final date) => _showDayDetail(context, date),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Legend
          _Legend(colorScheme: colorScheme),
        ],
      ),
    );
  }

  /// Show a bottom sheet listing the day's activities.
  Future<void> _showDayDetail(final BuildContext context, final DateTime date) async {
    unawaited(HapticFeedback.selectionClick());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(date: date),
    );
  }

  String _formatMonth(final DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }
}

// -- Weekday Headers ----------------------------------------------------------

class _WeekdayHeaders extends StatelessWidget {
  const _WeekdayHeaders({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -- Month Grid ---------------------------------------------------------------

/// A single month grid showing day cells with activity dots.
class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.onDayTap});

  final DateTime month;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final activityAsync = ref.watch(_monthActivityProvider(month));
    final activity = activityAsync.valueOrNull ?? const _MonthActivity();

    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Monday = 1, Sunday = 7 in Dart's weekday system.
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    // Offset: Monday-based grid, so Monday=0, Tuesday=1, ... Sunday=6.
    final startOffset = firstWeekday - 1;

    final totalCells = startOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        for (int row = 0; row < rowCount; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.xs),
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
                    activity: activity,
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
    required final _MonthActivity activity,
  }) {
    final cellIndex = row * 7 + col;
    final dayNumber = cellIndex - startOffset + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 48);
    }

    final date = DateTime(month.year, month.month, dayNumber);
    final isToday = date == todayDate;
    final hasReviews = activity.reviewDays.contains(dayNumber);
    final hasEntries = activity.entryDays.contains(dayNumber);
    final hasMilestones = activity.milestoneDays.contains(dayNumber);

    return _DayCell(
      dayNumber: dayNumber,
      isToday: isToday,
      hasReviews: hasReviews,
      hasEntries: hasEntries,
      hasMilestones: hasMilestones,
      onTap: () => onDayTap(date),
    );
  }
}

// -- Day Cell -----------------------------------------------------------------

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.isToday,
    required this.hasReviews,
    required this.hasEntries,
    required this.hasMilestones,
    required this.onTap,
  });

  final int dayNumber;
  final bool isToday;
  final bool hasReviews;
  final bool hasEntries;
  final bool hasMilestones;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Container(
              width: 28,
              height: 28,
              decoration: isToday
                  ? BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: AppTypography.bodySmall.copyWith(
                  color: isToday
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Activity dots row
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasReviews)
                    const _Dot(color: AppColors.stateLearning), // Blue
                  if (hasEntries)
                    const _Dot(color: Color(0xFF9333EA)), // Purple
                  if (hasMilestones)
                    const _Dot(color: AppColors.stateMastery), // Green
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// -- Legend --------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.stateLearning,
          label: 'Reviews',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(
          color: const Color(0xFF9333EA),
          label: 'Lab entries',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AppSpacing.md),
        _LegendItem(
          color: AppColors.stateMastery,
          label: 'Milestones',
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.colorScheme,
  });

  final Color color;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        ),
      ],
    );
  }
}

// -- Day Detail Bottom Sheet --------------------------------------------------

/// Bottom sheet showing all activities for a specific day.
class _DayDetailSheet extends ConsumerWidget {
  const _DayDetailSheet({required this.date});

  final DateTime date;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayDataAsync = ref.watch(_dayDetailProvider(date));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (final context, final scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                _formatDate(date),
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: dayDataAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (final e, _) => Center(child: Text('Error: $e')),
                  data: (final data) {
                    if (data.isEmpty) {
                      return Center(
                        child: Text(
                          'No activity this day',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: data.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, final index) {
                        final item = data[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: AppSurfaces.panel(
                            context,
                            radius: AppRadius.sm,
                          ),
                          child: Row(
                            children: [
                              _Dot(color: item.color),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.typeLabel,
                                      style: AppTypography.caption.copyWith(
                                        color: item.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(final DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// -- Data Models & Providers --------------------------------------------------

/// Aggregated activity data for a single month — which day numbers have
/// which types of activity. Stored as sets of day-of-month ints for O(1) lookup.
class _MonthActivity {
  const _MonthActivity({
    this.reviewDays = const {},
    this.entryDays = const {},
    this.milestoneDays = const {},
  });

  final Set<int> reviewDays;
  final Set<int> entryDays;
  final Set<int> milestoneDays;
}

/// Provider that aggregates review/entry/milestone data for a given month.
///
/// Fetches all three data sources for the month range and buckets them by
/// day-of-month. This is a FutureProvider because the underlying DAOs
/// provide futures for range queries (reviews) and we convert streams
/// to futures for entries/milestones.
final _monthActivityProvider = FutureProvider.family<_MonthActivity, DateTime>((
  final ref,
  final month,
) async {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  // Fetch reviews for the month range.
  final reviewsDao = ref.watch(reviewsDaoProvider);
  final reviews = await reviewsDao.getInRange(start, end);
  final reviewDays = <int>{};
  for (final r in reviews) {
    reviewDays.add(r.reviewedAt.day);
  }

  // Fetch lab entries for the month range.
  // LabEntriesDao doesn't have a range query, so we use watchRecent and filter.
  final entriesDao = ref.watch(labEntriesDaoProvider);
  final allEntries = await entriesDao.watchByLab(null).first;
  final entryDays = <int>{};
  for (final e in allEntries) {
    if (e.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
        e.createdAt.isBefore(end.add(const Duration(seconds: 1)))) {
      entryDays.add(e.createdAt.day);
    }
  }

  // Fetch completed milestones for the month range.
  // MilestonesDao doesn't have a global range query, so we get all labs
  // and collect milestones. This is efficient enough for calendar display.
  final labsDao = ref.watch(labsDaoProvider);
  final labs = await labsDao.getAll();
  final milestonesDao = ref.watch(milestonesDaoProvider);
  final milestoneDays = <int>{};
  for (final lab in labs) {
    final milestones = await milestonesDao.watchByLab(lab.id).first;
    for (final m in milestones) {
      if (m.completedAt != null &&
          m.completedAt!.isAfter(start.subtract(const Duration(seconds: 1))) &&
          m.completedAt!.isBefore(end.add(const Duration(seconds: 1)))) {
        milestoneDays.add(m.completedAt!.day);
      }
    }
  }

  return _MonthActivity(
    reviewDays: reviewDays,
    entryDays: entryDays,
    milestoneDays: milestoneDays,
  );
});

/// A single activity item shown in the day detail bottom sheet.
class _DayActivityItem {
  const _DayActivityItem({
    required this.typeLabel,
    required this.description,
    required this.color,
    required this.timestamp,
  });

  final String typeLabel;
  final String description;
  final Color color;
  final DateTime timestamp;
}

/// Provider that fetches all activity details for a specific day.
final _dayDetailProvider =
    FutureProvider.family<List<_DayActivityItem>, DateTime>((final ref, final date) async {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final items = <_DayActivityItem>[];

      // Reviews
      final reviewsDao = ref.watch(reviewsDaoProvider);
      final reviews = await reviewsDao.getInRange(start, end);
      for (final r in reviews) {
        items.add(
          _DayActivityItem(
            typeLabel: 'Review',
            description:
                '${r.rating} review'
                '${r.moveId != null ? ' (move)' : ''}'
                '${r.comboId != null ? ' (combo)' : ''}',
            color: AppColors.stateLearning,
            timestamp: r.reviewedAt,
          ),
        );
      }

      // Lab entries
      final entriesDao = ref.watch(labEntriesDaoProvider);
      final allEntries = await entriesDao.watchByLab(null).first;
      for (final e in allEntries) {
        if (e.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.createdAt.isBefore(end)) {
          items.add(
            _DayActivityItem(
              typeLabel: 'Lab Entry',
              description: e.content,
              color: const Color(0xFF9333EA),
              timestamp: e.createdAt,
            ),
          );
        }
      }

      // Milestones
      final labsDao = ref.watch(labsDaoProvider);
      final labs = await labsDao.getAll();
      final milestonesDao = ref.watch(milestonesDaoProvider);
      for (final lab in labs) {
        final milestones = await milestonesDao.watchByLab(lab.id).first;
        for (final m in milestones) {
          if (m.completedAt != null &&
              m.completedAt!.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              m.completedAt!.isBefore(end)) {
            items.add(
              _DayActivityItem(
                typeLabel: 'Milestone',
                description: '${m.title} (${lab.name})',
                color: AppColors.stateMastery,
                timestamp: m.completedAt!,
              ),
            );
          }
        }
      }

      // Sort by timestamp
      items.sort((final a, final b) => a.timestamp.compareTo(b.timestamp));
      return items;
    });
