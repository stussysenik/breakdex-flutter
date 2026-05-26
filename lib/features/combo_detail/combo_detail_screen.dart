import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drift/drift.dart' show Value;

import '../../core/database/database.dart';
import '../../core/database/daos/combos_dao.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/native_video_album.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../../shared/widgets/notes_section.dart';
import '../../shared/widgets/logs_section.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

import '../../core/state_machines/combo_detail/machine.dart' as sm;
import '../../core/state_machines/combo_detail/provider.dart';

class ComboDetailScreen extends ConsumerStatefulWidget {
  const ComboDetailScreen({super.key, required this.comboId});

  final String comboId;

  @override
  ConsumerState<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends ConsumerState<ComboDetailScreen> {
  int _activeIndex = 0;
  final NativeVideoAlbum _videoAlbum = NativeVideoAlbum();

  @override
  Widget build(BuildContext context) {
    final comboStream = ref.watch(comboRepositoryProvider).watchById(widget.comboId);
    final comboMovesStream = ref.watch(comboRepositoryProvider).watchComboMoves(widget.comboId);
    final fsrsCards = ref.watch(fsrsCardsRefreshProvider).valueOrNull ?? const [];
    final colorScheme = Theme.of(context).colorScheme;

    // Handle destructive navigation
    ref.listen<sm.ComboDetailState>(comboDetailStateProvider(widget.comboId), (prev, next) {
      if (next is sm.Gone && mounted) {
        context.pop();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Combo>(
          stream: comboStream,
          builder: (context, comboSnap) {
            return StreamBuilder<List<ComboMoveWithDetail>>(
              stream: comboMovesStream,
              builder: (context, movesSnap) {
                if (!comboSnap.hasData || !movesSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final combo = comboSnap.data!;
                final List<ComboMoveWithDetail> comboMoves = movesSnap.data!;
                
                // Initialize notifier once combo is loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.read(comboDetailStateProvider(widget.comboId).notifier).init(combo);
                  }
                });

                final safeIndex = _activeIndex.clamp(
                  0,
                  comboMoves.isEmpty ? 0 : comboMoves.length - 1,
                );
                final currentMove = comboMoves.isNotEmpty ? comboMoves[safeIndex].move : null;

                FsrsCard? comboCard;
                for (final card in fsrsCards) {
                  if (card.entityType == 'combo' && card.entityId == combo.id) {
                    comboCard = card;
                    break;
                  }
                }
                final comboState = switch (comboCard?.fsrsState) {
                  2 => LearningState.mastery,
                  1 || 3 => LearningState.learning,
                  _ => LearningState.newState,
                };

                final totalBeats = comboMoves.fold<int>(0, (sum, m) => sum + m.move.count);

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenEdge),
                  children: [
                    // Header row: back breadcrumb + edit/delete actions
                    Row(
                      children: [
                        Expanded(
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
                                  'Combo',
                                  style: AppTypography.sectionHeader.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/edit-combo/${combo.id}'),
                          child: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: () => _showDeleteSheet(context, ref, combo),
                          child: Icon(
                            Icons.delete_outline,
                            color: colorScheme.secondary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Combo name
                    Semantics(
                      header: true,
                      child: Text(
                        combo.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      StatePill(state: comboState),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${comboMoves.length} STEPS · $totalBeats BEATS',
                        style: AppTypography.sectionHeader.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.lg),

                    if (currentMove != null && currentMove.videoPath != null)
                      RobustVideoPlayer(
                        key: ValueKey('${currentMove.id}:$safeIndex'),
                        videoPath: currentMove.resolvedVideoPath!,
                        autoPlay: true,
                        onEdit: () => _editVideo(currentMove),
                      )
                    else
                      const VideoPlaceholder(),
                    const SizedBox(height: AppSpacing.lg),

                    ComboStepLine(
                      stepCount: comboMoves.length,
                      activeIndex: safeIndex,
                      onStepSelected: (index) {
                        setState(() => _activeIndex = index);
                      },
                      stepNames: comboMoves.map((m) => m.move.name).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (currentMove != null) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push('/breakdex/move/${currentMove.id}'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STEP ${safeIndex + 1}: ${currentMove.name.toUpperCase()}',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: colorScheme.primary,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentMove.category.toUpperCase()} · ${currentMove.count} BEATS',
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.secondary.withValues(alpha: 0.8),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (currentMove.notes != null && currentMove.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            currentMove.notes!,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],

                    NotesSection(
                      notes: combo.notes,
                      onChanged: (text) => ref
                          .read(comboDetailStateProvider(widget.comboId).notifier)
                          .send(sm.UpdateNotes(text)),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    LogsSection(entityId: combo.id, entityType: 'combo'),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Opens the video editor for a combo move's video and updates the move on return.
  Future<void> _editVideo(Move move) async {
    if (move.videoPath == null) return;
    final resolvedPath = move.resolvedVideoPath;
    MediaPlaybackCoordinator.shared.pauseAll();
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': resolvedPath},
    );
    if (editedPath != null && mounted) {
      await ref.read(mediaCleanupServiceProvider).cleanupDetachedAsset(
            title: move.name,
            category: move.category,
            storedVideoPath: move.videoPath,
            resolvedVideoPath: move.resolvedVideoPath,
            contentHash: move.contentHash,
            managedAlbumAssetId: move.managedAlbumAssetId,
            excludingMoveId: move.id,
            skipPhotosCleanup: true,
          );
      await ref.read(moveRepositoryProvider).update(
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
      try {
        final managedCopy = await _videoAlbum.saveToAlbum(
          videoPath: editedPath,
          albumName: NativeVideoAlbum.defaultAlbumName(),
          assetTitle: move.name,
          category: move.category,
        );
        await ref.read(moveRepositoryProvider).update(
              MovesCompanion(
                id: Value(move.id),
                managedAlbumAssetId: Value(managedCopy?.assetLocalIdentifier),
                managedAlbumFilename: Value(managedCopy?.filename),
                managedAlbumName: Value(managedCopy?.albumName),
              ),
            );
      } catch (error) {
        debugPrint('Album save failed (non-fatal): $error');
      }
    }
  }

  /// Shows a Cupertino-style destructive action sheet for deleting this combo.
  void _showDeleteSheet(BuildContext context, WidgetRef ref, Combo combo) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Delete "${combo.name}"?'),
        message: const Text(
          'This will remove the combo and all its move associations.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context); // dismiss sheet
              unawaited(HapticFeedback.heavyImpact());
              ref.read(comboDetailStateProvider(widget.comboId).notifier).send(sm.ConfirmDelete());
            },
            child: const Text('Delete Combo'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
