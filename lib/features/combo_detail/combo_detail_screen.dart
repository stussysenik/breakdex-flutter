import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';
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
import '../../core/services/native_share_sheet.dart';
import '../../core/utils/share_sheet.dart';
import '../../core/utils/diagnostics.dart';
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
  Widget build(final BuildContext context) {
    final comboAsync = ref.watch(comboByIdStreamProvider(widget.comboId));
    final movesAsync = ref.watch(comboMovesStreamProvider(widget.comboId));
    final fsrsCards = ref.watch(fsrsCardsRefreshProvider).valueOrNull ?? const [];
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<sm.ComboDetailState>(comboDetailStateProvider(widget.comboId), (final prev, final next) {
      if (next is sm.Gone && mounted) {
        context.pop();
      }
    });

    final combo = comboAsync.valueOrNull;
    final comboMoves = movesAsync.valueOrNull;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: combo == null || comboMoves == null
                ? const Center(child: CircularProgressIndicator())
                : _ComboDetailBody(
                    combo: combo,
                    comboMoves: comboMoves,
                    fsrsCards: fsrsCards,
                    colorScheme: colorScheme,
                    comboId: widget.comboId,
                    activeIndex: _activeIndex,
                    onStepSelected: (final i) => setState(() => _activeIndex = i),
                    onEditVideo: _editVideo,
                    onShareVideo: _shareVideo,
                    onSaveToAlbum: _saveToAlbum,
                    onDeleteCombo: (final combo) => _showDeleteSheet(context, ref, combo),
                  ),
          ),
          // State machine overlays
          Consumer(
            builder: (final context, final ref, _) {
              final smState = ref.watch(comboDetailStateProvider(widget.comboId));
              final notifier = ref.read(comboDetailStateProvider(widget.comboId).notifier);
              return Stack(
                children: [
                  if (smState is sm.Deleting)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: AppSpacing.md),
                              Text('Deleting...', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (smState is sm.SavingNotes || smState is sm.SavingLog)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  if (smState is sm.ErrorState)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                                const SizedBox(height: AppSpacing.md),
                                Text(smState.message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                                const SizedBox(height: AppSpacing.lg),
                                TextButton(
                                  onPressed: () => notifier.send(sm.Cancel()),
                                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Opens the video editor for a combo move's video and updates the move on return.
  Future<void> _editVideo(final Move move) async {
    if (move.videoPath == null) return;
    final resolvedPath = move.resolvedVideoPath;
    MediaPlaybackCoordinator.shared.pauseAll();
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': resolvedPath},
    );
    if (editedPath != null && mounted) {
      // 1. Compute SHA-256 hash from absolute temp path
      final contentHash =
          await ref.read(assetHashServiceProvider).computeHash(editedPath);

      // 2. Resolve final semantic path with contentHash
      final semanticRelative = await VideoPathResolver.moveToSemanticPath(
        currentRelativePath: editedPath,
        category: move.category,
        moveName: move.name,
        contentHash: contentHash,
      );
      final resolvedAbs = VideoPathResolver.toAbsolute(semanticRelative);

      // 3. Cleanup old assets
      final pathChanged = move.resolvedVideoPath != resolvedAbs;
      await ref.read(mediaCleanupServiceProvider).cleanupDetachedAsset(
            title: move.name,
            category: move.category,
            storedVideoPath: pathChanged ? move.videoPath : null,
            resolvedVideoPath: pathChanged ? move.resolvedVideoPath : null,
            contentHash: move.contentHash,
            managedAlbumAssetId: move.managedAlbumAssetId,
            excludingMoveId: move.id,
            skipPhotosCleanup: true,
          );

      // 4. Update DB
      await ref.read(moveRepositoryProvider).update(
            MovesCompanion(
              id: Value(move.id),
              videoPath: Value(semanticRelative),
              originalVideoName: Value(p.basename(editedPath)),
              managedAlbumAssetId: const Value(null),
              managedAlbumFilename: const Value(null),
              managedAlbumName: const Value(null),
              contentHash: Value(contentHash),
            ),
          );

      unawaited(
        ref
            .read(videoImportSyncHookProvider)
            .onVideoImported(localPath: resolvedAbs, moveId: move.id),
      );
      try {
        final managedCopy = await _videoAlbum.saveToAlbum(
          videoPath: resolvedAbs,
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
  void _showDeleteSheet(final BuildContext context, final WidgetRef ref, final Combo combo) {
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
              Navigator.pop(context);
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

  Future<void> _shareVideo(final Move move) async {
    final resolvedPath = move.resolvedVideoPath;
    if (resolvedPath == null) return;
    MediaPlaybackCoordinator.shared.pauseAll();
    try {
      await NativeShareSheet.shareFiles(
        filePaths: [resolvedPath],
        subject: move.name,
        sharePositionOrigin: sharePositionOrigin(context),
      );
    } catch (e, stack) {
      DiagnosticsLog.error('ComboDetail', '_shareVideo failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _saveToAlbum(final Move move) async {
    final resolvedPath = move.resolvedVideoPath;
    if (resolvedPath == null) return;
    try {
      await _videoAlbum.saveToAlbum(
        videoPath: resolvedPath,
        albumName: NativeVideoAlbum.defaultAlbumName(),
        assetTitle: move.name,
        category: move.category,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "${move.name}" to Photos')),
        );
      }
    } catch (e, stack) {
      DiagnosticsLog.error('ComboDetail', '_saveToAlbum failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}

class _ComboDetailBody extends ConsumerWidget {
  const _ComboDetailBody({
    required this.combo,
    required this.comboMoves,
    required this.fsrsCards,
    required this.colorScheme,
    required this.comboId,
    required this.activeIndex,
    required this.onStepSelected,
    required this.onEditVideo,
    required this.onShareVideo,
    required this.onSaveToAlbum,
    required this.onDeleteCombo,
  });

  final Combo combo;
  final List<ComboMoveWithDetail> comboMoves;
  final List<FsrsCard> fsrsCards;
  final ColorScheme colorScheme;
  final String comboId;
  final int activeIndex;
  final ValueChanged<int> onStepSelected;
  final void Function(Move move) onEditVideo;
  final void Function(Move move) onShareVideo;
  final void Function(Move move) onSaveToAlbum;
  final void Function(Combo combo) onDeleteCombo;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final safeIndex = activeIndex.clamp(
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

    final totalBeats = comboMoves.fold<int>(0, (final sum, final m) => sum + m.move.count);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      children: [
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
              onTap: () => onDeleteCombo(combo),
              child: Icon(
                Icons.delete_outline,
                color: colorScheme.secondary,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
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
            key: ValueKey('${currentMove.id}:$safeIndex:${currentMove.contentHash}'),
            videoPath: currentMove.resolvedVideoPath!,
            autoPlay: true,
            onEdit: () => onEditVideo(currentMove),
          )
        else
          const VideoPlaceholder(),
        if (currentMove != null && currentMove.videoPath != null) ...[
          const SizedBox(height: AppSpacing.md),
          _VideoActionRow(
            move: currentMove,
            onEdit: () => onEditVideo(currentMove),
            onShare: () => onShareVideo(currentMove),
            onSaveToAlbum: () => onSaveToAlbum(currentMove),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ComboStepLine(
          stepCount: comboMoves.length,
          activeIndex: safeIndex,
          onStepSelected: onStepSelected,
          stepNames: comboMoves.map((final m) => m.move.name).toList(),
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
          onChanged: (final text) => ref
              .read(comboDetailStateProvider(comboId).notifier)
              .send(sm.UpdateNotes(text)),
        ),
        const SizedBox(height: AppSpacing.xl),
        LogsSection(entityId: combo.id, entityType: 'combo'),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _VideoActionRow extends StatelessWidget {
  const _VideoActionRow({
    required this.move,
    required this.onEdit,
    required this.onShare,
    required this.onSaveToAlbum,
  });

  final Move move;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onSaveToAlbum;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ActionTile(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: onEdit,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ActionTile(
          icon: Icons.ios_share,
          label: 'Share',
          onTap: onShare,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ActionTile(
          icon: Icons.save_alt_outlined,
          label: 'Save',
          onTap: onSaveToAlbum,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(final BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
