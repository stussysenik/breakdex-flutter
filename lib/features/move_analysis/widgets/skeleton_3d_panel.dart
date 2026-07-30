// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/scene_3d_view.dart';
import 'package:breakdex/features/move_analysis/providers/analysis_providers.dart';
import 'package:breakdex/core/design/icons.dart';

/// Panel showing the 3D skeleton visualization.
///
/// Embeds a SceneKit `Scene3DView` and auto-updates the skeleton
/// whenever `currentPoseProvider` changes. Includes an info bar
/// showing joint count and confidence.
///
/// **Web:** renders an "Unavailable on web" placeholder — the 3D skeleton
/// depends on a native SceneKit platform view (UiKitView), which has no
/// web equivalent. The MethodChannel-based `Scene3D` service hooks are
/// also skipped to avoid `MissingPluginException`.
class Skeleton3DPanel extends ConsumerStatefulWidget {
  const Skeleton3DPanel({super.key});

  @override
  ConsumerState<Skeleton3DPanel> createState() => _Skeleton3DPanelState();
}

class _Skeleton3DPanelState extends ConsumerState<Skeleton3DPanel> {
  @override
  void initState() {
    super.initState();
    // Scene3D updates are driven by watching currentPoseProvider in build()
  }

  @override
  Widget build(final BuildContext context) {
    final pose = ref.watch(currentPoseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Push skeleton updates to native when pose changes
    if (pose != null && pose.isUsable && !kIsWeb) {
      // Schedule after frame to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(scene3DProvider).updateSkeleton(pose.joints);
      });
    }

    if (kIsWeb) {
      return _webPlaceholder();
    }

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              AppIconView(
                AppIcon.discover,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                '3D Skeleton',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (pose != null) ...[
                Text(
                  '${pose.joints.where((final j) => j.isConfident).length} joints',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceDot(confidence: pose.overallConfidence),
              ],
            ],
          ),
        ),
        // 3D view
        const Expanded(child: Scene3DView(backgroundColor: Colors.black)),
      ],
    );
  }

  Widget _webPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconView(AppIcon.discover, size: 24, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '3D skeleton view unavailable on web',
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Small colored dot indicating overall pose confidence.
class _ConfidenceDot extends StatelessWidget {
  const _ConfidenceDot({required this.confidence});

  final double confidence;

  @override
  Widget build(final BuildContext context) {
    final color = confidence > 0.7
        ? AppColors.actionGood
        : confidence > 0.4
        ? AppColors.actionHard
        : AppColors.actionAgain;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '${(confidence * 100).round()}%',
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
