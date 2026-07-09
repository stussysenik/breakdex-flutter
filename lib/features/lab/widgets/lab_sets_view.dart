import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/app_loader.dart';
import '../providers/lab_providers.dart';

/// Sets view — shows labs filtered to labType='set' only.
///
/// Each set card shows the set name, linked move count, and a mini
/// horizontal preview of the first few move names as pills. This gives
/// the user a quick sense of each set's content without opening it.
///
/// Unlike the project list, sets emphasize sequencing — the move pills
/// appear in their sequenceIndex order, previewing the performance flow.
class LabSetsView extends ConsumerWidget {
  const LabSetsView({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final setsAsync = ref.watch(_setsStreamProvider);

    return setsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: AppLoader()),
      ),
      error: (final e, _) => SliverFillRemaining(
        child: Center(child: Text('Error: $e')),
      ),
      data: (final sets) {
        if (sets.isEmpty) {
          return const SliverFillRemaining(child: _SetsEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          sliver: SliverList.builder(
            itemCount: sets.length,
            itemBuilder: (_, final index) {
              final lab = sets[index];
              return _SetCard(
                lab: lab,
                onTap: () => context.push('/lab/${lab.id}'),
              )
                  .animate()
                  .fadeIn(
                    duration: AppMotion.moderate01,
                    delay: Duration(
                      milliseconds: index.clamp(0, 15) * 40,
                    ),
                  )
                  .slideY(
                    begin: 0.03,
                    duration: AppMotion.moderate02,
                    delay: Duration(
                      milliseconds: index.clamp(0, 15) * 40,
                    ),
                  );
            },
          ),
        );
      },
    );
  }
}

/// Stream provider for sets only — filters to labType='set'.
final _setsStreamProvider = StreamProvider<List<Lab>>((final ref) {
  return ref.watch(labsDaoProvider).watchByType('set');
});

// -- Set Card -----------------------------------------------------------------

/// A card for a single set, showing name, move count, and a horizontal
/// sequence preview (first 4-5 move names as compact pills).
class _SetCard extends ConsumerWidget {
  const _SetCard({required this.lab, this.onTap});

  final Lab lab;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final movesAsync = ref.watch(labMovesProvider(lab.id));
    final moves = movesAsync.valueOrNull ?? [];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSurfaces.panel(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + move count badge
            Row(
              children: [
                Icon(
                  Icons.playlist_play_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    lab.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${moves.length} move${moves.length == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Move sequence preview pills (first 5 moves)
            if (moves.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < moves.length && i < 5; i++) ...[
                      if (i > 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 8,
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          moves[i].move.name,
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (moves.length > 5) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+${moves.length - 5}',
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Metadata row: time
            const SizedBox(height: AppSpacing.sm),
            Text(
              relativeTime(lab.updatedAt),
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// -- Empty State --------------------------------------------------------------

class _SetsEmptyState extends StatelessWidget {
  const _SetsEmptyState();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.playlist_play_rounded,
            size: 64,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Create your first set',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Orchestrate your moves for performance',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
