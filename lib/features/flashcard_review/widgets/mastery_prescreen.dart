// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../providers/deck_providers.dart';
import '../providers/review_providers.dart';
import 'create_deck_sheet.dart';

/// The session launcher shown before entering a flashcard review session.
class MasteryPrescreen extends ConsumerWidget {
  const MasteryPrescreen({super.key, required this.source});

  final ReviewSessionSource source;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Ensure reactivity on card changes
    ref.watch(fsrsCardsRefreshProvider);
    final totalReviewable = ref.watch(totalReviewableCountProvider).valueOrNull;
    if (totalReviewable == 0 && source == ReviewSessionSource.stateBased) {
      return const _ReviewEmptyState();
    }

    final viewPadding = MediaQuery.of(context).padding;
    const bottomNavHeight = kBottomNavigationBarHeight;

    return SingleChildScrollView(
      // Top padding accounts for status bar + extra space
      // Bottom padding accounts for frosted nav bar + safe area + extra breathing room
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.xl + viewPadding.top,
        AppSpacing.screenEdge,
        bottomNavHeight + viewPadding.bottom + AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: source == ReviewSessionSource.stateBased
              ? const _StateModeSection()
              : const _DecksSection(),
        ),
      ),
    );
  }
}

class _StateModeSection extends ConsumerWidget {
  const _StateModeSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedKind = ref.watch(reviewEntityKindProvider);
    final isMoves = selectedKind == ReviewEntityKind.moves;
    
    final matrixAsync = ref.watch(reviewStateMatrixProvider);
    final stateLabels = ref.watch(learningStateLabelsProvider);
    final title = isMoves ? 'Moves' : 'Combos';

    final practiceAll = ref.watch(_practiceAllModeProvider);

    return matrixAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: AppLoader()),
      ),
      error: (final e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: Text('Error: $e')),
      ),
      data: (final matrix) {
        final counts = matrix.countsFor(selectedKind);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewLaneToggle(
              selectedKind: selectedKind,
              onChanged: (final selection) {
                HapticFeedback.selectionClick();
                ref.read(reviewEntityKindProvider.notifier).state = selection;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            
            _BasicPracticeToggle(
              isEnabled: practiceAll,
              onChanged: (final value) {
                HapticFeedback.selectionClick();
                ref.read(_practiceAllModeProvider.notifier).state = value;
                // Sync to the provider that actually affects the counts and filtering
                ref.read(reviewPracticeAllProvider.notifier).state = value;
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            _ReviewListDashboard(
              title: title,
              stateLabels: stateLabels,
              counts: counts,
              customCounts: matrix.customMoveCounts,
              isBasicPractice: practiceAll,
              onStartAll: () => _startStateSession(ref, selectedKind, null),
              onStartState: (final state) =>
                  _startStateSession(ref, selectedKind, state),
              onStartCustomState: (final dbValue) =>
                  _startCustomStateSession(ref, selectedKind, dbValue),
            ),
          ],
        );
      },
    );
  }

  void _startStateSession(
    final WidgetRef ref,
    final ReviewEntityKind kind,
    final LearningState? state,
  ) {
    HapticFeedback.heavyImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.stateBased);
    ref.read(reviewEntityKindProvider.notifier).state = kind;
    ref.read(selectedDeckProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    ref.read(reviewStateFilterProvider.notifier).state = state;
    ref.read(reviewCustomStateFilterProvider.notifier).state = null;
    
    // We already synced practiceAll in the toggle, so just refresh and launch
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }

  void _startCustomStateSession(
    final WidgetRef ref,
    final ReviewEntityKind kind,
    final String dbValue,
  ) {
    HapticFeedback.heavyImpact();
    ref
        .read(reviewSessionSourceProvider.notifier)
        .set(ReviewSessionSource.stateBased);
    ref.read(reviewEntityKindProvider.notifier).state = kind;
    ref.read(selectedDeckProvider.notifier).state = null;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    ref.read(reviewStateFilterProvider.notifier).state = null;
    ref.read(reviewCustomStateFilterProvider.notifier).state = dbValue;
    
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }
}

final _practiceAllModeProvider = StateProvider<bool>((final ref) => false);

