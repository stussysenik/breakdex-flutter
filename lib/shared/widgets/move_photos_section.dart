// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import 'dart:convert';
import '../../core/platform/io.dart';
import '../../core/platform/native_media.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/services/app_storage_paths.dart';
import 'app_loader.dart';

Future<String> _photoDirectory() async {
  final docs = await AppStoragePaths.documentsDirectory();
  final dir = Directory(p.join(docs.path, '.photos'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}

class MovePhotosSection extends StatefulWidget {
  const MovePhotosSection({
    super.key,
    required this.imagePaths,
    required this.onChanged,
  });

  final String? imagePaths;
  final ValueChanged<String?> onChanged;

  @override
  State<MovePhotosSection> createState() => _MovePhotosSectionState();
}

class _MovePhotosSectionState extends State<MovePhotosSection> {
  static const _uuid = Uuid();
  final _picker = ImagePicker();
  bool _loading = false;

  List<String> get _paths {
    if (widget.imagePaths == null || widget.imagePaths!.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(widget.imagePaths!) as List<dynamic>;
      return decoded.cast<String>();
    } on Object catch (_) {
      return [];
    }
  }

  Future<String?> _resolveAbsolutePath(final String filename) async {
    final dir = await _photoDirectory();
    final fullPath = p.join(dir, filename);
    return File(fullPath).existsSync() ? fullPath : null;
  }

  Future<void> _addPhoto() async {
    setState(() => _loading = true);
    try {
      final source = await showModalBottomSheet<String>(
        context: context,
        builder: (final ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () => Navigator.pop(ctx, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null || !mounted) {
        setState(() => _loading = false);
        return;
      }

      final XFile? file = source == 'camera'
          ? await _picker.pickImage(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (file == null || !mounted) {
        setState(() => _loading = false);
        return;
      }

      final dir = await _photoDirectory();
      final ext = p.extension(file.path).isNotEmpty
          ? p.extension(file.path)
          : '.jpg';
      final filename = 'photo-${_uuid.v4()}$ext';
      final dest = p.join(dir, filename);
      await File(file.path).copy(dest);

      final updated = [..._paths, filename];
      widget.onChanged(jsonEncode(updated));
      unawaited(HapticFeedback.mediumImpact());
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add photo: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _viewPhoto(final String filename) async {
    final fullPath = await _resolveAbsolutePath(filename);
    if (fullPath == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (final ctx) => Dialog.fullscreen(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: fileImage(
                fullPath,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.md,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(final String filename) async {
    final dir = await _photoDirectory();
    final file = File(p.join(dir, filename));
    if (await file.exists()) {
      await file.delete();
    }

    final updated = _paths.where((final p) => p != filename).toList();
    widget.onChanged(updated.isEmpty ? null : jsonEncode(updated));
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paths = _paths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTOS',
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              // Add button
              _AddPhotoButton(
                loading: _loading,
                onTap: _addPhoto,
                colorScheme: colorScheme,
              ),
              // Existing photos
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: paths.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (final context, final index) {
                    final filename = paths[index];
                    return _PhotoThumbnail(
                      filename: filename,
                      onTap: () => _viewPhoto(filename),
                      onLongPress: () => _deletePhoto(filename),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.loading,
    required this.onTap,
    required this.colorScheme,
  });

  final bool loading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: loading
            ? const Center(child: AppLoader(size: 6))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 28,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatefulWidget {
  const _PhotoThumbnail({
    required this.filename,
    required this.onTap,
    required this.onLongPress,
  });

  final String filename;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  String? _absolutePath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final dir = await _photoDirectory();
    final fullPath = p.join(dir, widget.filename);
    if (mounted) {
      setState(() => _absolutePath = fullPath);
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (_absolutePath == null) {
      return const _PhotoPlaceholder();
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: 120,
          height: 120,
          child: fileImage(
            _absolutePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
      ),
    );
  }
}
