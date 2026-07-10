// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import '../../core/platform/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/loading_state_machine.dart';
import 'app_loader.dart';
import 'metadata_video_picker_sheet.dart';

/// Bottom sheet with 3 video source options: Camera, Photo Library, Files (iCloud).
/// Shows loading overlay during pick/download. Returns [VideoPickResult] or null.
class VideoPickerSheet extends StatefulWidget {
  const VideoPickerSheet({
    super.key,
    this.previousVideoName,
    this.previousThumbnailPath,
  });

  final String? previousVideoName;
  final String? previousThumbnailPath;

  static Future<VideoPickResult?> show(
    final BuildContext context, {
    final String? previousVideoName,
    final String? previousThumbnailPath,
  }) {
    return showModalBottomSheet<VideoPickResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (final ctx) => VideoPickerSheet(
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
  final _loadingController = LoadingStateController<void>();
  LoadingStateMachine<void> _loadState = const Idle();
  StreamSubscription<LoadingStateMachine<void>>? _stateSub;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _loadingController.stream.listen((final state) {
      if (mounted) setState(() => _loadState = state);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _progressSub?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  void _startProgressListener() {
    _progressSub?.cancel();
    _progressSub = _videoService.importProgress.listen((final p) {
      _loadingController.send(LoadingEvent.progress(p));
    });
  }

  void _cancel() {
    if (mounted) Navigator.pop(context, null);
  }

  String _describeError(final Object error) {
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
    final result = await MetadataVideoPickerSheet.show(context);
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _pickFromFiles() async {
    unawaited(HapticFeedback.selectionClick());
    _loadingController.send(LoadingEvent.start);
    _startProgressListener();
    try {
      final resultEither = await _videoService.pickFromFiles().run();
      if (!mounted) return;
      resultEither.match(
        (final failure) {
          final err = _describeError(Exception(failure.message));
          _loadingController.send(LoadingEvent.fail(err, retryable: true));
        },
        (final result) {
          if (result != null) {
            _loadingController.send(LoadingEvent.complete(null));
            Navigator.pop(context, result);
          } else {
            _loadingController.send(LoadingEvent.reset);
          }
        },
      );
    } on Object catch (e) {
      if (mounted) {
        _loadingController.send(LoadingEvent.fail(_describeError(e), retryable: true));
      }
    }
  }

  Future<void> _recordVideo() async {
    unawaited(HapticFeedback.selectionClick());
    _loadingController.send(LoadingEvent.start);
    try {
      final resultEither = await _videoService.recordVideo().run();
      if (!mounted) return;
      resultEither.match(
        (final failure) {
          final err = _describeError(Exception(failure.message));
          _loadingController.send(LoadingEvent.fail(err, retryable: true));
        },
        (final result) {
          if (result != null) {
            _loadingController.send(LoadingEvent.complete(null));
            Navigator.pop(context, result);
          } else {
            _loadingController.send(LoadingEvent.reset);
          }
        },
      );
    } on Object catch (e) {
      if (mounted) {
        _loadingController.send(LoadingEvent.fail(_describeError(e), retryable: true));
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = _loadState is Loading || _loadState is Downloading;

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
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
                  icon: Icons.photo_library,
                  label: 'Photo Library',
                  subtitle: 'Includes iCloud Photos',
                  onTap: isLoading ? null : _pickFromPhotos,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SourceTile(
                  icon: Icons.folder,
                  label: 'Files',
                  subtitle: 'iCloud Drive, Dropbox, local files',
                  onTap: isLoading ? null : _pickFromFiles,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SourceTile(
                  icon: Icons.videocam,
                  label: 'Camera',
                  subtitle: 'Record a new video',
                  onTap: isLoading ? null : _recordVideo,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        _buildLoadingOverlay(colorScheme),
      ],
    );
  }

  Widget _buildLoadingOverlay(final ColorScheme colorScheme) {
    return _loadState.map(
      idle: (_) => const SizedBox.shrink(),
      ready: (_) => const SizedBox.shrink(),
      loading: (_) => _LoadingOverlayContent(
        statusText: 'Preparing...',
        onCancel: _cancel,
      ),
      downloading: (final s) => _LoadingOverlayContent(
        statusText: 'Importing...',
        progress: s.progress,
        onCancel: _cancel,
      ),
      retrying: (final s) => _LoadingOverlayContent(
        statusText: 'Retrying (${s.attempt}/${s.maxAttempts})...',
        onCancel: _cancel,
      ),
      timeout: (_) => _ErrorOverlayContent(
        message: 'iCloud download timed out.',
        onRetry: _pickFromFiles,
        onCancel: () => _loadingController.send(LoadingEvent.reset),
      ),
      error: (final s) => _ErrorOverlayContent(
        message: s.message,
        onRetry: s.retryable ? _pickFromFiles : null,
        onCancel: () => _loadingController.send(LoadingEvent.reset),
      ),
    );
  }
}

class _LoadingOverlayContent extends StatelessWidget {
  const _LoadingOverlayContent({
    required this.statusText,
    this.progress,
    required this.onCancel,
  });

  final String statusText;
  final double? progress;
  final VoidCallback onCancel;

  @override
  Widget build(final BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoader(size: 10, color: Colors.white),
            const SizedBox(height: 16),
            if (progress != null)
              Text(
                '${(progress! * 100).toInt()}%',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlayContent extends StatelessWidget {
  const _ErrorOverlayContent({
    required this.message,
    this.onRetry,
    required this.onCancel,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('RETRY'),
              ),
            TextButton(
              onPressed: onCancel,
              child: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.videoName, this.thumbnailPath});
  final String videoName;
  final String? thumbnailPath;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbnailPath != null
                ? Image.file(File(thumbnailPath!), fit: BoxFit.cover)
                : const Icon(Icons.movie, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT SELECTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(videoName, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          Icon(Icons.history, color: colorScheme.secondary, size: 18),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.titleSmall),
                    Text(subtitle, style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
