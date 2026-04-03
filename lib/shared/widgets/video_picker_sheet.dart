import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/video_service.dart';

/// Bottom sheet with 3 video source options: Camera, Photo Library, Files (iCloud).
/// Shows loading overlay during pick/download. Returns VideoPickResult or null.
///
/// When [previousVideoName] is provided, shows a ghost suggestion header
/// so the user can identify which video to re-pick.
class VideoPickerSheet extends StatefulWidget {
  const VideoPickerSheet({
    super.key,
    this.previousVideoName,
    this.previousThumbnailPath,
  });

  final String? previousVideoName;
  final String? previousThumbnailPath;

  static Future<VideoPickResult?> show(
    BuildContext context, {
    String? previousVideoName,
    String? previousThumbnailPath,
  }) {
    MediaPlaybackCoordinator.shared.pauseAll();
    return showModalBottomSheet<VideoPickResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => VideoPickerSheet(
        previousVideoName: previousVideoName,
        previousThumbnailPath: previousThumbnailPath,
      ),
    );
  }

  @override
  State<VideoPickerSheet> createState() => _VideoPickerSheetState();
}

class _VideoPickerSheetState extends State<VideoPickerSheet> {
  final _videoService = VideoService();
  bool _loading = false;
  String _statusText = '';
  double _progress = 0.0;
  StreamSubscription<double>? _progressSub;

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  void _startProgressListener() {
    _progressSub?.cancel();
    _progressSub = _videoService.importProgress.listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  void _onStatus(String status) {
    if (mounted) setState(() => _statusText = status);
  }

  /// Dismiss the sheet without a result. Any in-flight native picker operation
  /// will complete in the background but its result is silently discarded
  /// because the `mounted` guards in each pick method prevent post-pop updates.
  void _cancel() {
    if (mounted) Navigator.pop(context, null);
  }

  /// Extract a human-readable message from the error thrown by the native
  /// video import channel. `PlatformException.message` already carries the
  /// `NSError.localizedDescription` from Swift, so we surface it directly
  /// with a few friendly overrides for common cases.
  String _describeError(Object error) {
    if (error is PlatformException) {
      final msg = error.message ?? '';
      if (msg.contains('iCloud') || msg.contains('Timed out')) {
        return 'iCloud download timed out — try again later';
      }
      if (msg.contains('view controller')) {
        return 'Could not open picker — try again';
      }
      if (msg.isNotEmpty) return msg;
    }
    return 'Could not access file';
  }

  Future<void> _pickFromPhotos() async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _loading = true;
      _progress = 0.0;
      _statusText = 'Opening photo library...';
    });
    _startProgressListener();
    try {
      // Do not timeout the picker interaction itself; users may need
      // more than 30s to browse iCloud/Photos and pick a file.
      final result = await _videoService.pickFromPhotos(onStatus: _onStatus);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) _showError(_describeError(e));
    }
  }

  Future<void> _pickFromFiles() async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _loading = true;
      _progress = 0.0;
      _statusText = 'Opening files...';
    });
    _startProgressListener();
    try {
      // Do not timeout the picker interaction itself; users may need
      // more than 30s to browse iCloud Drive and pick a file.
      final result = await _videoService.pickFromFiles(onStatus: _onStatus);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) _showError(_describeError(e));
    }
  }

  Future<void> _recordVideo() async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _loading = true;
      _statusText = 'Opening camera...';
    });
    try {
      final result = await _videoService.recordVideo(onStatus: _onStatus);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) _showError(_describeError(e));
    }
  }

  void _showError(String message) {
    _progressSub?.cancel();
    setState(() {
      _loading = false;
      _progress = 0.0;
      _statusText = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.previousVideoName != null ? 'Re-pick Video' : 'Add Video',
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.previousVideoName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GhostCard(
                    videoName: widget.previousVideoName!,
                    thumbnailPath: widget.previousThumbnailPath,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SourceTile(
                  icon: Icons.videocam,
                  label: 'Camera',
                  subtitle: 'Record a new video',
                  onTap: _loading ? null : _recordVideo,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SourceTile(
                  icon: Icons.photo_library,
                  label: 'Photo Library',
                  subtitle: 'Includes iCloud Photos',
                  onTap: _loading ? null : _pickFromPhotos,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SourceTile(
                  icon: Icons.folder,
                  label: 'Files',
                  subtitle: 'iCloud Drive, Dropbox, local files',
                  onTap: _loading ? null : _pickFromFiles,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        backgroundColor: Colors.white24,
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _cancel,
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}

/// Ghost card shown at 0.45 opacity above source tiles when re-picking.
/// Shows the previous video's thumbnail + original filename for context.
class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.videoName, this.thumbnailPath});

  final String videoName;
  final String? thumbnailPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.45,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            // Thumbnail or fallback icon
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: thumbnailPath != null
                    ? Image.file(
                        File(thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.videocam_off,
                              color: colorScheme.secondary, size: 20),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.videocam_off,
                            color: colorScheme.secondary, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous video',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  Text(
                    videoName,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.history, color: colorScheme.secondary, size: 18),
          ],
        ),
      ),
    );
  }
}
