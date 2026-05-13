import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/settings_gear_button.dart';
import '../../core/models/learning_state.dart';

class MoveCategoryScreen extends ConsumerWidget {
  const MoveCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final movesAsync = ref.watch(_allMovesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final moves = movesAsync.valueOrNull ?? const <Move>[];

    final categoryCounts = <String, int>{};
    for (final move in moves) {
      categoryCounts[move.category] = (categoryCounts[move.category] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'moves-back',
          label: 'Back',
          button: true,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
                  Text(
                    'Back',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Moves'),
        actions: const [SettingsGearButton(), SizedBox(width: AppSpacing.sm)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          Semantics(header: true, child: Text('Categories', style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface))),
          const SizedBox(height: AppSpacing.lg),
          for (final cat in categories)
            _CategoryTile(
              category: cat,
              count: categoryCounts[cat.name] ?? 0,
              onTap: () => context.push('/breakdex/moves/${Uri.encodeComponent(cat.name)}'),
            ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(header: true, child: Text('Uncategorized', style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700))),
          const SizedBox(height: AppSpacing.sm),
          _CategoryTile(
            category: const Category(name: 'Uncategorized', colorValue: 0xFF9E9E9E, isDefault: true),
            count: (categoryCounts['default'] ?? 0) + (categoryCounts['Uncategorized'] ?? 0),
            onTap: () => context.push('/breakdex/moves/uncategorized'),
          ),
        ],
      ),
    );
  }
}

final _allMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.count, required this.onTap});

  final Category category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(category.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
              ),
              Text(
                '$count',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.chevron_right_rounded, color: colorScheme.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MoveCategoryDetailScreen extends ConsumerWidget {
  const MoveCategoryDetailScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(_allMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final allMoves = movesAsync.valueOrNull ?? const <Move>[];
    final filtered = categoryName == 'uncategorized'
        ? allMoves.where((m) => m.category == 'default' || m.category == 'Uncategorized').toList()
        : allMoves.where((m) => m.category == categoryName).toList();

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'category-back',
          label: 'Back',
          button: true,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
                  Text('Back', style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                ],
              ),
            ),
          ),
        ),
        title: Text(categoryName),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_outlined, size: 48, color: colorScheme.secondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No moves in $categoryName', style: AppTypography.bodyMedium.copyWith(color: colorScheme.secondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenEdge),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final move = filtered[index];
                final state = move.learningState.toLearningState();
                return _MoveRow(
                  move: move,
                  state: state,
                  onTap: () => context.push('/breakdex/move/${move.id}'),
                );
              },
            ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move, required this.state, required this.onTap});

  final Move move;
  final LearningState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(move.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    if (move.originalVideoName != null) ...[
                      const SizedBox(height: 2),
                      Text(move.originalVideoName!, style: AppTypography.caption.copyWith(color: colorScheme.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StatePill(state: state, showDisclosure: true),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  LearningState toLearningState() => switch (this) {
    'NEW' => LearningState.newState,
    'LEARNING' => LearningState.learning,
    'MASTERY' => LearningState.mastery,
    _ => LearningState.newState,
  };
}