class _BasicPracticeToggle extends StatelessWidget {
  const _BasicPracticeToggle({required this.isEnabled, required this.onChanged});
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: isEnabled ? colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.bolt_rounded : Icons.bolt_outlined,
            color: isEnabled ? colorScheme.primary : colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BASIC PRACTICE'.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Menlo',
                    color: isEnabled ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                Text(
                  isEnabled ? 'BYPASSING FSRS (MATH)' : 'FSRS ACTIVE (DUE ONLY)',
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'Menlo',
                    fontSize: 10,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
          ),

        ],
      ),
    );
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
  Widget build(final BuildContext context) {
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

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your Arsenal is empty',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add moves to start your practice journey.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecksSection extends ConsumerWidget {
  const _DecksSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final decksAsync = ref.watch(decksListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CUSTOM DECKS',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontFamily: 'Menlo',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 24),
              onPressed: () => CreateDeckSheet.show(context),
              tooltip: 'Create Deck',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        decksAsync.when(
          loading: () => const Center(child: AppLoader()),
          error: (final e, _) => Text('Error loading decks: $e'),
          data: (final decks) {
            if (decks.isEmpty) {
              return _EmptyDeckState();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: decks.length,
              separatorBuilder: (final _, final index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (final context, final index) {
                final deck = decks[index];
                return _DeckListRow(
                  deck: deck,
                  onTap: () => _startDeckSession(ref, deck),
                  onLongPress: () => _showDeckActions(context, ref, deck),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _startDeckSession(final WidgetRef ref, final Deck deck) {
    HapticFeedback.heavyImpact();
    ref.read(reviewSessionSourceProvider.notifier).set(ReviewSessionSource.deck);
    ref.read(selectedDeckProvider.notifier).state = deck;
    ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    refreshReviewSession(ref);
    ref.read(reviewSessionActiveProvider.notifier).state = true;
  }

  void _showDeckActions(
    final BuildContext context,
    final WidgetRef ref,
    final Deck deck,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (final context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Deck'),
              onTap: () {
                Navigator.pop(context);
                unawaited(CreateDeckSheet.show(context, deck: deck));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Deck', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                unawaited(ref.read(decksDaoProvider).deleteDeck(deck.id));
                unawaited(HapticFeedback.mediumImpact());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDeckState extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 48, color: colorScheme.secondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No custom decks yet',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => CreateDeckSheet.show(context),
            child: const Text('CREATE FIRST DECK'),
          ),
        ],
      ),
    );
  }
}

class _DeckListRow extends StatelessWidget {
  const _DeckListRow({
    required this.deck,
    required this.onTap,
    required this.onLongPress,
  });

  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmart = deck.deckType == 'smart';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              isSmart ? Icons.auto_awesome_rounded : Icons.layers_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name.toUpperCase(),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Menlo',
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (deck.sessionSize != null)
                    Text(
                      '${deck.sessionSize} CARDS',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Menlo',
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ReviewListDashboard extends ConsumerWidget {
  const _ReviewListDashboard({
    required this.title,
    required this.stateLabels,
    required this.counts,
    required this.customCounts,
    required this.onStartAll,
    required this.onStartState,
    required this.onStartCustomState,
    required this.isBasicPractice,
  });

  final String title;
  final Map<LearningState, String> stateLabels;
  final Map<LearningState, int> counts;
  final Map<String, int> customCounts;
  final VoidCallback onStartAll;
  final void Function(LearningState state) onStartState;
  final void Function(String dbValue) onStartCustomState;
  final bool isBasicPractice;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final int total = counts.values.fold(0, (final sum, final value) => sum + value) +
        customCounts.values.fold(0, (final sum, final value) => sum + value);
    
    final customStates = ref.watch(customLearningStatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            isBasicPractice ? 'ALL $title (BASIC PRACTICE)'.toUpperCase() : '$title BOXES'.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: isBasicPractice ? colorScheme.primary : colorScheme.secondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontFamily: 'Menlo',
            ),
          ),
        ),
        
        for (final state in LearningState.values)
          _ReviewStateRow(
            state: state,
            label: resolveLearningStateLabel(stateLabels, state),
            count: counts[state] ?? 0,
            onTap: () => onStartState(state),
          ),
        
        for (final custom in customStates)
          if ((customCounts[custom.dbValue] ?? 0) > 0)
            _ReviewStateRow(
              customColor: custom.color,
              label: custom.label,
              count: customCounts[custom.dbValue] ?? 0,
              onTap: () => onStartCustomState(custom.dbValue),
            ),
        
        _ReviewStateRow(
          label: 'TOTAL DUE',
          count: total,
          isTotal: true,
          onTap: total > 0 ? onStartAll : null,
        ),

        const SizedBox(height: AppSpacing.xl),

        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            onPressed: total > 0 ? onStartAll : null,
            style: FilledButton.styleFrom(
              backgroundColor: total == 0 ? colorScheme.surfaceContainerHighest : colorScheme.primary,
              foregroundColor: total == 0 ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (total > 0) const Icon(Icons.play_arrow_rounded, size: 24),
                if (total > 0) const SizedBox(width: AppSpacing.sm),
                Text(
                  (total == 0 ? 'ALL BOXES EMPTY' : (isBasicPractice ? 'START BASIC PRACTICE' : 'REVIEW ALL DUE')).toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontFamily: 'Menlo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStateRow extends StatelessWidget {
  const _ReviewStateRow({
    this.state,
    this.customColor,
    required this.label,
    required this.count,
    this.onTap,
    this.isTotal = false,
  });

  final LearningState? state;
  final Color? customColor;
  final String label;
  final int count;
  final VoidCallback? onTap;
  final bool isTotal;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = count > 0 || isTotal;
    final accent = customColor ?? (state != null ? context.stateColor(state!) : colorScheme.primary);

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                color: enabled ? accent : colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontFamily: 'Menlo',
                    color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isTotal ? colorScheme.primary : Colors.transparent,
                    border: isTotal ? null : Border.all(color: accent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Menlo',
                      color: isTotal ? colorScheme.onPrimary : accent,
                    ),
                  ),
                )
              else if (!isTotal)
                Text(
                  '0',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Menlo',
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
