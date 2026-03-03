import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/native_video_export.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  int _selectedSpeedIndex = 2; // 1x default
  int _rotation = 0; // 0, 90, 180, 270
  int _selectedAspectIndex = 0; // Original
  bool _exporting = false;
  ExportProgress? _exportProgress;
  StreamSubscription<ExportProgress>? _progressSub;

  Duration _videoDuration = Duration.zero;
  VideoPlayerController? _controller;
  List<Uint8List?> _thumbnails = [];

  static const _speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
  static const _speedLabels = ['0.25x', '0.5x', '1x', '1.5x', '2x'];

  static const _aspectLabels = ['Original', '9:16', '16:9', '1:1', '4:5'];
  static const _aspectRatios = <double?>[null, 9 / 16, 16 / 9, 1.0, 4 / 5];
  static const _aspectRatioStrings = <String?>[
    null, '9:16', '16:9', '1:1', '4:5',
  ];

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(File(widget.videoPath));
    await controller.initialize();
    if (mounted) {
      setState(() {
        _controller = controller;
        _videoDuration = controller.value.duration;
      });
      controller.setLooping(true);
      _generateThumbnails();
    }
  }

  Future<void> _generateThumbnails() async {
    final thumbs = <Uint8List?>[];
    for (int i = 0; i < 8; i++) {
      try {
        final ms = (_videoDuration.inMilliseconds > 0)
            ? (_videoDuration.inMilliseconds * i / 8).round()
            : i * 500;
        final data = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxWidth: 80,
          quality: 50,
        );
        thumbs.add(data);
      } catch (_) {
        thumbs.add(null);
      }
    }
    if (mounted) setState(() => _thumbnails = thumbs);
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _exporting
                            ? () async {
                                await NativeVideoExport.cancel();
                                if (mounted) {
                                  setState(() => _exporting = false);
                                }
                              }
                            : () => context.pop(),
                        child: Text(
                          _exporting ? 'Cancel Export' : 'Cancel',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _exporting
                                ? AppColors.actionAgain
                                : colorScheme.secondary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _exporting ? null : _export,
                        child: Text(
                          'Export',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _exporting
                                ? colorScheme.secondary
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Video preview
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdge),
                  child: _buildVideoPreview(colorScheme),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Scrollable controls
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Column(
                      children: [
                        // Trim timeline
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenEdge),
                          child: _TrimTimeline(
                            trimStart: _trimStart,
                            trimEnd: _trimEnd,
                            thumbnails: _thumbnails,
                            onChanged: (start, end) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _trimStart = start;
                                _trimEnd = end;
                              });
                            },
                          ),
                        ),

                        // Trim labels
                        if (_videoDuration.inMilliseconds > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenEdge),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                      _trimStart *
                                          _videoDuration.inMilliseconds),
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                Text(
                                  _formatDuration(
                                      _trimEnd *
                                          _videoDuration.inMilliseconds),
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),

                        // Speed
                        _buildPillSelector(
                          context,
                          label: 'SPEED',
                          items: _speedLabels,
                          selectedIndex: _selectedSpeedIndex,
                          onSelected: (i) =>
                              setState(() => _selectedSpeedIndex = i),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Transform
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenEdge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSFORM',
                                style: AppTypography.sectionHeader.copyWith(
                                  color: colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  _TransformButton(
                                    icon: Icons.rotate_left,
                                    active: _rotation != 0,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() =>
                                          _rotation = (_rotation - 90) % 360);
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _TransformButton(
                                    icon: Icons.rotate_right,
                                    active: _rotation != 0,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() =>
                                          _rotation = (_rotation + 90) % 360);
                                    },
                                  ),
                                ],
                              ),
                              if (_rotation != 0) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Rotation: $_rotation°',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Aspect Ratio
                        _buildPillSelector(
                          context,
                          label: 'ASPECT RATIO',
                          items: _aspectLabels,
                          selectedIndex: _selectedAspectIndex,
                          onSelected: (i) =>
                              setState(() => _selectedAspectIndex = i),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Export overlay with real-time progress
            if (_exporting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _exportProgress?.progress,
                              color: AppColors.accent,
                              strokeWidth: 4,
                              backgroundColor: Colors.white24,
                            ),
                            Center(
                              child: Text(
                                _exportProgress != null
                                    ? '${(_exportProgress!.progress * 100).round()}%'
                                    : '...',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _exportProgress?.displayText ?? 'Preparing...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Using Apple AVFoundation',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillSelector(
    BuildContext context, {
    required String label,
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(i);
                  },
                  child: Container(
                    margin:
                        EdgeInsets.only(left: i > 0 ? AppSpacing.sm : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        items[i],
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(ColorScheme colorScheme) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final targetAspect = _aspectRatios[_selectedAspectIndex];

    Widget videoContent = SizedBox(
      width: _controller!.value.size.width,
      height: _controller!.value.size.height,
      child: VideoPlayer(_controller!),
    );

    if (targetAspect != null) {
      videoContent = AspectRatio(
        aspectRatio: targetAspect,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: Transform.rotate(
              angle: _rotation * 3.14159265 / 180,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        ),
      );
    } else {
      videoContent = Transform.rotate(
        angle: _rotation * 3.14159265 / 180,
        child: FittedBox(
          fit: BoxFit.cover,
          child: videoContent,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _controller!.value.isPlaying
                ? _controller!.pause()
                : _controller!.play();
          });
        },
        child: Container(
          height: 300,
          width: double.infinity,
          color: AppColors.darkBg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: videoContent),
              if (!_controller!.value.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white70,
                    size: 64,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(double ms) {
    final d = Duration(milliseconds: ms.round());
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _exportProgress = null;
    });

    // Pause video during export
    _controller?.pause();

    // Listen to progress stream
    _progressSub = NativeVideoExport.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _exportProgress = progress);
      }
    });

    try {
      final docs = await getApplicationDocumentsDirectory();
      final movesDir = Directory(p.join(docs.path, 'Moves'));
      if (!await movesDir.exists()) {
        await movesDir.create(recursive: true);
      }

      final outputPath = p.join(movesDir.path, '${const Uuid().v4()}.mp4');

      final trimStartMs = (_trimStart * _videoDuration.inMilliseconds).round();
      final trimEndMs = (_trimEnd * _videoDuration.inMilliseconds).round();
      final speed = _speeds[_selectedSpeedIndex];
      final normalizedRotation = ((_rotation % 360) + 360) % 360;

      final result = await NativeVideoExport.export(
        inputPath: widget.videoPath,
        outputPath: outputPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        speed: speed,
        rotation: normalizedRotation,
        aspectRatio: _aspectRatioStrings[_selectedAspectIndex],
      );

      HapticFeedback.heavyImpact();
      if (mounted) context.pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportProgress = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      _progressSub?.cancel();
      _progressSub = null;
    }
  }
}

