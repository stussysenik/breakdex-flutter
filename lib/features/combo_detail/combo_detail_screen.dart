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
import '../../core/providers.dart';
import '../../core/services/native_video_album.dart';
import '../../shared/widgets/combo_step_line.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

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
    final comboStream = ref
        .watch(comboRepositoryProvider)
        .watchById(widget.comboId);
    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(widget.comboId);
    final fsrsCards =
        ref.watch(fsrsCardsRefreshProvider).valueOrNull ?? const [];
    final colorScheme = Theme.of(context).colorScheme;

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
                final comboMoves = movesSnap.data!;
                final safeIndex = _activeIndex.clamp(
                  0,
                  comboMoves.isEmpty ? 0 : comboMoves.length - 1,
                );
                final currentMove = comboMoves.isNotEmpty
                    ? comboMoves[safeIndex].move
                    : null;
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
                                  style: AppTypography.bodyMedium.copyWith(
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
                          onTap: () => _showDeleteSheet(context, combo),
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
                    Row(children: [StatePill(state: comboState)]),
                    const SizedBox(height: AppSpacing.md),

                    ComboStepLine(
                      stepCount: comboMoves.length,
                      activeIndex: safeIndex,
                      onStepSelected: (index) {
                        setState(() => _activeIndex = index);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (currentMove != null && currentMove.videoPath != null)
                      RobustVideoPlayer(
                        key: ValueKey('${currentMove.id}:$safeIndex'),
                        videoPath: currentMove.videoPath!,
                        autoPlay: true,
                        onEdit: () => _editVideo(currentMove),
                        overlay: Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              currentMove.name,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const VideoPlaceholder(),
                    const SizedBox(height: AppSpacing.md),

                    // Current move name + state
                    if (currentMove != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentMove.name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${safeIndex + 1}/${comboMoves.length}',
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (currentMove.category != 'default') ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          currentMove.category.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
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
    final originalPath = move.videoPath;
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': move.videoPath},
    );
    if (editedPath != null && mounted) {
      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(id: Value(move.id), videoPath: Value(editedPath)),
          );
      await ref.read(videoServiceProvider).replaceVideo(originalPath);
      unawaited(
        _videoAlbum
            .saveToAlbum(
              videoPath: editedPath,
              albumName: NativeVideoAlbum.defaultAlbumName(),
              assetTitle: move.name,
              category: move.category,
            )
            .catchError(
              (error) => debugPrint('Album save failed (non-fatal): $error'),
            ),
      );
    }
  }

  /// Shows a Cupertino-style destructive action sheet for deleting this combo.
  void _showDeleteSheet(BuildContext context, Combo combo) {
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
              HapticFeedback.heavyImpact();
              ref.read(comboRepositoryProvider).delete(combo.id);
              context.pop(); // navigate back
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
