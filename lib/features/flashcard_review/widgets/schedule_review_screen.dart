import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../providers/review_providers.dart';
import 'item_schedule_detail_sheet.dart';
import 'schedule_calendar.dart';
import 'scheduled_item_row.dart';
import 'srs_parameters_card.dart';

/// The schedule review mode: a calendar-based view of upcoming reviews.
///
/// Layout (CustomScrollView):
/// 1. DueCardsSummary — NEW / LEARN / MASTERY counts
/// 2. ScheduleCalendar — forward-looking month calendar with due dots
/// 3. SrsParametersCard — FSRS config display
/// 4. Section header — "Due [selected date]"
/// 5. ScheduledItemList — items due on selected date
class ScheduleReviewScreen extends ConsumerWidget {
  const ScheduleReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMoves = ref.watch(totalMoveCountProvider).valueOrNull ?? 0;

    // Reuse the same empty state from mastery prescreen when no moves exist
    if (totalMoves == 0) return const _ScheduleEmptyState();

    final dueCountsAsync = ref.watch(calendarDueCountsProvider);
    final dueSummaryAsync = ref.watch(dueSummaryProvider);
    final selectedDate = ref.watch(reviewCalendarSelectedDateProvider);
    final itemsAsync = ref.watch(itemsDueOnSelectedDateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Due summary
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverToBoxAdapter(
            child: dueSummaryAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (summary) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    summary.totalDueNow == 0
                        ? 'All caught up'
                        : '${summary.totalDueNow} due today',
                    style: AppTypography.bodyMedium.copyWith(
                      color: summary.totalDueNow == 0
                          ? colorScheme.secondary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Calendar
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverToBoxAdapter(
            child: dueCountsAsync.when(
              loading: () => const SizedBox(height: 280),
              error: (_, _) => const SizedBox.shrink(),
              data: (counts) => ScheduleCalendar(dueCounts: counts),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // SRS parameters
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: const SliverToBoxAdapter(child: SrsParametersCard()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        // Section header: "Due [date]"
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  _isToday(selectedDate)
                      ? 'Due Today'
                      : 'Due ${_fmtDate(selectedDate)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                itemsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) => Text(
                    '${items.length} item${items.length == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

        // Items list
        itemsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          data: (items) {
            if (items.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                    vertical: AppSpacing.xl,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: AppColors.actionGood.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isToday(selectedDate)
                              ? 'No items due today'
                              : 'No items due on this date',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ScheduledItemRow(
                    item: item,
                    onTap: () => ItemScheduleDetailSheet.show(context, item),
                  );
                },
              ),
            );
          },
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String _fmtDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// -- Schedule Empty State ----------------------------------------------------

/// Shown when the user has zero moves — same design as mastery empty state.
class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > 480
            ? 420.0
            : constraints.maxWidth - (AppSpacing.screenEdge * 2);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
            ),
            child: Center(
              child: SizedBox(
                width: contentWidth.clamp(280.0, 420.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 108,
                      width: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                                angle: -0.12,
                                child: Container(
                                  width: 80,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.stateNew.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: AppMotion.moderate02,
                                delay: const Duration(milliseconds: 80),
                              )
                              .slideY(begin: 0.1),
                          Transform.rotate(
                                angle: 0.08,
                                child: Container(
                                  width: 80,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.stateLearning.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: AppMotion.moderate02,
                                delay: const Duration(milliseconds: 160),
                              )
                              .slideY(begin: 0.1),
                          Container(
                                width: 80,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.stateMastery.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: AppMotion.moderate02,
                                delay: const Duration(milliseconds: 240),
                              )
                              .slideY(begin: 0.1),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Add moves to start training',
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Record your breakdancing moves, then review with spaced repetition.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.secondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: () => context.go('/arsenal'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'Go to Arsenal',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
