import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/models/reviewable_item.dart' show MoveVideoPath;
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/sync/video_retrieval_controller.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/native_share_sheet.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/native_video_album.dart';
import '../../core/utils/share_sheet.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer;
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/color_setting_tile.dart';
import '../../shared/widgets/notes_section.dart';
import '../flashcard_review/widgets/state_picker_sheet.dart';
import '../lab/widgets/move_aura_section.dart';
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

                // Video player — 3 states:
                // 1. Local file exists → play it
                // 2. Cloud-only (contentHash but no local file) → download overlay
                // 3. No video at all → add video placeholder
                if (move.videoPath != null)
                  Hero(
                    tag: 'move-thumb-${move.id}',
                    child: RobustVideoPlayer(
                      videoPath: move.resolvedVideoPath!,
                      onRepick: () => _addOrReplaceVideo(context, ref, move),
                      onEdit: () => _editVideo(context, ref, move),
                      ghostThumbnailPath: _thumbnailPathFor(
                        move.resolvedVideoPath!,
                      ),
                      originalVideoName: move.originalVideoName,
                    ),
                  )
                else if (move.contentHash != null)
                  _CloudVideoPlaceholder(
                    move: move,
                    onDownloaded: (localPath) async {
                      // Update move with re-downloaded local path (relative)
                      await ref
                          .read(moveRepositoryProvider)
                          .update(
                            MovesCompanion(
                              id: Value(move.id),
                              videoPath: Value(
                                VideoPathResolver.toRelative(localPath),
                              ),
                            ),
                          );
                    },
                  )
                else
                  _VideoMissingCard(
                    move: move,
                    onReRecord: () => _addOrReplaceVideo(context, ref, move),
                    onImport: () => _addOrReplaceVideo(context, ref, move),
                    onDelete: () => _deleteMove(context, ref, move),
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
                    StatePill(
                      state: state,
                      onTap: () =>
                          _changeReviewState(context, ref, move, state),
                      showDisclosure: true,
                      semanticsIdentifier: 'move-detail-state-pill',
                    ),
                    _CategoryBadge(
                      category: move.category,
                      onTap: () => _changeCategory(context, ref, move),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap state or category to edit.',
                  style: AppTypography.caption.copyWith(
                    color: colorScheme.secondary,
                  ),
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
                if (_sourceFileNameFor(move) case final sourceFileName?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _MetadataValue(label: 'Source file', value: sourceFileName),
                ],
                if (_albumFileNameFor(move) case final albumFileName?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _MetadataValue(label: 'Album file', value: albumFileName),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Notes
                NotesSection(
                  notes: move.notes,
                  onChanged: (text) {
                    ref
                        .read(moveRepositoryProvider)
                        .update(
                          MovesCompanion(
                            id: Value(move.id),
                            notes: Value(text.isEmpty ? null : text),
                          ),
                        );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bboy Aura — move transition affinities
                MoveAuraSection(moveId: move.id),
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
                    onTap: () {
                      MediaPlaybackCoordinator.shared.pauseAll();
                      context.push(
                        '/move-analysis',
                        extra: {
                          'moveId': move.id,
                          'videoPath': move.resolvedVideoPath,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ActionTile(
                    icon: Icons.edit,
                    label: 'Edit Video',
                    onTap: () => _editVideo(context, ref, move),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (tileContext) => ActionTile(
                      icon: Icons.ios_share,
                      label: 'Share Video',
                      onTap: () => _shareVideo(tileContext, move),
                    ),
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
    MediaPlaybackCoordinator.shared.pauseAll();
    final origin = sharePositionOrigin(context);
    await NativeShareSheet.shareFiles(
      filePaths: [move.resolvedVideoPath!],
      subject: move.name,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _addOrReplaceVideo(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    MediaPlaybackCoordinator.shared.pauseAll();
    final result = await VideoPickerSheet.show(
      context,
      previousVideoName: move.originalVideoName,
      previousThumbnailPath: move.videoPath != null
          ? _thumbnailPathFor(move.resolvedVideoPath!)
          : null,
    );
    if (result == null) return;
    await ref
        .read(mediaCleanupServiceProvider)
        .cleanupDetachedAsset(
          title: move.name,
          category: move.category,
          storedVideoPath: move.videoPath,
          resolvedVideoPath: move.resolvedVideoPath,
          contentHash: move.contentHash,
          managedAlbumAssetId: move.managedAlbumAssetId,
          excludingMoveId: move.id,
        );
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: Value(VideoPathResolver.toRelative(result.localPath)),
            originalVideoName: Value(result.originalFileName),
            managedAlbumAssetId: const Value(null),
            managedAlbumFilename: const Value(null),
            managedAlbumName: const Value(null),
            contentHash: const Value(null),
          ),
        );
    unawaited(
      ref
          .read(videoImportSyncHookProvider)
          .onVideoImported(localPath: result.localPath, moveId: move.id),
    );
    if (!context.mounted) return;
    final managedCopy = await _saveSemanticAlbumCopy(
      context,
      videoPath: result.localPath,
      title: move.name,
      category: move.category,
    );
    await _storeManagedAlbumCopyMetadata(
      ref,
      moveId: move.id,
      copy: managedCopy,
    );
  }

  Future<void> _editVideo(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    if (move.videoPath == null) return;
    MediaPlaybackCoordinator.shared.pauseAll();
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': move.resolvedVideoPath},
    );
    if (editedPath != null && context.mounted) {
      await ref
          .read(mediaCleanupServiceProvider)
          .cleanupDetachedAsset(
            title: move.name,
            category: move.category,
            storedVideoPath: move.videoPath,
            resolvedVideoPath: move.resolvedVideoPath,
            contentHash: move.contentHash,
            managedAlbumAssetId: move.managedAlbumAssetId,
            excludingMoveId: move.id,
          );
      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(VideoPathResolver.toRelative(editedPath)),
              managedAlbumAssetId: const Value(null),
              managedAlbumFilename: const Value(null),
              managedAlbumName: const Value(null),
              contentHash: const Value(null),
            ),
          );
      unawaited(
        ref
            .read(videoImportSyncHookProvider)
            .onVideoImported(localPath: editedPath, moveId: move.id),
      );
      if (!context.mounted) return;
      final managedCopy = await _saveSemanticAlbumCopy(
        context,
        videoPath: editedPath,
        title: move.name,
        category: move.category,
      );
      await _storeManagedAlbumCopyMetadata(
        ref,
        moveId: move.id,
        copy: managedCopy,
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
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(move);
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: const Value(null),
            originalVideoName: const Value(null),
            managedAlbumAssetId: const Value(null),
            managedAlbumFilename: const Value(null),
            managedAlbumName: const Value(null),
            contentHash: const Value(null),
          ),
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
                        final naming = ref.read(
                          reviewableNamingServiceProvider,
                        );
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
                          unawaited(HapticFeedback.heavyImpact());
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
      if (move.videoPath != null && context.mounted) {
        await _syncManagedAlbumCopy(
          context,
          ref: ref,
          moveId: move.id,
          videoPath: move.resolvedVideoPath!,
          previousAssetLocalIdentifier: move.managedAlbumAssetId,
          previousTitle: move.name,
          previousCategory: move.category,
          nextTitle: newName,
          nextCategory: move.category,
        );
      }
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

  Future<void> _changeReviewState(
    BuildContext context,
    WidgetRef ref,
    Move move,
    LearningState currentState,
  ) async {
    unawaited(HapticFeedback.selectionClick());
    final nextState = await StatePickerSheet.show(
      context,
      currentState: currentState,
      moveName: move.name,
    );
    if (nextState == null || nextState == currentState) return;
    await ref
        .read(manualReviewStateServiceProvider)
        .setMoveState(move, nextState);
  }

  Future<void> _changeCategory(
    BuildContext context,
    WidgetRef ref,
    Move move,
  ) async {
    final newCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final categories = sheetRef.watch(categoriesProvider);
          return SafeArea(
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
                    categories.isEmpty
                        ? 'Create the first category and it will be applied right away.'
                        : 'Keep each move anchored to a dance category so review and stats stay meaningful.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (categories.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final category in categories)
                          _EditableCategoryChip(
                            label: category.name,
                            color: category.color,
                            selected: category.name == move.category,
                            onTap: () =>
                                Navigator.pop(sheetContext, category.name),
                          ),
                      ],
                    ),
                  SizedBox(height: categories.isNotEmpty ? AppSpacing.lg : 0),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final created = await _showAddCategoryDialog(
                          sheetContext,
                          sheetRef,
                        );
                        if (created != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext, created);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        categories.isEmpty
                            ? 'Create first category'
                            : 'Add category',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (newCategory == null || newCategory == move.category) return;

    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(id: Value(move.id), category: Value(newCategory)),
        );
    if (move.videoPath != null && context.mounted) {
      await _syncManagedAlbumCopy(
        context,
        ref: ref,
        moveId: move.id,
        videoPath: move.resolvedVideoPath!,
        previousAssetLocalIdentifier: move.managedAlbumAssetId,
        previousTitle: move.name,
        previousCategory: move.category,
        nextTitle: move.name,
        nextCategory: newCategory,
      );
    }
  }

  Future<String?> _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    errorText: errorText,
                  ),
                  onChanged: (_) => setDialogState(() => errorText = null),
                ),
                const SizedBox(height: AppSpacing.md),
                ColorSettingTile(
                  title: 'Category color',
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: 'Category Color',
                      subtitle: 'Pick any color for this category label.',
                      presets: categoryPresetColors,
                    );
                    if (nextColor == null || !context.mounted) return;
                    setDialogState(() => selectedColor = nextColor);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setDialogState(
                      () => errorText = 'Category name cannot be empty.',
                    );
                    return;
                  }
                  final exists = ref
                      .read(categoriesProvider)
                      .any((item) => item.name == name);
                  if (exists) {
                    setDialogState(() => errorText = '"$name" already exists.');
                    unawaited(HapticFeedback.heavyImpact());
                    return;
                  }

                  await ref
                      .read(categoriesProvider.notifier)
                      .addCategory(name, selectedColor);
                  if (!context.mounted) return;
                  unawaited(HapticFeedback.mediumImpact());
                  Navigator.pop(context, name);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _sourceFileNameFor(Move move) {
    final originalName = move.originalVideoName?.trim();
    if (originalName != null && originalName.isNotEmpty) {
      return originalName;
    }
    final resolvedPath = move.resolvedVideoPath;
    if (resolvedPath == null || resolvedPath.trim().isEmpty) return null;
    return p.basename(resolvedPath);
  }

  String? _albumFileNameFor(Move move) {
    final persistedName = move.managedAlbumFilename?.trim();
    if (persistedName != null && persistedName.isNotEmpty) {
      return persistedName;
    }
    if (move.videoPath == null && move.originalVideoName == null) return null;
    final extensionSource =
        move.resolvedVideoPath ?? move.originalVideoName ?? '';
    final extension = p.extension(extensionSource).replaceFirst('.', '');
    return NativeVideoAlbum.semanticFilename(
      assetTitle: move.name,
      category: move.category,
      fileExtension: extension,
    );
  }

  Future<ManagedAlbumCopy?> _saveSemanticAlbumCopy(
    BuildContext context, {
    required String videoPath,
    required String title,
    required String category,
  }) async {
    try {
      return await _videoAlbum.saveToAlbum(
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
      return null;
    }
  }

  Future<void> _storeManagedAlbumCopyMetadata(
    WidgetRef ref, {
    required String moveId,
    required ManagedAlbumCopy? copy,
  }) {
    return ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(moveId),
            managedAlbumAssetId: Value(copy?.assetLocalIdentifier),
            managedAlbumFilename: Value(copy?.filename),
            managedAlbumName: Value(copy?.albumName),
          ),
        );
  }

  Future<void> _syncManagedAlbumCopy(
    BuildContext context, {
    required WidgetRef ref,
    required String moveId,
    required String videoPath,
    required String? previousAssetLocalIdentifier,
    required String previousTitle,
    required String previousCategory,
    required String nextTitle,
    required String nextCategory,
  }) async {
    try {
      await _videoAlbum.deleteManagedCopies(
        assetTitle: previousTitle,
        category: previousCategory,
        fileExtension: p.extension(videoPath),
        assetLocalIdentifier: previousAssetLocalIdentifier,
      );
      if (!context.mounted) return;
      final managedCopy = await _saveSemanticAlbumCopy(
        context,
        videoPath: videoPath,
        title: nextTitle,
        category: nextCategory,
      );
      await _storeManagedAlbumCopyMetadata(
        ref,
        moveId: moveId,
        copy: managedCopy,
      );
    } catch (error) {
      await _storeManagedAlbumCopyMetadata(ref, moveId: moveId, copy: null);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Album sync failed: $error')));
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
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(mediaCleanupServiceProvider).cleanupMoveMedia(move);
    await ref.read(moveRepositoryProvider).delete(move.id);
    if (context.mounted) context.pop();
  }
}

class _CategoryBadge extends ConsumerWidget {
  const _CategoryBadge({required this.category, this.onTap});

  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider);
    final match = categories.where((item) => item.name == category).firstOrNull;
    final dotColor = match?.color ?? colorScheme.secondary;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: colorScheme.secondary),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return badge;
    }

    return Semantics(
      button: true,
      label: 'Change category from $category',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: badge,
        ),
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

