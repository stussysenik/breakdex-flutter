import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/design/theme.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/services/native_video_album.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/state_machines/move_detail/provider.dart';
import '../../core/state_machines/move_detail/state.dart';
import '../../core/state_machines/move_detail/event.dart';
import '../../core/utils/share_sheet.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/notes_section.dart';
import '../../shared/widgets/logs_section.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart';
import '../../core/services/native_share_sheet.dart';
import '../../shared/widgets/move_photos_section.dart';
import '../flashcard_review/widgets/state_picker_sheet.dart';
import '../lab/widgets/move_aura_section.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../../core/services/categories_service.dart';
import '../../core/sync/video_retrieval_controller.dart';

import 'widgets/move_detail_overlays.dart';

class MoveDetailScreen extends ConsumerStatefulWidget {
  const MoveDetailScreen({super.key, required this.moveId});

  final String moveId;

  @override
  ConsumerState<MoveDetailScreen> createState() => _MoveDetailScreenState();
}

class _MoveDetailScreenState extends ConsumerState<MoveDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final moveId = widget.moveId;
      debugPrint('[MoveDetailScreen] initState loading moveId=$moveId');
      ref.read(moveRepositoryProvider).getById(moveId).then((m) {
        if (mounted) {
          debugPrint('[MoveDetailScreen] initState loaded move name="${m.name}" id=${m.id}');
          ref.read(moveDetailProvider.notifier).init(m);
        }
      }).catchError((err, stack) {
        debugPrint('[MoveDetailScreen] initState FAILED to load moveId=$moveId — $err');
        if (mounted) {
          context.pop();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final machineState = ref.watch(moveDetailProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Handle terminal states
    if (machineState is Gone) {
      Future.microtask(() => context.pop());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final move = machineState.move;
    final state = LearningState.fromName(move.learningState);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                title: Text(move.name, style: AppTypography.titleSmall),
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenEdge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Card
                      if (move.videoPath != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: RobustVideoPlayer(
                            key: ValueKey('detail-video-${move.id}-${move.videoPath}-${move.contentHash}'),
                            videoPath: move.resolvedVideoPath!,
                            originalVideoName: move.originalVideoName,
                          ),
                        )
                      else if (move.contentHash != null)
                        _CloudVideoPlaceholder(
                          move: move,
                          onDownloaded: (localPath) {
                            ref.read(moveDetailProvider.notifier).send(
                                  VideoEdited(localPath),
                                );
                          },
                        )
                      else
                        _VideoMissingCard(
                          move: move,
                          onReRecord: () => _addOrReplaceVideo(context, ref, move),
                          onImport: () => _addOrReplaceVideo(context, ref, move),
                          onDelete: () => ref
                              .read(moveDetailProvider.notifier)
                              .send(const TapDelete()),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // Move Name
                      Text(
                        move.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      // Hash / filename
                      if (move.originalVideoName != null ||
                          move.contentHash != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (move.originalVideoName != null)
                              move.originalVideoName!,
                            if (move.contentHash != null)
                              move.contentHash!.length > 12
                                  ? '\u2026${move.contentHash!.substring(move.contentHash!.length - 12)}'
                                  : move.contentHash!,
                          ].join(' \u00b7 '),
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),

                      // Metadata Row
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          StatePill(
                            state: state,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeState()),
                            showDisclosure: true,
                            semanticsIdentifier: 'move-detail-state-pill',
                          ),
                          _CategoryBadge(
                            category: move.category,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeCategory()),
                          ),
                          _CountBadge(
                            count: move.count,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeCount()),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Notes
                      NotesSection(
                        notes: move.notes,
                        onChanged: (text) {
                          ref
                              .read(moveDetailProvider.notifier)
                              .send(UpdateNotes(text));
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Photos
                      MovePhotosSection(
                        imagePaths: move.imagePaths,
                        onChanged: (json) {
                          ref
                              .read(moveDetailProvider.notifier)
                              .send(UpdatePhotos(json));
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      MoveAuraSection(moveId: move.id),
                      const SizedBox(height: AppSpacing.lg),

                      LogsSection(entityId: move.id, entityType: 'move'),
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
                          onTap: () => ref
                              .read(moveDetailProvider.notifier)
                              .send(const TapRemoveVideo()),
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
                        label: 'Rename Move',
                        onTap: () => ref
                            .read(moveDetailProvider.notifier)
                            .send(const TapRename()),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ActionTile(
                        icon: Icons.delete_forever,
                        label: 'Delete Move',
                        destructive: true,
                        onTap: () => ref
                            .read(moveDetailProvider.notifier)
                            .send(const TapDelete()),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ..._buildOverlays(machineState, colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildOverlays(MoveDetailState state, ColorScheme cs) {
    debugPrint('[MoveDetailScreen] _buildOverlays state=${state.runtimeType}');
    final overlays = <Widget>[];
    final notifier = ref.read(moveDetailProvider.notifier);

    if (state is Renaming) {
      overlays.add(RenameOverlay(
        draftName: state.draftName,
        onDraftChanged: (n) => notifier.send(UpdateDraft(n)),
        onCancel: () => notifier.send(const Cancel()),
        onSave: (n) => notifier.send(SaveName(n)),
      ));
    }

    if (state is NameConflict) {
      overlays.add(RenameOverlay(
        draftName: state.conflictingName,
        onDraftChanged: (n) => notifier.send(UpdateDraft(n)),
        onCancel: () => notifier.send(const Cancel()),
        onSave: (n) => notifier.send(SaveName(n)),
        isConflict: true,
        conflictName: state.conflictingName,
      ));
    }

    if (state is Deleting) overlays.add(const SavingOverlay(message: 'Deleting...'));
    if (state is SavingName) overlays.add(const SavingOverlay(message: 'Renaming...'));
    if (state is SavingState) overlays.add(const SavingOverlay(message: 'Updating state...'));
    if (state is SavingCategory) overlays.add(const SavingOverlay(message: 'Updating category...'));
    if (state is SavingCount) overlays.add(const SavingOverlay(message: 'Updating count...'));
    if (state is SavingNotes) overlays.add(const SavingOverlay(message: 'Saving notes...'));
    if (state is SavingPhotos) overlays.add(const SavingOverlay(message: 'Updating photos...'));
    if (state is SavingVideo) overlays.add(const SavingOverlay(message: 'Importing video...'));

    if (state is ChangingState) {
      overlays.add(StatePickerOverlay(
        currentState: LearningState.fromName(state.move.learningState),
        moveName: state.move.name,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (next) => notifier.send(SaveState(next)),
      ));
    }

    if (state is ChangingCategory) {
      overlays.add(CategoryPickerOverlay(
        currentCategory: state.move.category,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (next) => notifier.send(SaveCategory(next)),
      ));
    }

    if (state is ChangingCount) {
      overlays.add(CountEditorOverlay(
        initialCount: state.move.count,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (next) => notifier.send(SaveCount(next)),
      ));
    }

    if (state is ConfirmingDelete) {
      overlays.add(ConfirmActionOverlay(
        title: 'Delete Move?',
        content: 'This will permanently delete this move and its video.',
        confirmLabel: 'Delete',
        isDestructive: true,
        onCancel: () => notifier.send(const Cancel()),
        onConfirm: () => notifier.send(const Confirm()),
      ));
    }

    if (state is ErrorState) {
      overlays.add(ConfirmActionOverlay(
        title: 'Error',
        content: state.message,
        confirmLabel: 'OK',
        isDestructive: false,
        onCancel: () => notifier.send(const Cancel()),
        onConfirm: () => notifier.send(const Cancel()),
      ));
    }

    if (state is AlbumSyncFailed) {
      overlays.add(ConfirmActionOverlay(
        title: 'Album Sync Failed',
        content: state.message,
        confirmLabel: 'OK',
        isDestructive: false,
        onCancel: () => notifier.send(const Cancel()),
        onConfirm: () => notifier.send(const Cancel()),
      ));
    }

    if (state is ConfirmingRemoveVideo) {
      overlays.add(ConfirmActionOverlay(
        title: 'Remove Video?',
        content: 'The video will be removed from this move but kept in your local storage.',
        confirmLabel: 'Remove',
        isDestructive: true,
        onCancel: () => notifier.send(const Cancel()),
        onConfirm: () => notifier.send(const Confirm()),
      ));
    }

    return overlays;
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

  Future<void> _addOrReplaceVideo(BuildContext context, WidgetRef ref, Move move) async {
    MediaPlaybackCoordinator.shared.pauseAll();
    final result = await VideoPickerSheet.show(
      context,
      previousVideoName: move.originalVideoName,
      previousThumbnailPath: move.videoPath != null ? _thumbnailPathFor(move.resolvedVideoPath!) : null,
    );
    if (result != null) {
      ref.read(moveDetailProvider.notifier).send(VideoPicked(result.localPath, result.originalFileName ?? ''));
    }
  }

  Future<void> _editVideo(BuildContext context, WidgetRef ref, Move move) async {
    if (move.videoPath == null) return;
    MediaPlaybackCoordinator.shared.pauseAll();
    debugPrint('[MoveDetailScreen] _editVideo pushing editor with resolvedPath=${move.resolvedVideoPath}');
    final editedPath = await context.push<String>('/video-editor', extra: {'videoPath': move.resolvedVideoPath});
    debugPrint('[MoveDetailScreen] _editVideo Editor returned path=$editedPath');
    if (editedPath != null) {
      ref.read(moveDetailProvider.notifier).send(VideoEdited(editedPath));
    }
  }

  String? _thumbnailPathFor(String videoPath) {
    final dir = p.dirname(videoPath);
    final name = p.basenameWithoutExtension(videoPath);
    return p.join(dir, '.thumbs', '$name.jpg');
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

    return Semantics(
      button: true,
      label: 'Change category from $category',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600))),
                if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.expand_more, size: 14, color: colorScheme.secondary)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Change count from $count',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('$count', style: AppTypography.caption.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                Text(' counts', style: AppTypography.caption.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w400)),
                if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.expand_more, size: 14, color: colorScheme.secondary)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoMissingCard extends StatelessWidget {
  final Move move;
  final VoidCallback onReRecord;
  final VoidCallback onImport;
  final VoidCallback onDelete;
  const _VideoMissingCard({required this.move, required this.onReRecord, required this.onImport, required this.onDelete});

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
          Icon(Icons.videocam_off_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('Video Missing', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('The original video couldn\'t be found.', style: AppTypography.caption.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _MissingActionButton(icon: Icons.videocam, label: 'Re-record', onTap: onReRecord)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _MissingActionButton(icon: Icons.photo_library_outlined, label: 'Import', onTap: onImport)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(onTap: onDelete, child: Text('Delete move', style: AppTypography.caption.copyWith(color: AppColors.actionAgain.withValues(alpha: 0.7)))),
        ],
      ),
    );
  }
}

class _MissingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MissingActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
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
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CloudVideoPlaceholder extends ConsumerStatefulWidget {
  final Move move;
  final ValueChanged<String> onDownloaded;
  const _CloudVideoPlaceholder({required this.move, required this.onDownloaded});
  @override
  ConsumerState<_CloudVideoPlaceholder> createState() => _CloudVideoPlaceholderState();
}

class _CloudVideoPlaceholderState extends ConsumerState<_CloudVideoPlaceholder> {
  String? _reportedLocalPath;
  @override
  Widget build(BuildContext context) {
    final contentHash = widget.move.contentHash!;
    final retrievalAsync = ref.watch(videoRetrievalStatusProvider(contentHash));
    final retrieval = retrievalAsync.valueOrNull ?? ref.read(videoRetrievalControllerProvider).snapshotFor(contentHash);

    ref.listen(videoRetrievalStatusProvider(contentHash), (_, next) {
      final snapshot = next.valueOrNull;
      final localPath = snapshot?.localPath;
      if (snapshot?.state == VideoRetrievalState.available && localPath != null && localPath != _reportedLocalPath) {
        _reportedLocalPath = localPath;
        widget.onDownloaded(localPath);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = retrieval.state == VideoRetrievalState.queued || retrieval.state == VideoRetrievalState.downloading;

    return Container(
      height: 220,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: InkWell(
        onTap: isBusy ? null : () => ref.read(videoRetrievalControllerProvider).requestPlayback(contentHash),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy) CircularProgressIndicator(value: retrieval.progress > 0 ? retrieval.progress : null)
              else Icon(Icons.cloud_download_outlined, size: 48, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text('Video stored in cloud', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Text('Tap to download and play', style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}


