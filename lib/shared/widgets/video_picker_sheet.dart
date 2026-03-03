import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/video_service.dart';

/// Bottom sheet with 3 video source options: Camera, Photo Library, Files (iCloud).
/// Shows loading overlay during pick/download. Returns VideoPickResult or null.
class VideoPickerSheet extends StatefulWidget {
  const VideoPickerSheet({super.key});

  static Future<VideoPickResult?> show(BuildContext context) {
    return showModalBottomSheet<VideoPickResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const VideoPickerSheet(),
    );
  }

  @override
  State<VideoPickerSheet> createState() => _VideoPickerSheetState();
}

class _VideoPickerSheetState extends State<VideoPickerSheet> {
  final _videoService = VideoService();
  bool _loading = false;
  String _statusText = '';

  void _onStatus(String status) {
    if (mounted) setState(() => _statusText = status);
  }

  Future<void> _pickFromPhotos() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    final result = await _videoService.pickFromPhotos(onStatus: _onStatus);
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _pickFromFiles() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    final result = await _videoService.pickFromFiles(onStatus: _onStatus);
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _recordVideo() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);
    final result = await _videoService.recordVideo(onStatus: _onStatus);
    if (mounted) Navigator.pop(context, result);
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
                  'Add Video',
                  style: AppTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
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
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _statusText,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
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
            Icon(icon, color: AppColors.accent, size: 28),
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
