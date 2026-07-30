import 'dart:async';
import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/sync/space_manager.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';

/// Provider for space analysis — refreshes when this screen is opened.
final spaceAnalysisProvider = FutureProvider<SpaceAnalysis>((final ref) {
  return ref.watch(spaceManagerProvider).analyze();
});

/// Screen showing freeable storage with a one-tap "Free All" action.
///
/// Only assets with ≥1 verified cloud copy are eligible for local deletion.
/// SafetyGuard + circuit breaker prevent unsafe bulk deletions.
class FreeSpaceScreen extends ConsumerStatefulWidget {
  const FreeSpaceScreen({super.key});

  @override
  ConsumerState<FreeSpaceScreen> createState() => _FreeSpaceScreenState();
}

class _FreeSpaceScreenState extends ConsumerState<FreeSpaceScreen> {
  bool _freeing = false;
  int? _freedBytes;

  @override
  Widget build(final BuildContext context) {
    final analysis = ref.watch(spaceAnalysisProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Free Up Space',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: analysis.when(
        loading: () => const Center(child: AppLoader()),
        error: (final e, _) => Center(
          child: Text(
            'Could not analyze storage: $e',
            style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
          ),
        ),
        data: (final data) => _buildContent(context, data, colorScheme),
      ),
    );
  }

  Widget _buildContent(
    final BuildContext context,
    final SpaceAnalysis analysis,
    final ColorScheme colorScheme,
  ) {
    final freeableMb = (analysis.freeableBytes / (1024 * 1024)).toStringAsFixed(
      1,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              AppIconView(
                analysis.canFree ? AppIcon.cloudDone : AppIcon.success,
                size: 48,
                color: analysis.canFree
                    ? Theme.of(context).colorScheme.primary
                    : AppSemanticTheme.of(context).stateMastery,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                analysis.canFree ? '$freeableMb MB' : 'All Clear',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                analysis.canFree
                    ? '${analysis.freeableHashes.length} videos can be freed safely'
                    : 'No videos can be freed right now',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Explanation
        Text(
          'Videos with at least one verified cloud backup can have their '
          'local copy removed. You can re-download them anytime from your '
          'cloud storage.',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Stats
        _StatRow(
          label: 'Cloud-backed videos',
          value: '${analysis.totalSyncedAssets}',
          colorScheme: colorScheme,
        ),
        _StatRow(
          label: 'Freeable videos',
          value: '${analysis.freeableHashes.length}',
          colorScheme: colorScheme,
        ),
        _StatRow(
          label: 'Space to recover',
          value: '$freeableMb MB',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Result message
        if (_freedBytes != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppSemanticTheme.of(context).stateMastery.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                AppIconView(
                  AppIcon.success,
                  color: AppSemanticTheme.of(context).stateMastery,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Freed ${(_freedBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppSemanticTheme.of(context).stateMastery,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Free All button
        if (analysis.canFree)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _freeing ? null : () => _freeAll(analysis),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: _freeing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AppLoader(size: 6, color: Colors.white),
                    )
                  : Text(
                      'Free $freeableMb MB',
                      style: AppTypography.bodySmall.merge(
                        const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _freeAll(final SpaceAnalysis analysis) async {
    // Safety confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Free Up Space?'),
        content: Text(
          'This will delete ${analysis.freeableHashes.length} local video files '
          'that have verified cloud backups. You can re-download them anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Free Space'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _freeing = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      final freed = await ref
          .read(spaceManagerProvider)
          .freeSpace(analysis.freeableHashes);

      if (mounted) {
        setState(() {
          _freeing = false;
          _freedBytes = freed;
        });
        // Refresh analysis
        ref.invalidate(spaceAnalysisProvider);
        await HapticFeedback.heavyImpact();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _freeing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to free space: $e')));
      }
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall
                .merge(const TextStyle(fontWeight: FontWeight.w600))
                .copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