class _TrimTimeline extends StatelessWidget {
  const _TrimTimeline({
    required this.trimStart,
    required this.trimEnd,
    required this.thumbnails,
    required this.onChanged,
  });

  final double trimStart;
  final double trimEnd;
  final List<Uint8List?> thumbnails;
  final void Function(double start, double end) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Stack(
        children: [
          Row(
            children: List.generate(
              8,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.darkFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: (i < thumbnails.length && thumbnails[i] != null)
                      ? Image.memory(
                          thumbnails[i]!,
                          fit: BoxFit.cover,
                          height: 52,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Positioned(
            left: trimStart *
                (MediaQuery.of(context).size.width -
                    AppSpacing.screenEdge * 2),
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                final width = MediaQuery.of(context).size.width -
                    AppSpacing.screenEdge * 2;
                final newStart =
                    (trimStart + d.delta.dx / width).clamp(0.0, trimEnd - 0.1);
                onChanged(newStart, trimEnd);
              },
              child: Container(
                width: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(6),
                  ),
                ),
                child: const Center(
                  child:
                      Icon(Icons.drag_indicator, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            right: (1 - trimEnd) *
                (MediaQuery.of(context).size.width -
                    AppSpacing.screenEdge * 2),
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                final width = MediaQuery.of(context).size.width -
                    AppSpacing.screenEdge * 2;
                final newEnd = (trimEnd + d.delta.dx / width)
                    .clamp(trimStart + 0.1, 1.0);
                onChanged(trimStart, newEnd);
              },
              child: Container(
                width: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(6),
                  ),
                ),
                child: const Center(
                  child:
                      Icon(Icons.drag_indicator, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: (trimStart + trimEnd) /
                    2 *
                    (MediaQuery.of(context).size.width -
                        AppSpacing.screenEdge * 2) -
                1,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransformButton extends StatelessWidget {
  const _TransformButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fill = active
        ? AppColors.accent.withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: active
              ? Border.all(color: AppColors.accent, width: 1.5)
              : null,
        ),
        child: Icon(icon,
            color: active
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
