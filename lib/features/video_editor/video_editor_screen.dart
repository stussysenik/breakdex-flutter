import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
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
  bool _matrixInitialized = false;
  double _viewW = 300.0;
  double _viewH = 300.0;
  
  final TransformationController _transformController = TransformationController();
  bool _exporting = false;
  ExportProgress? _exportProgress;
  StreamSubscription<ExportProgress>? _progressSub;

  Duration _videoDuration = Duration.zero;
  VideoPlayerController? _controller;
  List<Uint8List?> _thumbnails = [];

  static const _speeds = [0.25, 0.5, 1.0, 1.5, 2.0];
  static const _speedLabels = ['0.25x', '0.5x', '1x', '1.5x', '2x'];

  static const _aspectLabels = [
    'Original',
    'Free Form',
    '9:16',
    '16:9',
    '1:1',
    '4:5',
  ];
  static const _aspectRatios = <double?>[
    null, // Original
    null, // Free Form (uses dynamic bounding rect)
    9 / 16,
    16 / 9,
    1.0,
    4 / 5,
  ];

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load video: $e')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
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
    _transformController.dispose();
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
                    horizontal: AppSpacing.screenEdge,
                  ),
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
                            horizontal: AppSpacing.screenEdge,
                          ),
                          child: _TrimTimeline(
                            trimStart: _trimStart,
                            trimEnd: _trimEnd,
                            thumbnails: _thumbnails,
                            videoPath: widget.videoPath,
                            videoDurationMs: _videoDuration.inMilliseconds,
                            onChanged: (start, end) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _trimStart = start;
                                _trimEnd = end;
                              });
                            },
                            onPlayheadChanged: (position) {
                              // Pause during scrubbing for instant frame preview
                              if (_controller?.value.isPlaying ?? false) {
                                _controller?.pause();
                              }
                              final ms =
                                  (position * _videoDuration.inMilliseconds)
                                      .round();
                              _controller?.seekTo(Duration(milliseconds: ms));
                            },
                          ),
                        ),

                        // Trim labels
                        if (_videoDuration.inMilliseconds > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenEdge,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                    _trimStart * _videoDuration.inMilliseconds,
                                  ),
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                Text(
                                  _formatDuration(
                                    _trimEnd * _videoDuration.inMilliseconds,
                                  ),
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
                          onSelected: (i) {
                            setState(() => _selectedSpeedIndex = i);
                            _controller?.setPlaybackSpeed(_speeds[i]);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Transform
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenEdge,
                          ),
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
                                      setState(() {
                                        _rotation = (_rotation - 90) % 360;
                                        _matrixInitialized = false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _TransformButton(
                                    icon: Icons.rotate_right,
                                    active: _rotation != 0,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        _rotation = (_rotation + 90) % 360;
                                        _matrixInitialized = false;
                                      });
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
                          onSelected: (i) {
                            setState(() {
                              _selectedAspectIndex = i;
                              _matrixInitialized = false;
                            });
                          },
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
                              // Indeterminate when initializing, determinate when encoding
                              value: (_exportProgress?.isInitializing ?? true)
                                  ? null
                                  : _exportProgress?.progress,
                              color: _exportProgress?.isStalled == true
                                  ? AppColors.actionHard
                                  : AppColors.accent,
                              strokeWidth: 4,
                              backgroundColor: Colors.white24,
                            ),
                            if (_exportProgress != null &&
                                !_exportProgress!.isInitializing)
                              Center(
                                child: Text(
                                  '${(_exportProgress!.progress * 100).round()}%',
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
                      if (_exportProgress?.isStalled == true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Export may be slow on this device',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.actionHard,
                          ),
                        ),
                      ],
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
                    margin: EdgeInsets.only(left: i > 0 ? AppSpacing.sm : 0),
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

    const playOverlay = Center(
      child: Icon(Icons.play_circle_filled, color: Colors.white70, size: 64),
    );

    final targetAspect = _aspectRatios[_selectedAspectIndex];
    final videoSize = _controller!.value.size;
    final isRotated = _rotation == 90 || _rotation == 270;
    final orientedWidth = isRotated ? videoSize.height : videoSize.width;
    final orientedHeight = isRotated ? videoSize.width : videoSize.height;

    Widget rawVideo = SizedBox(
      width: videoSize.width,
      height: videoSize.height,
      child: VideoPlayer(_controller!),
    );
    if (_rotation != 0) {
      rawVideo = Transform.rotate(
        angle: _rotation * 3.14159265 / 180,
        child: rawVideo,
      );
    }

    final videoContent = SizedBox(
      width: orientedWidth,
      height: orientedHeight,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: rawVideo,
        ),
      ),
    );

    if (targetAspect != null || _aspectLabels[_selectedAspectIndex] == 'Free Form') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          const maxH = 300.0;
          
          if (targetAspect != null) {
            if (maxW / maxH > targetAspect) {
              _viewH = maxH;
              _viewW = _viewH * targetAspect;
            } else {
              _viewW = maxW;
              _viewH = _viewW / targetAspect;
            }
          } else {
            // Free Form uses full available space for the crop window initially
            _viewW = maxW;
            _viewH = maxH;
          }
          
          final minScale = math.max(_viewW / orientedWidth, _viewH / orientedHeight);
          
          if (!_matrixInitialized) {
            final dx = (_viewW - orientedWidth * minScale) / 2;
            final dy = (_viewH - orientedHeight * minScale) / 2;
            _transformController.value = Matrix4.identity()
              ..translate(dx, dy)
              ..scale(minScale);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _matrixInitialized = true);
            });
          }
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 300,
              width: double.infinity,
              color: AppColors.darkBg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      width: _viewW,
                      height: _viewH,
                      child: ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: minScale,
                          maxScale: minScale * 4.0,
                          boundaryMargin: EdgeInsets.zero,
                          constrained: false,
                          onInteractionEnd: (_) => setState((){}),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                              });
                            },
                            child: videoContent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_controller!.value.isPlaying) playOverlay,
                  if (_aspectLabels[_selectedAspectIndex] == 'Free Form' || targetAspect != null)
                    IgnorePointer(
                      child: Container(
                        width: _viewW,
                        height: _viewH,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
            });
          },
          child: Container(
            height: 300,
            width: double.infinity,
            color: AppColors.darkBg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: orientedWidth / orientedHeight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: rawVideo,
                    ),
                  ),
                ),
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

      Rect? finalCrop;
      if (_aspectRatios[_selectedAspectIndex] != null || _aspectLabels[_selectedAspectIndex] == 'Free Form') {
        final matrix = _transformController.value;
        final s = matrix.getMaxScaleOnAxis();
        final tx = matrix.getTranslation().x;
        final ty = matrix.getTranslation().y;
        
        final videoSize = _controller!.value.size;
        final isRotated = _rotation == 90 || _rotation == 270;
        final orientedWidth = isRotated ? videoSize.height : videoSize.width;
        final orientedHeight = isRotated ? videoSize.width : videoSize.height;

        final left = -tx / s;
        final top = -ty / s;
        final width = _viewW / s;
        final height = _viewH / s;
        
        final normLeft = (left / orientedWidth).clamp(0.0, 1.0);
        final normTop = (top / orientedHeight).clamp(0.0, 1.0);
        final normWidth = (width / orientedWidth).clamp(0.0, 1.0);
        final normHeight = (height / orientedHeight).clamp(0.0, 1.0);
        
        finalCrop = Rect.fromLTWH(normLeft, normTop, normWidth, normHeight);
      }

      final result = await NativeVideoExport.export(
        inputPath: widget.videoPath,
        outputPath: outputPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        speed: speed,
        rotation: normalizedRotation,
        aspectRatio: null,
        cropRect: finalCrop,
      );

      // Wait for iOS to flush the exported file to disk (up to 2s).
      // Without this, the video player may try to load before the file
      // is fully written, causing a black screen with an error icon.
      final exported = File(result);
      var retries = 0;
      while (retries < 20) {
        if (await exported.exists() && await exported.length() > 0) {
          // Additional buffer time for the OS to finalize the file descriptor
          await Future.delayed(const Duration(milliseconds: 300));
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }

      // Detach from the main isolate briefly using Future.microtask
      // to ensure UI frames can clear before popping.
      await Future.microtask(() {});
      
      HapticFeedback.heavyImpact();
      if (mounted) context.pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _exporting = false;
          _exportProgress = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      _progressSub?.cancel();
      _progressSub = null;
    }
  }
}

