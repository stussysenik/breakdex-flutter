import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/lab/providers/lab_providers.dart';
import 'package:breakdex/features/lab/widgets/lab_card.dart';
import 'package:breakdex/core/design/icons.dart';

/// List view of labs, ordered by most recently updated.
///
/// Watches [labsStreamProvider] (or a type-filtered stream when
/// [labTypeFilter] is set) for real-time updates. Each lab is rendered
/// as a [LabCard] with staggered entrance animation matching the Arsenal
/// tab's list behavior.
///
/// **labTypeFilter**: when set to 'project' or 'set', only labs of that
/// type are shown. When null, all labs are displayed (backward compat).
class LabListView extends ConsumerWidget {
  const LabListView({super.key, this.labTypeFilter});

  /// Optional filter: 'project', 'set', or null (show all).
  final String? labTypeFilter;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Use the type-filtered stream when a filter is active, otherwise all labs.
    final labsAsync = labTypeFilter != null
        ? ref.watch(_labsByTypeProvider(labTypeFilter!))
        : ref.watch(labsStreamProvider);

    return labsAsync.when(
      loading: () =>
          const SliverFillRemaining(child: Center(child: AppLoader())),
      error: (final e, _) =>
          SliverFillRemaining(child: Center(child: Text('Error: $e'))),
      data: (final labs) {
        if (labs.isEmpty) {
          return SliverFillRemaining(
            child: _LabEmptyState(labType: labTypeFilter),
          );
        }

        // No horizontal padding here: the frame's content band already
        // supplies the gutter, and re-applying it doubles the inset.
        return SliverList.builder(
          itemCount: labs.length,
          itemBuilder: (_, final index) {
            final lab = labs[index];
            return LabCard(
                  lab: lab,
                  onTap: () => context.push('/lab/${lab.id}'),
                )
                .animate()
                .fadeIn(
                  duration: AppMotion.moderate01,
                  delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                )
                .slideY(
                  begin: 0.03,
                  duration: AppMotion.moderate02,
                  delay: Duration(milliseconds: index.clamp(0, 15) * 40),
                );
          },
        );
      },
    );
  }
}

/// Type-filtered stream provider — watches [LabsDao.watchByType] for a
/// specific labType ('project' or 'set').
final _labsByTypeProvider = StreamProvider.family<List<Lab>, String>((
  final ref,
  final labType,
) {
  return ref.watch(labsDaoProvider).watchByType(labType);
});

// -- Empty State --------------------------------------------------------------

class _LabEmptyState extends StatelessWidget {
  const _LabEmptyState({this.labType});

  final String? labType;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, title, subtitle) = switch (labType) {
      'project' => (
        AppIcon.lab.resolve(context),
        'No projects yet',
        'Start your first training project',
      ),
      'set' => (
        AppIcon.combo.resolve(context),
        'No sets yet',
        'Start your first set',
      ),
      _ => (
        AppIcon.lab.resolve(context),
        'No labs yet',
        'Start your first lab',
      ),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
