// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/scene_3d_view.dart';
import '../providers/analysis_providers.dart';

/// Panel showing the 3D skeleton visualization.
///
/// Embeds a SceneKit `Scene3DView` and auto-updates the skeleton
/// whenever `currentPoseProvider` changes. Includes an info bar
/// showing joint count and confidence.
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
    if (pose != null && pose.isUsable) {
      // Schedule after frame to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(scene3DProvider).updateSkeleton(pose.joints);
      });
    }

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.view_in_ar, size: 16, color: colorScheme.secondary),
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
        const Expanded(
          child: Scene3DView(
            backgroundColor: Colors.black,
          ),
        ),
      ],
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