class _TrimTimeline extends StatefulWidget {
  const _TrimTimeline({
    required this.trimStart,
    required this.trimEnd,
    required this.thumbnails,
    required this.onChanged,
    required this.videoPath,
    required this.videoDurationMs,
    this.onPlayheadChanged,
  });

  final double trimStart;
  final double trimEnd;
  final List<Uint8List?> thumbnails;
  final void Function(double start, double end) onChanged;
  final String videoPath;
  final int videoDurationMs;
  final ValueChanged<double>? onPlayheadChanged;

  @override
  State<_TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<_TrimTimeline> {
  String? _activeHandle; // 'start', 'end', 'playhead'
  double _playheadPosition = 0.5; // normalized within trim range
  Uint8List? _previewThumbnail;
  double? _previewPosition; // normalized 0-1 for positioning
  final Map<int, Uint8List> _thumbnailCache = {};
  Timer? _thumbnailDebounce;

  void _requestThumbnail(double normalizedPosition) {
    _thumbnailDebounce?.cancel();
    _thumbnailDebounce = Timer(const Duration(milliseconds: 16), () async {
      if (widget.videoDurationMs <= 0) return;
      final ms = (normalizedPosition * widget.videoDurationMs).round();
      final key = (ms / 100).round(); // round to 100ms buckets

      if (_thumbnailCache.containsKey(key)) {
        if (mounted) {
          setState(() => _previewThumbnail = _thumbnailCache[key]);
        }
        return;
      }

      try {
        final data = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          maxWidth: 80,
          quality: 50,
        );
        if (data != null) {
          // LRU eviction at 50 entries
          if (_thumbnailCache.length >= 50) {
            _thumbnailCache.remove(_thumbnailCache.keys.first);
          }
          _thumbnailCache[key] = data;
          if (mounted) {
            setState(() => _previewThumbnail = data);
          }
        }
      } catch (_) {
        // Fallback: no preview
      }
    });
  }

