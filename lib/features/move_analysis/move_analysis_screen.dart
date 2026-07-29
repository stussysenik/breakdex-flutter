// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/models/pose_frame.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;
import 'package:breakdex/features/move_analysis/providers/analysis_providers.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/move_analysis/widgets/analysis_toolbar.dart';
import 'package:breakdex/features/move_analysis/widgets/pose_overlay.dart';
import 'package:breakdex/features/move_analysis/widgets/skeleton_3d_panel.dart';

/// Full-screen move analysis screen: video + 3D skeleton visualization.
///
/// **User flow:**
/// 1. From move detail → tap "Analyze" → opens this screen
/// 2. Video plays in top half, 3D skeleton renders in bottom half
/// 3. Each video frame → VisionML.detectPose() → Scene3D.updateSkeleton()
/// 4. Toggle to camera mode for live pose detection
/// 5. "BG" button → segmentPerson() for background removal
///
/// **Architecture:**
/// - Video playback is handled by `RobustVideoPlayer` (existing widget)
/// - Pose detection uses `VisionML` service (NativeBridge → Apple Vision)
/// - 3D rendering uses `Scene3DView` widget (PlatformView → SceneKit)
/// - State is managed via Riverpod providers in `analysis_providers.dart`
class MoveAnalysisScreen extends ConsumerStatefulWidget {
  const MoveAnalysisScreen({super.key, this.moveId, required this.videoPath});

  final String? moveId;
  final String videoPath;

  @override
  ConsumerState<MoveAnalysisScreen> createState() => _MoveAnalysisScreenState();
}

class _MoveAnalysisScreenState extends ConsumerState<MoveAnalysisScreen> {
  StreamSubscription<PoseFrame>? _livePoseSubscription;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _stopLivePose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final mode = ref.watch(analysisModeProvider);
    final pose = ref.watch(currentPoseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // When mode changes, manage live pose streaming
    ref.listen(analysisModeProvider, (final prev, final next) {
      if (next == AnalysisMode.camera) {
        _startLivePose();
      } else {
        _stopLivePose();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, colorScheme),

            // Main content: video + 3D split view
            Expanded(
              child: Column(
                children: [
                  // Top half: video with pose overlay
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.videoPath.isNotEmpty &&
                            mode == AnalysisMode.video)
                          RobustVideoPlayer(videoPath: widget.videoPath)
                        else if (mode == AnalysisMode.camera)
                          _buildCameraPlaceholder(colorScheme)
                        else
                          const VideoPlaceholder(icon: AppIcon.videoOff),

                        // Pose overlay on top of video
                        if (pose != null)
                          Positioned.fill(child: PoseOverlay(poseFrame: pose)),

                        // Analyze button (video mode)
                        if (mode == AnalysisMode.video &&
                            widget.videoPath.isNotEmpty)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _buildAnalyzeButton(colorScheme),
                          ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(height: 1, color: colorScheme.outline),

                  // Bottom half: 3D skeleton
                  const Expanded(child: Skeleton3DPanel()),
                ],
              ),
            ),

            // Toolbar
            const AnalysisToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    final BuildContext context,
    final ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdge,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              children: [
                AppIconView(
                  AppIcon.back,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                Text(
                  'Back',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Move Analysis',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Spacer to balance the back button
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder(final ColorScheme colorScheme) {
    final livePose = ref.watch(livePoseActiveProvider);

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              livePose
                  ? AppIcon.camera.resolve(context)
                  : AppIcon.camera.resolve(context),
              color: livePose
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              livePose ? 'Live Pose Detection Active' : 'Camera Mode',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
            if (livePose)
              Text(
                'Point camera at a person',
                style: AppTypography.caption.copyWith(color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(final ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _analyzeCurrentFrame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isAnalyzing
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isAnalyzing)
              const SizedBox(
                width: 14,
                height: 14,
                child: AppLoader(size: 6, color: Colors.white),
              )
            else
              const AppIconView(
                AppIcon.discover,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 6),
            Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze Pose',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Analyze a single frame from the video.
  Future<void> _analyzeCurrentFrame() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      // TODO: Extract current video frame as image bytes
      // For now, this is a placeholder — full implementation needs
      // video frame extraction via the native bridge
      await HapticFeedback.lightImpact();

      // Placeholder: In production, extract frame bytes and call:
      // final joints = await ref.read(visionMLProvider).detectPose(frameBytes);
      // ref.read(currentPoseProvider.notifier).state = PoseFrame(
      //   joints: joints,
      //   timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      //   overallConfidence: joints.isEmpty ? 0.0 :
      //     joints.map((j) => j.confidence).reduce((a, b) => a + b) / joints.length,
      // );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Start live camera pose detection.
  Future<void> _startLivePose() async {
    final visionML = ref.read(visionMLProvider);

    try {
      await visionML.startLivePose();
      ref.read(livePoseActiveProvider.notifier).state = true;

      unawaited(_livePoseSubscription?.cancel());
      _livePoseSubscription = visionML.livePoseStream.listen(
        (final frame) {
          if (mounted) {
            ref.read(currentPoseProvider.notifier).state = frame;
          }
        },
        onError: (final Object e) {
          debugPrint('[MoveAnalysis] Live pose error: $e');
          _stopLivePose();
        },
      );
    } on Object catch (e) {
      debugPrint('[MoveAnalysis] Failed to start live pose: $e');
    }
  }

  /// Stop live camera pose detection and clean up resources.
  void _stopLivePose() {
    _livePoseSubscription?.cancel();
    _livePoseSubscription = null;

    try {
      ref.read(visionMLProvider).stopLivePose();
      ref.read(livePoseActiveProvider.notifier).state = false;
    } on Object catch (_) {}
  }
}
