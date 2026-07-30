import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/features/flashcard_review/providers/review_providers.dart';
import 'package:breakdex/features/flashcard_review/widgets/item_schedule_detail_sheet.dart';
import 'package:breakdex/features/flashcard_review/widgets/schedule_calendar.dart';
import 'package:breakdex/features/flashcard_review/widgets/scheduled_item_row.dart';
import 'package:breakdex/features/flashcard_review/widgets/srs_parameters_card.dart';
import 'package:breakdex/core/design/icons.dart';

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
  Widget build(final BuildContext context, final WidgetRef ref) {
    final totalMoves = ref.watch(totalMoveCountProvider).valueOrNull ?? 0;

    // Reuse the same empty state from mastery prescreen when no moves exist
    if (totalMoves == 0) return const _ScheduleEmptyState();

    final dueCountsAsync = ref.watch(calendarDueCountsProvider);
    final dueSummaryAsync = ref.watch(dueSummaryProvider);
    final selectedDate = ref.watch(reviewCalendarSelectedDateProvider);
    final itemsAsync = ref.watch(itemsDueOnSelectedDateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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
                  child: AppLoader(size: 6),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (final summary) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    summary.totalDueNow == 0
                        ? l10n.revAllCaughtUp
                        : l10n.revDueTodayCount(summary.totalDueNow),
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
              data: (final counts) => ScheduleCalendar(dueCounts: counts),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // SRS parameters
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
          sliver: SliverToBoxAdapter(child: SrsParametersCard()),
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
                      ? l10n.revDueTodayHeader
                      : l10n.revDueDate(_fmtDate(selectedDate)),
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                itemsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (final items) => Text(
                    l10n.revItemCount(items.length),
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
          loading: () =>
              const SliverToBoxAdapter(child: Center(child: AppLoader())),
          error: (final e, _) => SliverToBoxAdapter(
            child: Center(child: Text(l10n.revError('$e'))),
          ),
          data: (final items) {
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
                        AppIconView(
                          AppIcon.check,
                          size: 48,
                          color: AppSemanticTheme.of(context).actionGood.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isToday(selectedDate)
                              ? l10n.revNoItemsDueToday
                              : l10n.revNoItemsDueOnDate,
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
                itemBuilder: (final context, final index) {
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

  static bool _isToday(final DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String _fmtDate(final DateTime date) {
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
class _ScheduleEmptyState extends ConsumerWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final entityNames = ref.watch(entityNamesProvider);

    return LayoutBuilder(
      builder: (final context, final constraints) {
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
                                    color: context
                                        .stateColor(LearningState.newState)
                                        .withValues(alpha: 0.15),
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
                                    color: context
                                        .stateColor(LearningState.learning)
                                        .withValues(alpha: 0.15),
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
                                  color: context
                                      .stateColor(LearningState.mastery)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: AppMotion.moderate02,
                                delay: AppMotion.moderate02,
                              )
                              .slideY(begin: 0.1),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.revAddToStartTraining(
                        entityNames.movePlural.toLowerCase(),
                      ),
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.revRecordMoves(entityNames.movePlural.toLowerCase()),
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.secondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: () => context.go('/moves'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        l10n.revGoToArsenal,
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