  void _clearDragState() {
    _thumbnailDebounce?.cancel();
    setState(() {
      _activeHandle = null;
      _previewThumbnail = null;
      _previewPosition = null;
    });
  }

  @override
  void dispose() {
    _thumbnailDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timelineWidth =
        MediaQuery.of(context).size.width - AppSpacing.screenEdge * 2;

    return SizedBox(
      height: 90, // extra space for floating preview above
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Timeline base (positioned at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Stack(
                children: [
                  // Thumbnail strip
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
                          child:
                              (i < widget.thumbnails.length &&
                                  widget.thumbnails[i] != null)
                              ? Image.memory(
                                  widget.thumbnails[i]!,
                                  fit: BoxFit.cover,
                                  height: 52,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Start handle
                  Positioned(
                    left: widget.trimStart * timelineWidth,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'start';
                          _previewPosition = widget.trimStart;
                        });
                        // Pause and seek to start handle position (iMovie/CapCut behavior)
                        widget.onPlayheadChanged?.call(widget.trimStart);
                        _requestThumbnail(widget.trimStart);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newStart =
                            (widget.trimStart + d.delta.dx / timelineWidth)
                                .clamp(0.0, widget.trimEnd - 0.1);
                        widget.onChanged(newStart, widget.trimEnd);
                        setState(() => _previewPosition = newStart);
                        // Seek preview to match handle position
                        widget.onPlayheadChanged?.call(newStart);
                        _requestThumbnail(newStart);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: Container(
                        width: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(6),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.drag_indicator,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // End handle
                  Positioned(
                    right: (1 - widget.trimEnd) * timelineWidth,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'end';
                          _previewPosition = widget.trimEnd;
                        });
                        // Pause and seek to end handle position
                        widget.onPlayheadChanged?.call(widget.trimEnd);
                        _requestThumbnail(widget.trimEnd);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newEnd =
                            (widget.trimEnd + d.delta.dx / timelineWidth).clamp(
                              widget.trimStart + 0.1,
                              1.0,
                            );
                        widget.onChanged(widget.trimStart, newEnd);
                        setState(() => _previewPosition = newEnd);
                        // Seek preview to match handle position
                        widget.onPlayheadChanged?.call(newEnd);
                        _requestThumbnail(newEnd);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: Container(
                        width: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.drag_indicator,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Playhead (draggable)
                  Positioned(
                    left: _effectivePlayheadPosition * timelineWidth - 1.5,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _activeHandle = 'playhead';
                          _previewPosition = _effectivePlayheadPosition;
                        });
                        _requestThumbnail(_effectivePlayheadPosition);
                      },
                      onHorizontalDragUpdate: (d) {
                        final newPos =
                            (_playheadPosition + d.delta.dx / timelineWidth)
                                .clamp(widget.trimStart, widget.trimEnd);
                        setState(() {
                          _playheadPosition = newPos;
                          _previewPosition = newPos;
                        });
                        widget.onPlayheadChanged?.call(newPos);
                        _requestThumbnail(newPos);
                      },
                      onHorizontalDragEnd: (_) => _clearDragState(),
                      child: Container(width: 3, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating preview thumbnail
          if (_activeHandle != null && _previewPosition != null)
            Positioned(
              left: (_previewPosition! * timelineWidth - 40).clamp(
                0.0,
                timelineWidth - 80,
              ),
              top: 0,
              child: Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.darkFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _previewThumbnail != null
                    ? Image.memory(_previewThumbnail!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          _formatPreviewTime(),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  double get _effectivePlayheadPosition {
    return _playheadPosition.clamp(widget.trimStart, widget.trimEnd);
  }

  String _formatPreviewTime() {
    if (_previewPosition == null || widget.videoDurationMs <= 0) return '--:--';
    final ms = (_previewPosition! * widget.videoDurationMs).round();
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        child: Icon(
          icon,
          color: active
              ? AppColors.accent
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
