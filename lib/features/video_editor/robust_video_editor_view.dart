import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'robust_trim_timeline.dart';
import 'video_edit_geometry.dart';
import 'video_editor_controller.dart';

class RobustVideoEditorView extends StatefulWidget {
  const RobustVideoEditorView({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<RobustVideoEditorView> createState() => _RobustVideoEditorViewState();
}

class _RobustVideoEditorViewState extends State<RobustVideoEditorView> {
  final TransformationController _transformController = TransformationController();
  
  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.error != null) {
          // ... error handling
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(controller.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
              ],
            ),
          );
        }

        if (!controller.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final videoValue = controller.playerController!.value;
        final videoSize = videoValue.size;

        return Stack(
          children: [
            Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
                      ),
                      Text(
                        'EDIT VIDEO',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 2),
                      ),
                      TextButton(
                        onPressed: controller.isExporting ? null : () async {
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

                // Preview Area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenEdge),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final aspects = <double?>[
                            null, // Original
                            null, // Free Form
                            9 / 16,
                            16 / 9,
                            1 / 1,
                            4 / 5,
                            controller.customAspectRatio,
                          ];
                          final targetAspect = aspects[controller.selectedAspectIndex];

                          final viewport = computeVideoEditViewport(
                            videoSize: videoSize,
                            rotation: controller.rotation,
                            maxWidth: constraints.maxWidth,
                            maxHeight: constraints.maxHeight,
                            targetAspect: targetAspect,
                          );

                          // Reset matrix on transform change to keep it centered
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            final matrix = Matrix4.identity();
                            final isRotated = (controller.rotation / 90).round() % 2 != 0;
                            final orientedSize = isRotated 
                                ? Size(videoSize.height, videoSize.width)
                                : videoSize;
                            
                            final scale = viewport.size.width / orientedSize.width;
                            matrix.scale(scale);
                            
                            // Center the rotated video in the viewport
                            // Note: InteractiveViewer handles centering if constraints match
                            _transformController.value = matrix;
                          });

                          return Container(
                            width: viewport.size.width,
                            height: viewport.size.height,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black54, blurRadius: 12),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InteractiveViewer(
                              transformationController: _transformController,
                              minScale: viewport.minScale,
                              maxScale: viewport.maxScale,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              constrained: false,
                              child: Transform.rotate(
                                angle: controller.rotation * math.pi / 180,
                                child: SizedBox(
                                  width: videoSize.width,
                                  height: videoSize.height,
                                  child: VideoPlayer(controller.playerController!),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Controls Area
                Container(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                        videoDurationMs: controller.videoDuration.inMilliseconds,
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
                        onSelected: (i) {
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
                            icon: Icons.rotate_left_rounded,
                            label: 'Rotate Left',
                            onTap: () => controller.setRotation(controller.rotation - 90),
                          ),
                          Column(
                            children: [
                              Text('ROTATION', style: AppTypography.caption.copyWith(color: colorScheme.secondary)),
                              Text('${controller.rotation}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          _TransformBtn(
                            icon: Icons.rotate_right_rounded,
                            label: 'Rotate Right',
                            onTap: () => controller.setRotation(controller.rotation + 90),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (controller.isExporting)
              _buildExportOverlay(colorScheme),
          ],
        );
      },
    );
  }

  Widget _buildExportOverlay(ColorScheme colorScheme) {
    final progress = controller.exportProgress;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100, height: 100,
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

  void _showCustomAspectDialog(BuildContext context) {
    final controllerX = TextEditingController();
    final controllerY = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Aspect Ratio'),
        content: Row(
          children: [
            Expanded(child: TextField(controller: controllerX, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width'))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':')),
            Expanded(child: TextField(controller: controllerY, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final x = double.tryParse(controllerX.text);
              final y = double.tryParse(controllerY.text);
              if (x != null && y != null && y > 0) {
                controller.setAspect(6, custom: x / y);
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
    required String label,
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.sectionHeader.copyWith(color: colorScheme.secondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = i == selectedIndex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      items[i],
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  const _TransformBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }
}
