// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/video_editor/robust_trim_timeline.dart';
import 'package:breakdex/features/video_editor/video_edit_geometry.dart';
import 'package:breakdex/features/video_editor/video_editor_controller.dart';
import 'package:breakdex/core/design/icons.dart';

class RobustVideoEditorView extends StatefulWidget {
  const RobustVideoEditorView({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<RobustVideoEditorView> createState() => _RobustVideoEditorViewState();
}

class _RobustVideoEditorViewState extends State<RobustVideoEditorView> {
  final TransformationController _transformController =
      TransformationController();
  bool _isPreviewMode = false;
  VideoEditViewport? _currentViewport;
  Size? _appliedViewportSize;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Re-frames the crop window whenever the viewport changes (first layout,
  /// aspect-ratio change, or rotation). Mutating the [TransformationController]
  /// or calling [updateCrop] (which notifies listeners) *during* build is
  /// illegal in Flutter and was the cause of the erratic crop jumps, so the
  /// reset + crop sync is deferred to after the frame.
  void _scheduleViewportSync(final VideoEditViewport viewport) {
    if (_appliedViewportSize == viewport.size) return;
    final isFirstLayout = _appliedViewportSize == null;
    _appliedViewportSize = viewport.size;

    // First layout: set synchronously so the very first frame is framed
    // correctly (no listeners attached yet, so this is safe and flash-free).
    if (isFirstLayout) {
      _transformController.value = viewport.initialTransform();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!isFirstLayout) {
        _transformController.value = viewport.initialTransform();
      }
      _syncCropToController();
    });
  }

  void _syncCropToController() {
    final viewport = _currentViewport;
    if (viewport == null) return;
    final crop = viewport.normalizedCropRect(_transformController.value);
    DiagnosticsLog.info(
      'VideoEditor',
      'Syncing crop to controller: ${crop.left.toStringAsFixed(3)},${crop.top.toStringAsFixed(3)}',
    );
    widget.controller.updateCrop(crop);
  }

  void _applyClamping() {
    final viewport = _currentViewport;
    if (viewport == null) return;
    final currentTransform = _transformController.value;
    final clamped = viewport.clampTransform(currentTransform);
    if (!matrixCloseTo(currentTransform, clamped)) {
      _transformController.value = clamped;
    }
  }

  static const _speeds = ['0.25x', '0.5x', '1x', '1.5x', '2x'];
  static const _aspects = [
    'Original',
    'Free Form',
    '9:16',
    '16:9',
    '1:1',
    '4:5',
    'Custom...',
  ];

  @override
  Widget build(final BuildContext context) {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (final context, _) {
        final status = controller.status;

        if (status is EditorError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIconView(AppIcon.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'EXPORT FAILED',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.red,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status.message,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                    child: const Text('Back to Gallery'),
                  ),
                ],
              ),
            ),
          );
        }

        if (status is EditorInitializing ||
            controller.playerController == null) {
          return const Center(child: AppLoader());
        }

        final videoValue = controller.playerController!.value;
        final videoSize = videoValue.size;

        return Stack(
          children: [
            Column(
              children: [
                // Top Bar
                AnimatedContainer(
                  duration: AppMotion.moderate02,
                  height: _isPreviewMode ? 0 : null,
                  decoration: const BoxDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (controller.hasUnsavedChanges)
                          TextButton(
                            onPressed: controller.revertToCommitted,
                            child: Text(
                              'Discard',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: colorScheme.secondary),
                            ),
                          ),
                        Text(
                          'EDIT VIDEO',
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.onSurface,
                            letterSpacing: 2,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.isExporting
                              ? null
                              : () async {
                                  controller.commitEdits();
                                  final result = await controller.export();
                                  if (result != null && context.mounted) {
                                    Navigator.of(context).pop(result);
                                  }
                                },
                          child: Text(
                            'SAVE',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Preview Area
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(
                            _isPreviewMode ? 0 : AppSpacing.screenEdge,
                          ),
                          child: LayoutBuilder(
                            builder: (final context, final constraints) {
                              final aspects = <double?>[
                                null, // Original
                                null, // Free Form
                                9 / 16,
                                16 / 9,
                                1 / 1,
                                4 / 5,
                                controller.customAspectRatio,
                              ];
                              final targetAspect =
                                  aspects[controller.selectedAspectIndex];

                              final viewport = computeVideoEditViewport(
                                videoSize: videoSize,
                                rotation: controller.rotation,
                                maxWidth: constraints.maxWidth,
                                maxHeight: constraints.maxHeight,
                                targetAspect: targetAspect,
                              );

                              _currentViewport = viewport;
                              _scheduleViewportSync(viewport);

                              return AnimatedContainer(
                                duration: AppMotion.moderate02,
                                curve: AppMotion.fluid,
                                width: viewport.size.width,
                                height: viewport.size.height,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(
                                    _isPreviewMode ? 0 : AppRadius.md,
                                  ),
                                  border: _isPreviewMode
                                      ? null
                                      : Border.all(
                                          color: colorScheme.outlineVariant,
                                          width: 1.5,
                                        ),
                                  boxShadow: _isPreviewMode
                                      ? null
                                      : const [
                                          BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 12,
                                          ),
                                        ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    GestureDetector(
                                      onTap: controller.togglePlay,
                                      child: InteractiveViewer(
                                        transformationController:
                                            _transformController,
                                        minScale: viewport.minScale,
                                        maxScale: viewport.maxScale,
                                        boundaryMargin: const EdgeInsets.all(
                                          double.infinity,
                                        ),
                                        constrained: false,
                                        // Clamp + sync the crop only when the
                                        // gesture ends. Clamping mid-gesture
                                        // overwrites the matrix the gesture is
                                        // still reading from, which makes
                                        // pinch/pan jitter.
                                        onInteractionEnd: (_) {
                                          _applyClamping();
                                          _syncCropToController();
                                        },
                                        child: Center(
                                          child: RotatedBox(
                                            quarterTurns:
                                                (controller.rotation % 360) ~/
                                                90,
                                            child: SizedBox(
                                              width: videoSize.width,
                                              height: videoSize.height,
                                              child: VideoPlayer(
                                                controller.playerController!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Rule-of-thirds framing guide over the crop
                                    // window (hidden in full-screen preview).
                                    if (!_isPreviewMode)
                                      const IgnorePointer(
                                        child: CustomPaint(
                                          painter: _CropGridPainter(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Preview Toggle Button - Moved to Top Right
                      Positioned(
                        top: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: FloatingActionButton.small(
                          onPressed: () =>
                              setState(() => _isPreviewMode = !_isPreviewMode),
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                          child: Icon(
                            _isPreviewMode
                                ? AppIcon.edit.resolve(context)
                                : AppIcon.glance.resolve(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls Area
                AnimatedContainer(
                  duration: AppMotion.moderate02,
                  height: _isPreviewMode ? 0 : null,
                  decoration: const BoxDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdge,
                      AppSpacing.lg,
                      AppSpacing.screenEdge,
                      AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RobustTrimTimeline(
                          trimStart: controller.trimStart,
                          trimEnd: controller.trimEnd,
                          playbackPosition: controller.playbackPosition,
                          isPlaying: controller.isPlaying,
                          thumbnails: controller.thumbnails,
                          videoDurationMs:
                              controller.videoDuration.inMilliseconds,
                          onTrimChanged: controller.updateTrim,
                          onPlayheadChanged: controller.seekToNormalized,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPillSelector(
                          label: 'SPEED',
                          items: _speeds,
                          selectedIndex: controller.selectedSpeedIndex,
                          onSelected: controller.setSpeed,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPillSelector(
                          label: 'ASPECT RATIO',
                          items: _aspects,
                          selectedIndex: controller.selectedAspectIndex,
                          onSelected: (final i) {
                            if (i == 6) {
                              _showCustomAspectDialog(context);
                            } else {
                              controller.setAspect(i);
                            }
                          },
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _TransformBtn(
                              icon: AppIcon.replay.resolve(context),
                              label: 'Rotate Left',
                              onTap: () => controller.setRotation(
                                controller.rotation - 90,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'ROTATION',
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                Text(
                                  '${controller.rotation}°',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            _TransformBtn(
                              icon: AppIcon.refresh.resolve(context),
                              label: 'Rotate Right',
                              onTap: () => controller.setRotation(
                                controller.rotation + 90,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (controller.isExporting) _buildExportOverlay(colorScheme),
          ],
        );
      },
    );
  }

  Widget _buildExportOverlay(final ColorScheme colorScheme) {
    final progress = widget.controller.exportProgress;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: progress?.progress,
                strokeWidth: 6,
                color: colorScheme.primary,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              progress?.displayText ?? 'Preparing Export...',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress.progress * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCustomAspectDialog(final BuildContext context) {
    final controllerX = TextEditingController();
    final controllerY = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Custom Aspect Ratio'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllerX,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Width'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(':'),
            ),
            Expanded(
              child: TextField(
                controller: controllerY,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final x = double.tryParse(controllerX.text);
              final y = double.tryParse(controllerY.text);
              if (x != null && y != null && y > 0) {
                widget.controller.setAspect(6, custom: x / y);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSelector({
    required final String label,
    required final List<String> items,
    required final int selectedIndex,
    required final ValueChanged<int> onSelected,
    required final ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (final context, final i) {
              final isSelected = i == selectedIndex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      items[i],
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransformBtn extends StatelessWidget {
  const _TransformBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        ),
      ],
    );
  }
}

/// Rule-of-thirds overlay drawn on top of the crop window to help frame the
/// content that will be kept. Purely visual — never intercepts gestures.
class _CropGridPainter extends CustomPainter {
  const _CropGridPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(final _CropGridPainter oldDelegate) => false;
}
