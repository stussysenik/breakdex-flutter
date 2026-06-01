import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../providers/analysis_providers.dart';

/// Toolbar at the bottom of the MoveAnalysisScreen.
///
/// Provides controls for:
/// - Mode toggle (Video / Camera)
/// - Background removal toggle
/// - Confidence indicator
class AnalysisToolbar extends ConsumerWidget {
  const AnalysisToolbar({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final mode = ref.watch(analysisModeProvider);
    final segActive = ref.watch(segmentationActiveProvider);
    final livePose = ref.watch(livePoseActiveProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdge,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Mode segmented control
            _ModeToggle(
              mode: mode,
              onChanged: (final m) =>
                  ref.read(analysisModeProvider.notifier).state = m,
            ),
            const Spacer(),
            // Background removal
            _ToolbarButton(
              icon: Icons.content_cut,
              label: 'BG',
              isActive: segActive,
              onTap: () => ref
                  .read(segmentationActiveProvider.notifier)
                  .state = !segActive,
            ),
            const SizedBox(width: AppSpacing.md),
            // Live indicator
            if (mode == AnalysisMode.camera)
              _LiveIndicator(isActive: livePose),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final AnalysisMode mode;
  final ValueChanged<AnalysisMode> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            label: 'Video',
            icon: Icons.videocam,
            isSelected: mode == AnalysisMode.video,
            onTap: () => onChanged(AnalysisMode.video),
          ),
          _SegmentButton(
            label: 'Camera',
            icon: Icons.camera_alt,
            isSelected: mode == AnalysisMode.camera,
            onTap: () => onChanged(AnalysisMode.camera),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : colorScheme.secondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isActive ? Theme.of(context).colorScheme.primary : colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Theme.of(context).colorScheme.primary : colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? Theme.of(context).colorScheme.primary : colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.actionAgain : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'LIVE' : 'OFF',
          style: AppTypography.caption.copyWith(
            color: isActive ? AppColors.actionAgain : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
