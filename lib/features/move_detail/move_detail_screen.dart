import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/native_video_album.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/video_picker_sheet.dart';

class MoveDetailScreen extends ConsumerWidget {
  MoveDetailScreen({super.key, required this.moveId});

  final String moveId;
  final NativeVideoAlbum _videoAlbum = NativeVideoAlbum();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moveStream = ref.watch(moveRepositoryProvider).watchById(moveId);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Move>(
          stream: moveStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final move = snapshot.data!;
            final state = LearningState.fromString(move.learningState);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenEdge),
              children: [
                // Back breadcrumb
                Semantics(
                  label: 'Back',
                  button: true,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        Text(
                          'Move',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Video player
                if (move.videoPath != null)
                  RobustVideoPlayer(
                    videoPath: move.videoPath!,
                    onRepick: () => _addOrReplaceVideo(context, ref, move),
                    onEdit: () => _editVideo(context, ref, move),
                    ghostThumbnailPath: _thumbnailPathFor(move.videoPath!),
                    originalVideoName: move.originalVideoName,
                  )
                else
                  Semantics(
                    label: 'Add video',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _addOrReplaceVideo(context, ref, move),
                      child: const VideoPlaceholder(icon: Icons.add_a_photo),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Move name
                Semantics(
                  header: true,
                  child: Text(
                    move.name,
                    style: AppTypography.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // State pill
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatePill(state: state),
                    _CategoryBadge(category: move.category),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Created date
                Text(
                  'Created',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(move.createdAt),
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: colorScheme.outline),
                const SizedBox(height: AppSpacing.md),

                // Actions
                Text(
                  'ACTIONS',
                  style: AppTypography.sectionHeader.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (move.videoPath != null) ...[
                  ActionTile(
                    icon: Icons.auto_fix_high,
                    label: 'Analyze Move',
                    onTap: () => context.push(
                      '/move-analysis',
                      extra: {'moveId': move.id, 'videoPath': move.videoPath},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionTile(
                    icon: Icons.edit,
                    label: 'Edit Video',
                    onTap: () => _editVideo(context, ref, move),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionTile(
                    icon: Icons.ios_share,
                    label: 'Share Video',
                    onTap: () => _shareVideo(context, move),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionTile(
                    icon: Icons.delete_outline,
                    label: 'Remove Video',
                    destructive: true,
                    onTap: () => _removeVideo(context, ref, move),
                  ),
                ] else
                  ActionTile(
                    icon: Icons.videocam,
                    label: 'Add Video',
                    onTap: () => _addOrReplaceVideo(context, ref, move),
                  ),
                const SizedBox(height: AppSpacing.sm),
                ActionTile(
                  icon: Icons.text_fields,
                  label: 'Rename',
                  onTap: () => _rename(context, ref, move),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionTile(
                  icon: Icons.category_outlined,
                  label: 'Change Category',
                  onTap: () => _changeCategory(context, ref, move),
                ),
                const SizedBox(height: AppSpacing.sm),
                ActionTile(
                  icon: Icons.delete_forever,
                  label: 'Delete Move',
                  destructive: true,
                  onTap: () => _deleteMove(context, ref, move),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Derives the cached thumbnail path from a video path.
  /// Thumbnails live in `.thumbs/{uuid}.jpg` alongside the video.
  String? _thumbnailPathFor(String videoPath) {
    final dir = p.dirname(videoPath);
    final name = p.basenameWithoutExtension(videoPath);
    return p.join(dir, '.thumbs', '$name.jpg');
  }

  Future<void> _shareVideo(BuildContext context, Move move) async {
    if (move.videoPath == null) return;
    await Share.shareXFiles([XFile(move.videoPath!)], subject: move.name);
  }

  Future<void> _addOrReplaceVideo(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    final result = await VideoPickerSheet.show(
      context,
      previousVideoName: move.originalVideoName,
      previousThumbnailPath: move.videoPath != null
          ? _thumbnailPathFor(move.videoPath!)
          : null,
    );
    if (result == null) return;
    final videoService = ref.read(videoServiceProvider);
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: Value(result.localPath),
            originalVideoName: Value(result.originalFileName),
          ),
        );
    await videoService.replaceVideo(move.videoPath);
    if (!context.mounted) return;
    await _saveSemanticAlbumCopy(
      context,
      videoPath: result.localPath,
      title: move.name,
      category: move.category,
    );
  }

  Future<void> _editVideo(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    if (move.videoPath == null) return;
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': move.videoPath},
    );
    if (editedPath != null && context.mounted) {
      final videoService = ref.read(videoServiceProvider);
      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(id: Value(move.id), videoPath: Value(editedPath)),
          );
      await videoService.replaceVideo(move.videoPath);
      if (!context.mounted) return;
      await _saveSemanticAlbumCopy(
        context,
        videoPath: editedPath,
        title: move.name,
        category: move.category,
      );
    }
  }

  Future<void> _removeVideo(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Video?'),
        content: const Text('The video file will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.actionAgain),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    HapticFeedback.mediumImpact();
    if (move.videoPath != null) {
      await ref.read(videoServiceProvider).deleteVideo(move.videoPath!);
    }
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(id: Value(move.id), videoPath: const Value(null)),
        );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Move move) async {
    final controller = TextEditingController(text: move.name);
    String? errorText;
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isEmpty = controller.text.trim().isEmpty;
          return AlertDialog(
            title: const Text('Rename Move'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Move name',
                errorText: errorText,
              ),
              onChanged: (_) => setDialogState(() => errorText = null),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isEmpty
                    ? null
                    : () async {
                        final naming = ref.read(reviewableNamingServiceProvider);
                        final normalized = naming.normalize(controller.text);
                        final exists = await naming.isNameTaken(
                          normalized,
                          excludingMoveId: move.id,
                        );
                        if (!ctx.mounted) return;
                        if (exists) {
                          setDialogState(
                            () => errorText = '"$normalized" already exists.',
                          );
                          HapticFeedback.heavyImpact();
                          return;
                        }
                        Navigator.pop(ctx, normalized);
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (newName == null || newName.isEmpty || newName == move.name) return;
    try {
      await ref
          .read(moveRepositoryProvider)
          .update(MovesCompanion(id: Value(move.id), name: Value(newName)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$error'.contains('duplicate_card_name')
                ? 'Card names must stay unique across moves and combos.'
                : 'Rename failed: $error',
          ),
        ),
      );
    }
  }

  Future<void> _changeCategory(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    final categories = ref.read(categoriesProvider);
    if (categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a category first.')));
      return;
    }

    final newCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move Category',
                style: AppTypography.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Keep each move anchored to a dance category so review and stats stay meaningful.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final category in categories)
                    _EditableCategoryChip(
                      label: category.name,
                      color: category.color,
                      selected: category.name == move.category,
                      onTap: () => Navigator.pop(sheetContext, category.name),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newCategory == null || newCategory == move.category) return;

    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(id: Value(move.id), category: Value(newCategory)),
        );
  }

  Future<void> _saveSemanticAlbumCopy(
    BuildContext context, {
    required String videoPath,
    required String title,
    required String category,
  }) async {
    try {
      await _videoAlbum.saveToAlbum(
        videoPath: videoPath,
        albumName: NativeVideoAlbum.defaultAlbumName(),
        assetTitle: title,
        category: category,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Album copy failed: $error')));
      }
    }
  }

  Future<void> _deleteMove(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Move?'),
        content: const Text(
          'This will permanently delete this move and its video.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.actionAgain),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    HapticFeedback.mediumImpact();
    if (move.videoPath != null) {
      await ref.read(videoServiceProvider).deleteVideo(move.videoPath!);
    }
    await ref.read(moveRepositoryProvider).delete(move.id);
    if (context.mounted) context.pop();
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            category,
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableCategoryChip extends StatelessWidget {
  const _EditableCategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? Colors.white : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
