import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../providers/deck_providers.dart';
import '../providers/review_providers.dart';
import 'create_deck_sheet.dart';
import 'deck_card.dart';

/// The session launcher shown before entering a flashcard review session.
///
/// The parent (FlashcardReviewScreen) passes [source] based on the active
/// mode tab — Review → stateBased, Deck → deck.
class MasteryPrescreen extends ConsumerWidget {
  const MasteryPrescreen({super.key, required this.source});

  final ReviewSessionSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalReviewable = ref.watch(totalReviewableCountProvider).valueOrNull;
    if (totalReviewable == 0) return const _ReviewEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.md,
        AppSpacing.screenEdge,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: source == ReviewSessionSource.stateBased
              ? const _StateModeSection()
              : _DecksSection(
                  onStartDeck: (deck) => _startDeckSession(ref, deck),
                ),
        ),
      ),
    );
  }

  void _startDeckSession(WidgetRef ref, Deck deck) {
    HapticFeedback.mediumImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.deck);
    ref.read(reviewEntityKindProvider.notifier).state = ReviewEntityKind.moves;
    ref.read(selectedDeckProvider.notifier).state = deck;
    ref.read(reviewStateFilterProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

class _StateModeSection extends ConsumerWidget {
  const _StateModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(reviewStateMatrixProvider);

    return countsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: Text('Error: $e')),
      ),
      data: (matrix) {
        final selectedKind = ref.watch(reviewEntityKindProvider);
        final isMoves = selectedKind == ReviewEntityKind.moves;
        final title = isMoves ? 'Moves' : 'Combos';
        final subtitle = isMoves
            ? 'Atomic move cards'
            : 'Sequence review cards';
        final counts = isMoves ? matrix.moveCounts : matrix.comboCounts;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewLaneToggle(
              selectedKind: selectedKind,
              onChanged: (selection) {
                HapticFeedback.selectionClick();
                ref.read(reviewEntityKindProvider.notifier).state = selection;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ReviewEntityPrescreenPanel(
              title: title,
              subtitle: subtitle,
              counts: counts,
              onStartAll: () => _startStateSession(ref, selectedKind, null),
              onStartState: (state) =>
                  _startStateSession(ref, selectedKind, state),
            ),
          ],
        );
      },
    );
  }

  void _startStateSession(
    WidgetRef ref,
    ReviewEntityKind kind,
    LearningState? state,
  ) {
    HapticFeedback.mediumImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.stateBased);
    ref.read(reviewEntityKindProvider.notifier).state = kind;
    ref.read(selectedDeckProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    ref.read(reviewStateFilterProvider.notifier).state = state;
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

class _ReviewLaneToggle extends StatelessWidget {
  const _ReviewLaneToggle({
    required this.selectedKind,
    required this.onChanged,
  });

  final ReviewEntityKind selectedKind;
  final ValueChanged<ReviewEntityKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<ReviewEntityKind>(
      items: const [
        AppSegmentedControlItem(
          value: ReviewEntityKind.moves,
          icon: Icons.trip_origin_rounded,
          label: 'Moves',
        ),
        AppSegmentedControlItem(
          value: ReviewEntityKind.combos,
          icon: Icons.timeline_rounded,
          label: 'Combos',
        ),
      ],
      selectedValue: selectedKind,
      onChanged: onChanged,
    );
  }
}

class _ReviewEntityPrescreenPanel extends StatelessWidget {
  const _ReviewEntityPrescreenPanel({
    required this.title,
    required this.subtitle,
    required this.counts,
    required this.onStartAll,
    required this.onStartState,
  });

