import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../providers/deck_providers.dart';
import '../providers/review_providers.dart';
import 'create_deck_sheet.dart';
import 'deck_card.dart';

/// The session launcher shown before entering a flashcard review session.
///
/// Session mode has two sources:
/// - State-based: quick entry into NEW / LEARNING / MASTERY buckets
/// - Deck: saved manual or smart deck sessions
class MasteryPrescreen extends ConsumerWidget {
  const MasteryPrescreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMoves = ref.watch(totalMoveCountProvider).valueOrNull ?? 0;
    if (totalMoves == 0) return const _ReviewEmptyState();

    final reviewSource = ref.watch(reviewSessionSourceProvider);
    final dueAsync = ref.watch(dueSummaryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverToBoxAdapter(
            child: dueAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (summary) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.totalDueNow == 0
                          ? 'All caught up'
                          : '${summary.totalDueNow} due today',
                      style: AppTypography.titleSmall.copyWith(
                        color: summary.totalDueNow == 0
                            ? colorScheme.secondary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choose a review source for this session.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverToBoxAdapter(
            child: _SourceSelector(
              source: reviewSource,
              onChanged: (source) {
                HapticFeedback.selectionClick();
                ref.read(reviewSessionSourceProvider.notifier).set(source);
                ref.read(reviewSessionTargetMoveIdsProvider.notifier).state =
                    null;
                if (source == ReviewSessionSource.stateBased) {
                  ref.read(selectedDeckProvider.notifier).state = null;
                } else {
                  ref.read(reviewStateFilterProvider.notifier).state = null;
                }
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        if (reviewSource == ReviewSessionSource.stateBased)
          const _StateModeSection()
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            sliver: SliverToBoxAdapter(
              child: _DecksSection(
                onStartDeck: (deck) => _startDeckSession(ref, deck),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  void _startDeckSession(WidgetRef ref, Deck deck) {
    HapticFeedback.mediumImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.deck);
    ref.read(selectedDeckProvider.notifier).state = deck;
    ref.read(reviewStateFilterProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({required this.source, required this.onChanged});

  final ReviewSessionSource source;
  final ValueChanged<ReviewSessionSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReviewSessionSource>(
      segments: const [
        ButtonSegment<ReviewSessionSource>(
          value: ReviewSessionSource.stateBased,
          icon: Icon(Icons.tune_rounded, size: 18),
          label: Text('State'),
        ),
        ButtonSegment<ReviewSessionSource>(
          value: ReviewSessionSource.deck,
          icon: Icon(Icons.style_rounded, size: 18),
          label: Text('Deck'),
        ),
      ],
      selected: {source},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _StateModeSection extends ConsumerWidget {
  const _StateModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(moveStateCountsProvider);

    return countsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
      data: (counts) {
        final items = [
          (
            state: LearningState.newState,
            title: 'New',
            subtitle: 'Fresh cards waiting for first reps',
            icon: Icons.fiber_new_rounded,
          ),
          (
            state: LearningState.learning,
            title: 'Learning',
            subtitle: 'Cards still settling into memory',
            icon: Icons.school_outlined,
          ),
          (
            state: LearningState.mastery,
            title: 'Mastery',
            subtitle: 'Cards already in longer-term rotation',
            icon: Icons.verified_rounded,
          ),
        ];

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == items.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _startStateSession(ref, null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text('Start All'),
                    ),
                  ),
                );
              }

              final item = items[index];
              final count = counts[item.state] ?? 0;
              return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _StateSessionCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      count: count,
                      color: item.state.color,
                      icon: item.icon,
                      onStart: () => _startStateSession(ref, item.state),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: AppMotion.moderate01,
                    delay: Duration(milliseconds: index * 40),
                  )
                  .slideY(
                    begin: 0.03,
                    duration: AppMotion.moderate02,
                    delay: Duration(milliseconds: index * 40),
                  );
            }, childCount: items.length + 1),
          ),
        );
      },
    );
  }

  void _startStateSession(WidgetRef ref, LearningState? state) {
    HapticFeedback.mediumImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.stateBased);
    ref.read(selectedDeckProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    ref.read(reviewStateFilterProvider.notifier).state = state;
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

class _StateSessionCard extends StatelessWidget {
  const _StateSessionCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.icon,
    required this.onStart,
  });

  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              TextButton(
                onPressed: onStart,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decks section with progressive disclosure:
/// - Empty: single-line "Create a deck" link
/// - Non-empty: horizontal scroll of deck cards + create button
class _DecksSection extends ConsumerWidget {
  const _DecksSection({required this.onStartDeck});

  final void Function(Deck deck) onStartDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return decksAsync.when(
      loading: () => const SizedBox(
        height: 20,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (decks) {
        if (decks.isEmpty) {
          return GestureDetector(
            onTap: () => CreateDeckSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Create a deck',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Decks',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Deck sessions use the deck’s own card filter and membership.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final deck in decks) ...[
                    DeckCard(
                      deck: deck,
                      onTap: () => onStartDeck(deck),
                      onLongPress: () => _confirmDelete(context, ref, deck),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  GestureDetector(
                    onTap: () => CreateDeckSheet.show(context),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.accent, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Create',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Deck deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${deck.name}"?'),
        content: const Text(
          'This will remove the deck. Your moves won’t be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(decksDaoProvider).deleteDeck(deck.id);
                if (ref.read(selectedDeckProvider)?.id == deck.id) {
                  ref.read(selectedDeckProvider.notifier).state = null;
                }
                HapticFeedback.mediumImpact();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete deck: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.actionAgain),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                        angle: -0.12,
                        child: Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.stateNew.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
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
                            borderRadius: BorderRadius.circular(AppRadius.md),
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
                          color: AppColors.stateMastery.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Add moves to start training',
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Record your breakdancing moves, then review with spaced repetition.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/arsenal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: const Text('Go to Arsenal'),
            ),
          ],
        ),
      ),
    );
  }
}
