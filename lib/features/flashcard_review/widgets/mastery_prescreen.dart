import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/services/categories_service.dart';
import '../../../core/services/fsrs_service.dart';
import '../providers/deck_providers.dart';
import '../providers/review_providers.dart';
import 'create_deck_sheet.dart';
import 'deck_card.dart';

/// The mastery pre-screen shown before entering a flashcard review session.
///
/// Displays:
/// - Due today / due tomorrow summary
/// - Per-category mastery grid with progress bars and card state counts
/// - "Start" buttons per category and "Start All" at the bottom
class MasteryPrescreen extends ConsumerWidget {
  const MasteryPrescreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMoves = ref.watch(totalMoveCountProvider).valueOrNull ?? 0;

    // Full empty state when no moves exist at all
    if (totalMoves == 0) return const _ReviewEmptyState();

    final masteryAsync = ref.watch(categoryMasteryProvider);
    final dueAsync = ref.watch(dueSummaryProvider);
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Saved Decks — horizontal scroll
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
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // Category mastery grid
        masteryAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Error: $e')),
          ),
          data: (masteryList) {
            if (masteryList.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              sliver: SliverList.builder(
                itemCount: masteryList.length,
                itemBuilder: (context, index) {
                  final mastery = masteryList[index];
                  final cat = categories
                      .where((c) => c.name == mastery.category)
                      .firstOrNull;
                  final catColor = cat?.color ?? AppColors.accent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CategoryMasteryCard(
                      mastery: mastery,
                      categoryColor: catColor,
                      onStart: () => _startSession(ref, mastery.category),
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
                },
              ),
            );
          },
        ),

        // NEW / LEARN / MASTERY triptych — above Start All for quick glance
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
            vertical: AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: dueAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (summary) => summary.totalDueNow == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          'All caught up',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          '${summary.totalDueNow} due today',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Start All button
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge, AppSpacing.md, AppSpacing.screenEdge, AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _startSession(ref, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Start All'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startSession(WidgetRef ref, String? category) {
    HapticFeedback.mediumImpact();
    ref.read(selectedDeckProvider.notifier).state = null;
    ref.read(reviewCategoryFilterProvider.notifier).state = category;
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }

  void _startDeckSession(WidgetRef ref, Deck deck) {
    HapticFeedback.mediumImpact();
    ref.read(selectedDeckProvider.notifier).state = deck;
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

/// A card showing mastery info for a single category.
class _CategoryMasteryCard extends StatelessWidget {
  const _CategoryMasteryCard({
    required this.mastery,
    required this.categoryColor,
    required this.onStart,
  });

  final CategoryMastery mastery;
  final Color categoryColor;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (mastery.masteryPercent * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: color dot + name + due badge + start button
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mastery.category,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (mastery.dueCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.actionAgain.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${mastery.dueCount} due',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.actionAgain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Apple HIG: minimum 44pt touch target
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: onStart,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(
                    'Start',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Mastery progress bar with progressive disclosure:
          // 0% → lower opacity bar, no text. 100% → checkmark icon.
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: pct == 0 ? 0.4 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mastery.masteryPercent,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      color: AppColors.stateMastery,
                      minHeight: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (pct == 100)
                Icon(Icons.check_circle, size: 16, color: AppColors.stateMastery)
              else if (pct > 0)
                Text(
                  '$pct%',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decks section with progressive disclosure:
/// - Empty: single-line "Create a deck" link (no header, no 100px scroll area)
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
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (decks) {
        // Collapsed single-line when empty
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

        // Full deck list with horizontal scroll
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decks',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
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
                      onLongPress: () =>
                          _confirmDelete(context, ref, deck),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // Create button
                  GestureDetector(
                    onTap: () => CreateDeckSheet.show(context),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              color: AppColors.accent, size: 24),
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
          'This will remove the deck. Your moves won\'t be affected.',
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
            child: const Text('Delete',
                style: TextStyle(color: AppColors.actionAgain)),
          ),
        ],
      ),
    );
  }
}

// -- Full Empty State --------------------------------------------------------

/// Shown when the user has zero moves in their breakdex.
///
/// Three overlapping rounded rectangles (fanned at slight angles) in state
/// colors evoke a deck of cards waiting to be filled, with staggered entrance
/// animations for polish.
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
            // Decorative fanned card shapes
            SizedBox(
              height: 100,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back card (rotated left)
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
                          delay: const Duration(milliseconds: 80))
                      .slideY(begin: 0.1),
                  // Middle card (rotated right)
                  Transform.rotate(
                    angle: 0.08,
                    child: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            AppColors.stateLearning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          duration: AppMotion.moderate02,
                          delay: const Duration(milliseconds: 160))
                      .slideY(begin: 0.1),
                  // Front card (centered)
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
                          delay: const Duration(milliseconds: 240))
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
