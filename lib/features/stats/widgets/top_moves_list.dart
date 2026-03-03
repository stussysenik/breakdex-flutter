import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';

class TopMovesList extends StatelessWidget {
  const TopMovesList({
    super.key,
    required this.topMoveEntries,
    required this.allMoves,
  });

  final List<MapEntry<String, int>> topMoveEntries;
  final List<Move> allMoves;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (topMoveEntries.isEmpty) {
      return Text('No reviews yet',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.secondary));
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < topMoveEntries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
            _MoveRow(
              rank: i + 1,
              moveId: topMoveEntries[i].key,
              count: topMoveEntries[i].value,
              allMoves: allMoves,
            ),
          ],
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.rank,
    required this.moveId,
    required this.count,
    required this.allMoves,
  });

  final int rank;
  final String moveId;
  final int count;
  final List<Move> allMoves;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final move = allMoves.where((m) => m.id == moveId).firstOrNull;
    final name = move?.name ?? 'Unknown';
    final state = move?.learningState ?? 'NEW';

    Color stateColor;
    switch (state) {
      case 'MASTERY':
        stateColor = AppColors.stateMastery;
        break;
      case 'LEARNING':
        stateColor = AppColors.stateLearning;
        break;
      default:
        stateColor = AppColors.stateNew;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.secondary,
                ),
          ),
        ],
      ),
    );
  }
}