  final String title;
  final String subtitle;
  final Map<LearningState, int> counts;
  final VoidCallback onStartAll;
  final void Function(LearningState state) onStartState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);
    final total = counts.values.fold(0, (sum, value) => sum + value);
    final readyStates = LearningState.values
        .where((state) => (counts[state] ?? 0) > 0)
        .toList(growable: false);
    final singleReadyState = readyStates.length == 1
        ? readyStates.single
        : null;
    final primaryActionLabel = switch (singleReadyState) {
      LearningState.newState => 'Start New',
      LearningState.learning => 'Start Learning',
      LearningState.mastery => 'Start Mastery',
      null when total == 0 => 'Nothing to review',
      _ => 'Review all ready',
    };
    final primaryAction = switch (singleReadyState) {
      LearningState.newState => () => onStartState(LearningState.newState),
      LearningState.learning => () => onStartState(LearningState.learning),
      LearningState.mastery => () => onStartState(LearningState.mastery),
      null when total == 0 => null,
      _ => onStartAll,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.panel(
        context,
        raised: true,
        radius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppSurfaces.panel(context, radius: 999),
                child: Text(
                  '$total ready',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final state in LearningState.values) ...[
                if (state != LearningState.values.first)
                  const SizedBox(height: AppSpacing.sm),
                _ReviewStateTile(
                  state: state,
                  count: counts[state] ?? 0,
                  accent: semanticTheme.colorForState(state),
                  onTap: () => onStartState(state),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: primaryAction,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: total == 0 ? null : colorScheme.primary,
                foregroundColor: total == 0 ? null : colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: Text(
                primaryActionLabel,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStateTile extends StatelessWidget {
  const _ReviewStateTile({
    required this.state,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final LearningState state;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticTheme = AppSemanticTheme.of(context);
    final enabled = count > 0;
    final subtitle = switch (state) {
      LearningState.newState => 'First recall',
      LearningState.learning => 'Short intervals',
      LearningState.mastery => 'Long intervals',
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${state.displayText}\n$count\n$subtitle',
      child: ExcludeSemantics(
        child: Container(
          decoration: AppSurfaces.panel(context, radius: AppRadius.sm),
          child: Material(
            color: semanticTheme.isMonoOutline
                ? colorScheme.surface
                : enabled
                ? accent.withValues(alpha: 0.08)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: enabled
                        ? accent.withValues(
                            alpha: semanticTheme.isMonoOutline ? 1 : 0.24,
                          )
                        : colorScheme.outline.withValues(alpha: 0.24),
                    width: semanticTheme.isMonoOutline ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: enabled ? accent : colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.displayText,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '$count',
                      style: AppTypography.titleSmall.copyWith(
                        color: enabled ? accent : colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: enabled
                          ? colorScheme.secondary
                          : colorScheme.secondary.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final selectedDeck = ref.watch(selectedDeckProvider);
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
                  Icon(
                    Icons.add,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Create a deck',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activeDeck = decks.any((deck) => deck.id == selectedDeck?.id)
            ? selectedDeck!
            : decks.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decks',
              style: AppTypography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final deck in decks) ...[
                    DeckCard(
                      deck: deck,
                      isSelected: deck.id == activeDeck.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedDeckProvider.notifier).state = deck;
                      },
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
                          Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create',
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(context).colorScheme.primary,
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
            const SizedBox(height: AppSpacing.lg),
            _DeckFocusPanel(deck: activeDeck, onStartDeck: onStartDeck)
                .animate()
                .fadeIn(duration: AppMotion.moderate01)
                .slideY(
                  begin: 0.03,
                  duration: AppMotion.moderate02,
                  curve: AppMotion.entrance,
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
          'This will remove the deck. Your moves won\u2019t be affected.',
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

class _DeckFocusPanel extends ConsumerWidget {
  const _DeckFocusPanel({required this.deck, required this.onStartDeck});

  final Deck deck;
  final void Function(Deck deck) onStartDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(deckSummaryProvider(deck.id));
    final colorScheme = Theme.of(context).colorScheme;

    return summaryAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Could not load deck: $error',
          style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
        ),
      ),
      data: (summary) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
            ),
            boxShadow: AppShadows.raised(Theme.of(context).brightness),
          ),
          child: Column(
            children: [
              Text(
                summary.deck.name,
                style: AppTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final state in LearningState.values) ...[
                if (state != LearningState.values.first)
                  const SizedBox(height: AppSpacing.sm),
                _DeckStateRow(
                  state: state,
                  count: summary.movesForState(state).length,
                  onTap: () =>
                      _showDeckStateSheet(context, ref, summary, state),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: summary.totalMoves == 0
                      ? null
                      : () {
                          ref.read(reviewStateFilterProvider.notifier).state =
                              null;
                          ref.read(reviewEntityKindProvider.notifier).state =
                              ReviewEntityKind.moves;
                          onStartDeck(summary.deck);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(
                    summary.totalMoves == 0 ? 'Deck is empty' : 'Start Deck',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startDeckState(
    WidgetRef ref,
    DeckSummary summary,
    LearningState state,
  ) {
    final stateMoves = summary.movesForState(state);
    if (stateMoves.isEmpty) return;

    HapticFeedback.mediumImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.deck);
    ref.read(reviewEntityKindProvider.notifier).state = ReviewEntityKind.moves;
    ref.read(selectedDeckProvider.notifier).state = summary.deck;
    ref.read(reviewStateFilterProvider.notifier).state = state;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = stateMoves
        .map((move) => move.id)
        .toSet();
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }

  void _showDeckStateSheet(
    BuildContext context,
    WidgetRef ref,
    DeckSummary summary,
    LearningState state,
  ) {
    final moves = summary.movesForState(state);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.deck.name} · ${state.displayText}',
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${moves.length} card${moves.length == 1 ? '' : 's'} in this state',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: moves.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final move = moves[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    move.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (move.category != 'default') ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      move.category,
                                      style: AppTypography.caption.copyWith(
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: moves.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            _startDeckState(ref, summary, state);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text('Start ${state.displayText}'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeckStateRow extends StatelessWidget {
  const _DeckStateRow({
    required this.state,
    required this.count,
    required this.onTap,
  });

  final LearningState state;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = count > 0;

    return Material(
      color: enabled
          ? state.color.withValues(alpha: 0.08)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: enabled ? state.color : colorScheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.displayText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count',
                style: AppTypography.bodyMedium.copyWith(
                  color: enabled ? state.color : colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: enabled
                    ? colorScheme.secondary
                    : colorScheme.secondary.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState();

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
                    Icon(
                      Icons.style_outlined,
                      size: 72,
                      color: colorScheme.secondary,
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