class _MetadataValue extends StatelessWidget {
  const _MetadataValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Card shown when a move has no video and no cloud copy — the video is truly
/// gone (orphaned legacy move or deleted file). Shows move metadata so the user
/// can identify it, and offers re-record / import / delete actions.
class _VideoMissingCard extends StatelessWidget {
  final Move move;
  final VoidCallback onReRecord;
  final VoidCallback onImport;
  final VoidCallback onDelete;

  const _VideoMissingCard({
    required this.move,
    required this.onReRecord,
    required this.onImport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Video Missing',
            style: AppTypography.bodySmall
                .merge(const TextStyle(fontWeight: FontWeight.w600))
                .copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'The original video couldn\'t be found.',
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MissingActionButton(
                  icon: Icons.videocam,
                  label: 'Re-record',
                  onTap: onReRecord,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MissingActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Import',
                  onTap: onImport,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onDelete,
            child: Text(
              'Delete move',
              style: AppTypography.caption.copyWith(
                color: AppColors.actionAgain.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MissingActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.mediumImpact());
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall
                  .merge(const TextStyle(fontWeight: FontWeight.w600))
                  .copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay shown when a video exists only in the cloud (freed locally).
/// Tapping triggers an on-demand download, then updates the move's videoPath.
class _CloudVideoPlaceholder extends ConsumerStatefulWidget {
  final Move move;
  final ValueChanged<String> onDownloaded;

  const _CloudVideoPlaceholder({
    required this.move,
    required this.onDownloaded,
  });

  @override
  ConsumerState<_CloudVideoPlaceholder> createState() =>
      _CloudVideoPlaceholderState();
}

class _CloudVideoPlaceholderState
    extends ConsumerState<_CloudVideoPlaceholder> {
  String? _reportedLocalPath;

  @override
  Widget build(BuildContext context) {
    final contentHash = widget.move.contentHash!;
    final retrievalAsync = ref.watch(videoRetrievalStatusProvider(contentHash));
    final retrieval =
        retrievalAsync.valueOrNull ??
        ref.read(videoRetrievalControllerProvider).snapshotFor(contentHash);

    ref.listen(videoRetrievalStatusProvider(contentHash), (_, next) {
      final snapshot = next.valueOrNull;
      final localPath = snapshot?.localPath;
      if (snapshot?.state == VideoRetrievalState.available &&
          localPath != null &&
          localPath != _reportedLocalPath) {
        _reportedLocalPath = localPath;
        widget.onDownloaded(localPath);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final isBusy =
        retrieval.state == VideoRetrievalState.queued ||
        retrieval.state == VideoRetrievalState.waitingForConnection ||
        retrieval.state == VideoRetrievalState.waitingForWifi ||
        retrieval.state == VideoRetrievalState.waitingForBudget ||
        retrieval.state == VideoRetrievalState.downloading;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isBusy
              ? null
              : () => ref
                    .read(videoRetrievalControllerProvider)
                    .requestPlayback(contentHash),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBusy) ...[
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: retrieval.progress > 0 ? retrieval.progress : null,
                      strokeWidth: 3,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    retrieval.message ?? 'Preparing retrieval…',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.cloud_download_outlined,
                    size: 48,
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Video stored in cloud',
                    style: AppTypography.bodySmall
                        .merge(const TextStyle(fontWeight: FontWeight.w600))
                        .copyWith(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to download and play',
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  if (retrieval.message != null &&
                      retrieval.state == VideoRetrievalState.failed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      retrieval.message!,
                      style: AppTypography.caption.copyWith(
                        color: Colors.red.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
