import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/features/lab/widgets/lab_card.dart';

/// Kanban-style board view with 4 horizontal-scroll columns:
/// Idea, Attempting, Landed, Clean.
///
/// Each column shows labs filtered by status, rendered as compact [LabCard]s.
/// The board scrolls horizontally so all columns remain visible even on
/// smaller screens. This mirrors Trello/Linear board UX patterns familiar
/// to product engineers.
class LabBoardView extends ConsumerWidget {
  const LabBoardView({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final labsAsync = ref.watch(labsStreamProvider);

    return labsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: AppLoader()),
      ),
      error: (final e, _) => SliverFillRemaining(
        child: Center(child: Text('Error: $e')),
      ),
      data: (final labs) {
        // Bucket labs by status for the 4 columns.
        final Map<String, List<Lab>> buckets = {
          'idea': [],
          'attempting': [],
          'landed': [],
          'clean': [],
        };
        for (final lab in labs) {
          final bucket = buckets[lab.status];
          if (bucket != null) {
            bucket.add(lab);
          } else {
            // Unknown status → default to idea column
            buckets['idea']!.add(lab);
          }
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            // Fixed height for the board area — enough for ~5 compact cards.
            height: MediaQuery.of(context).size.height * 0.6,
            // The board scrolls horizontally *inside* the frame's content
            // column, so the gutter is already applied by the frame.
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _BoardColumn(
                  title: 'Idea',
                  color: const Color(0xFFA7B1C2),
                  labs: buckets['idea']!,
                ),
                const SizedBox(width: AppSpacing.sm),
                _BoardColumn(
                  title: 'Attempting',
                  color: AppSemanticTheme.of(context).stateLearning,
                  labs: buckets['attempting']!,
                ),
                const SizedBox(width: AppSpacing.sm),
                _BoardColumn(
                  title: 'Landed',
                  color: AppSemanticTheme.of(context).stateMastery,
                  labs: buckets['landed']!,
                ),
                const SizedBox(width: AppSpacing.sm),
                _BoardColumn(
                  title: 'Clean',
                  color: const Color(0xFF0D9F9A),
                  labs: buckets['clean']!,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -- Board Column -------------------------------------------------------------

/// A single kanban column with a colored header and vertical list of cards.
class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.title,
    required this.color,
    required this.labs,
  });

  final String title;
  final Color color;
  final List<Lab> labs;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header with colored accent
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sm),
              ),
              border: Border(
                top: BorderSide(color: color, width: 2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${labs.length}',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Cards list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.sm),
                ),
              ),
              child: labs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No labs',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      itemCount: labs.length,
                      itemBuilder: (final context, final index) {
                        final lab = labs[index];
                        return LabCard(
                          lab: lab,
                          compact: true,
                          onTap: () => context.push('/lab/${lab.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
