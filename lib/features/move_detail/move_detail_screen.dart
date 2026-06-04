import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/state_machines/move_detail/provider.dart';
import '../../core/state_machines/move_detail/state.dart';
import '../../core/state_machines/move_detail/event.dart';
import '../../core/utils/share_sheet.dart';
import '../../core/utils/transfer_rate_estimator.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/notes_section.dart';
import '../../shared/widgets/logs_section.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart';
import '../../core/services/native_share_sheet.dart';
import '../../shared/widgets/move_photos_section.dart';
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
      ref.read(moveRepositoryProvider).getById(moveId).then((final m) {
        if (mounted) {
          debugPrint('[MoveDetailScreen] initState loaded move name="${m.name}" id=${m.id}');
          ref.read(moveDetailProvider.notifier).init(m);
        }
      }).catchError((final err, final stack) {
        debugPrint('[MoveDetailScreen] initState FAILED to load moveId=$moveId — $err');
        if (mounted) {
          context.pop();
        }
      });
    });
  }

  @override
  Widget build(final BuildContext context) {
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
                          onDownloaded: (final localPath) {
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
                          onDelete: () async {
                            final combosDao = ref.read(databaseProvider).combosDao;
                            final combos = await combosDao.getCombosUsingMove(move.id);
                            if (!mounted) return;
                            ref.read(moveDetailProvider.notifier).send(TapDelete(combos: combos));
                          },
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
                        const SizedBox(height: 4),
                        Text(
                          move.originalVideoName ??
                              'ID: ${move.contentHash?.substring(0, 8) ?? move.id.substring(0, 8)}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Attributes Row
                      Row(
                        children: [
                          StatePill(
                            state: state,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeState()),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _CategoryBadge(
                            category: move.category,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeCategory()),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _CountBadge(
                            count: move.count,
                            onTap: () => ref
                                .read(moveDetailProvider.notifier)
                                .send(const TapChangeCount()),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Notes
                      NotesSection(
                        notes: move.notes,
                        onChanged: (final text) {
                          ref
                              .read(moveDetailProvider.notifier)
                              .send(UpdateNotes(text));
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Photos
                      MovePhotosSection(
                        imagePaths: move.imagePaths,
                        onChanged: (final json) {
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

                      if (move.videoPath != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'VIDEO INFO',
                          style: AppTypography.sectionHeader.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (move.videoCreationDate != null)
                                _MetadataRow(
                                  label: 'Recorded',
                                  value: DateFormat('MMM d, yyyy · HH:mm').format(move.videoCreationDate!),
                                  icon: Icons.calendar_today_rounded,
                                ),
                              if (move.videoFileSize != null)
                                _MetadataRow(
                                  label: 'File Size',
                                  value: _formatFileSize(move.videoFileSize!.toInt()),
                                  icon: Icons.data_usage_rounded,
                                ),
                              if (move.originalVideoName != null)
                                _MetadataRow(
                                  label: 'Original Name',
                                  value: move.originalVideoName!,
                                  icon: Icons.insert_drive_file_rounded,
                                ),
                              // Duration + resolution are read from the clip
                              // at display-time (not persisted) so they stay
                              // correct even for legacy/imported videos.
                              _VideoTechInfoRows(
                                key: ValueKey('techinfo-${move.id}-${move.videoPath}'),
                                videoPath: move.resolvedVideoPath!,
                              ),
                            ],
                          ),
                        ),
                      ],

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
                        icon: Icons.copy_rounded,
                        label: 'Duplicate Move',
                        onTap: () => ref.read(moveDetailProvider.notifier).send(const TapDuplicate()),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ActionTile(
                        icon: Icons.delete_forever,
                        label: 'Delete Move',
                        destructive: true,
                        onTap: () async {
                          final combosDao = ref.read(databaseProvider).combosDao;
                          final combos = await combosDao.getCombosUsingMove(move.id);
                          if (!mounted) return;
                          ref.read(moveDetailProvider.notifier).send(TapDelete(combos: combos));
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
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

  List<Widget> _buildOverlays(final MoveDetailState state, final ColorScheme cs) {
    debugPrint('[MoveDetailScreen] _buildOverlays state=${state.runtimeType}');
    final overlays = <Widget>[];
    final notifier = ref.read(moveDetailProvider.notifier);

    if (state is Renaming) {
      overlays.add(RenameOverlay(
        draftName: state.draftName,
        onDraftChanged: (final n) => notifier.send(UpdateDraft(n)),
        onCancel: () => notifier.send(const Cancel()),
        onSave: (final n) => notifier.send(SaveName(n)),
      ));
    }

    if (state is NameConflict) {
      overlays.add(RenameOverlay(
        draftName: state.conflictingName,
        onDraftChanged: (final n) => notifier.send(UpdateDraft(n)),
        onCancel: () => notifier.send(const Cancel()),
        onSave: (final n) => notifier.send(SaveName(n)),
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
    if (state is Duplicating) overlays.add(const SavingOverlay(message: 'Duplicating move...'));
    // Removed SavingVideo overlay to make video import non-blocking

    if (state is ChangingState) {
      overlays.add(StatePickerOverlay(
        currentState: LearningState.fromName(state.move.learningState),
        moveName: state.move.name,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (final next) => notifier.send(SaveState(next)),
      ));
    }

    if (state is ChangingCategory) {
      overlays.add(CategoryPickerOverlay(
        currentCategory: state.move.category,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (final next) => notifier.send(SaveCategory(next)),
      ));
    }

    if (state is ChangingCount) {
      overlays.add(CountEditorOverlay(
        initialCount: state.move.count,
        onCancel: () => notifier.send(const Cancel()),
        onSave: (final next) => notifier.send(SaveCount(next)),
      ));
    }

    if (state is ConfirmingDelete) {
      final combos = state.combos;
      final content = combos.isNotEmpty
          ? 'This move is currently used in ${combos.length} combo(s) (e.g. ${combos.first.name}). Deleting it will permanently delete this move, its video, and remove it from those combos!'
          : 'This will permanently delete this move and its video.';

      overlays.add(ConfirmActionOverlay(
        title: 'Delete Move?',
        content: content,
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

  Future<void> _shareVideo(final BuildContext context, final Move move) async {
    final absPath = VideoPathResolver.toAbsolute(move.videoPath!);
    await NativeShareSheet.shareFiles(
      filePaths: [absPath],
      subject: move.name,
      sharePositionOrigin: sharePositionOrigin(context),
    );
  }

  Future<void> _editVideo(final BuildContext context, final WidgetRef ref, final Move move) async {
    final absPath = move.resolvedVideoPath!;
    final editedPath = await context.push<String>('/video-editor', extra: {'videoPath': absPath});
    if (editedPath != null && mounted) {
      ref.read(moveDetailProvider.notifier).send(VideoEdited(editedPath));
    }
  }

  Future<void> _addOrReplaceVideo(final BuildContext context, final WidgetRef ref, final Move move) async {
    final pickResult = await VideoPickerSheet.show(context);
    if (pickResult != null && mounted) {
      ref.read(moveDetailProvider.notifier).send(VideoEdited(pickResult.localPath));
    }
  }

  String _formatFileSize(final int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reads duration + pixel resolution directly from the video file at
/// display-time via a throwaway, muted controller. These fields are not
/// persisted to the DB, so this keeps them accurate for any playable clip
/// (including videos imported before metadata capture existed) without a
/// schema change. Renders nothing until extraction succeeds, and nothing at
/// all if the probe fails — the surrounding panel degrades gracefully.
class _VideoTechInfoRows extends StatefulWidget {
  const _VideoTechInfoRows({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<_VideoTechInfoRows> createState() => _VideoTechInfoRowsState();
}

class _VideoTechInfoRowsState extends State<_VideoTechInfoRows> {
  Duration? _duration;
  Size? _resolution;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  Future<void> _probe() async {
    final controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await controller.setVolume(0);
      await controller
          .initialize()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _duration = controller.value.duration;
        _resolution = controller.value.size;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      await controller.dispose();
    }
  }

  static String _formatDuration(final Duration d) {
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '${d.inHours}:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }

  @override
  Widget build(final BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final resolution = _resolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_duration != null)
          _MetadataRow(
            label: 'Duration',
            value: _formatDuration(_duration!),
            icon: Icons.timer_outlined,
          ),
        if (resolution != null && resolution.width > 0)
          _MetadataRow(
            label: 'Resolution',
            value: '${resolution.width.toInt()} × ${resolution.height.toInt()}',
            icon: Icons.aspect_ratio_rounded,
          ),
      ],
    );
  }
}

class _CategoryBadge extends ConsumerWidget {
  const _CategoryBadge({required this.category, this.onTap});
  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider);
    final match = categories.where((final item) => item.name == category).firstOrNull;
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
  Widget build(final BuildContext context) {
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
  Widget build(final BuildContext context) {
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
  Widget build(final BuildContext context) {
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
  Widget build(final BuildContext context) {
    final contentHash = widget.move.contentHash!;
    final retrievalAsync = ref.watch(videoRetrievalStatusProvider(contentHash));
    final retrieval = retrievalAsync.valueOrNull ?? ref.read(videoRetrievalControllerProvider).snapshotFor(contentHash);

    ref.listen(videoRetrievalStatusProvider(contentHash), (_, final next) {
      final snapshot = next.valueOrNull;
      final localPath = snapshot?.localPath;
      if (snapshot?.state == VideoRetrievalState.available && localPath != null && localPath != _reportedLocalPath) {
        _reportedLocalPath = localPath;
        widget.onDownloaded(localPath);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = retrieval.state == VideoRetrievalState.queued || retrieval.state == VideoRetrievalState.downloading;
    final isDownloading = retrieval.state == VideoRetrievalState.downloading;
    final eta = retrieval.etaRemaining;
    final rate = retrieval.bytesPerSecond;

    final String detailLine;
    if (!isBusy) {
      detailLine = 'Tap to download and play';
    } else if (retrieval.isStalled) {
      detailLine = 'Stalled — retrying…';
    } else if (isDownloading) {
      detailLine = <String>[
        '${(retrieval.progress * 100).round()}%',
        if (eta != null) formatTransferEta(eta),
        if (rate != null && rate > 0) formatTransferRate(rate),
      ].join(' · ');
    } else {
      detailLine = 'Preparing…';
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: InkWell(
        onTap: isBusy ? null : () => ref.read(videoRetrievalControllerProvider).requestPlayback(contentHash),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(value: retrieval.progress > 0 ? retrieval.progress : null),
                )
              else
                const Icon(Icons.cloud_download_outlined, size: 48, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                isBusy ? (retrieval.message ?? 'Downloading…') : 'Video stored in cloud',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(detailLine, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
