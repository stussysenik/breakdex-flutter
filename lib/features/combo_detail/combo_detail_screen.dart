// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/services/entity_names_service.dart';
import '../../core/database/daos/combo_plans_dao.dart';
import '../../core/database/daos/combos_dao.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/native_share_sheet.dart';
import '../../core/services/native_video_album.dart';
import '../../core/utils/diagnostics.dart';
import '../../core/utils/share_sheet.dart';
import '../../shared/widgets/beat_grid.dart';
import '../../shared/widgets/video_player_widget.dart'
    show RobustVideoPlayer, VideoPlaceholder;

import '../../core/state_machines/combo_detail/machine.dart' as sm;
import '../../core/state_machines/combo_detail/provider.dart';
import '../../shared/widgets/app_loader.dart';
import 'widgets/status_tag.dart';
import 'widgets/journal_list.dart';
import 'widgets/jot_composer.dart';

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
    final allIdsAsync = ref.watch(allComboIdsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<sm.ComboDetailState>(comboDetailStateProvider(widget.comboId), (final prev, final next) {
      if (next is sm.Gone && mounted) {
        context.pop();
      }
    });

    final combo = comboAsync.valueOrNull;
    final comboMoves = movesAsync.valueOrNull;
    final allIds = allIdsAsync.valueOrNull ?? <String>[];
    final currentIdx = allIds.indexOf(widget.comboId);
    final hasPrev = currentIdx > 0;
    final hasNext = currentIdx >= 0 && currentIdx < allIds.length - 1;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 104,
        leading: GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
              Text(
                ref.watch(entityNamesProvider).comboPlural,
                style: AppTypography.sectionHeader.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        actions: combo == null
            ? null
            : [
                if (hasPrev)
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: colorScheme.onSurface, size: 22),
                    tooltip: 'Previous combo',
                    onPressed: () => _navigateToCombo(context, allIds[currentIdx - 1]),
                  ),
                if (hasNext)
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface, size: 22),
                    tooltip: 'Next combo',
                    onPressed: () => _navigateToCombo(context, allIds[currentIdx + 1]),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: colorScheme.onSurface),
                  onSelected: (final action) => _handleAction(context, action, combo),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'plan',
                      child: Row(children: [
                        Icon(Icons.calendar_today, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Plan for a day…'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(children: [
                        Icon(Icons.copy, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Duplicate'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.ios_share, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Share'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'save-album',
                      child: Row(children: [
                        Icon(Icons.save_alt_outlined, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Save to Album'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_forever, size: 18, color: colorScheme.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Delete', style: TextStyle(color: colorScheme.error)),
                      ]),
                    ),
                  ],
                ),
              ],
      ),
      body: Stack(
        children: [
          combo == null || comboMoves == null
              ? const Center(child: AppLoader())
              : _ComboDetailBody(
                  combo: combo,
                  comboMoves: comboMoves,
                  comboId: widget.comboId,
                  activeIndex: _activeIndex,
                  onStepSelected: (final i) => setState(() => _activeIndex = i),
                ),
          _SmOverlay(comboId: widget.comboId),
        ],
      ),
    );
  }

  void _handleAction(final BuildContext context, final String action, final Combo combo) {
    switch (action) {
      case 'plan':
        _planCombo(context);
      case 'duplicate':
        _duplicateCombo(context, combo);
      case 'edit':
        context.push('/edit-combo/${combo.id}');
      case 'share':
        final current = _currentMove;
        if (current?.resolvedVideoPath != null) {
          _shareVideo(current!);
        }
      case 'save-album':
        final current = _currentMove;
        if (current?.resolvedVideoPath != null) {
          _saveToAlbum(current!);
        }
      case 'delete':
        _showDeleteSheet(context, combo);
    }
  }

  Move? get _currentMove {
    final movesAsync = ref.read(comboMovesStreamProvider(widget.comboId));
    final moves = movesAsync.valueOrNull;
    if (moves == null || moves.isEmpty) return null;
    final safeIndex = _activeIndex.clamp(0, moves.length - 1);
    return moves[safeIndex].move;
  }

  void _planCombo(final BuildContext context) {
    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    ).then((final picked) async {
      if (picked == null || !mounted) return;
      await ref.read(comboPlansDaoProvider).insertPlan(
        ComboPlansCompanion.insert(
          id: const Uuid().v4(),
          comboId: widget.comboId,
          planDate: ComboPlansDao.dateOnly(picked),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Planned for ${DateFormat('MMM d').format(picked)}')),
        );
      }
    });
  }

  Future<void> _duplicateCombo(final BuildContext context, final Combo source) async {
    final newId = const Uuid().v4();
    final newName = '${source.name} (copy)';

    await ref.read(combosDaoProvider).duplicateCombo(
          sourceComboId: source.id,
          newComboId: newId,
          newName: newName,
          provenanceEntryId: const Uuid().v4(),
          comboMoveIdFactory: () => const Uuid().v4(),
        );

    if (mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Duplicated as "$newName"')),
      );
      unawaited(this.context.push('/breakdex/combo/$newId'));
    }
  }

  void _showDeleteSheet(final BuildContext context, final Combo combo) {
    showCupertinoModalPopup<void>(
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
    } on Object catch (e) {
      DiagnosticsLog.error('ComboDetail', '_shareVideo failed: $e');
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
    } on Object catch (e) {
      DiagnosticsLog.error('ComboDetail', '_saveToAlbum failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _navigateToCombo(final BuildContext context, final String targetId) {
    context.go('/breakdex/combo/$targetId');
  }
}

class _ComboDetailBody extends ConsumerWidget {
  const _ComboDetailBody({
    required this.combo,
    required this.comboMoves,
    required this.comboId,
    required this.activeIndex,
    required this.onStepSelected,
  });

  final Combo combo;
  final List<ComboMoveWithDetail> comboMoves;
  final String comboId;
  final int activeIndex;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeIndex = activeIndex.clamp(0, comboMoves.isEmpty ? 0 : comboMoves.length - 1);
    final currentMove = comboMoves.isNotEmpty ? comboMoves[safeIndex].move : null;
    final chain = comboMoves.map((final m) => m.move.name).join(' → ');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenEdge),
            children: [
              // Name
              Semantics(
                header: true,
                child: Text(
                  combo.name,
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Transition chain
              if (chain.isNotEmpty)
                Text(
                  chain,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.md),
              // Status tag
              StatusTag(
                status: combo.status,
                onChanged: (final newStatus) async {
                  await ref.read(combosDaoProvider).updateStatus(
                        comboId: comboId,
                        newStatus: newStatus,
                        entryId: const Uuid().v4(),
                      );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Video player
              if (currentMove != null && currentMove.videoPath != null)
                RobustVideoPlayer(
                  key: ValueKey('${currentMove.id}:$safeIndex:${currentMove.contentHash}'),
                  videoPath: currentMove.resolvedVideoPath!,
                  autoPlay: true,
                )
              else
                const VideoPlaceholder(),
              const SizedBox(height: AppSpacing.md),

              // Beat grid
              BeatGrid(
                items: [
                  for (int i = 0; i < comboMoves.length; i++)
                    BeatGridItem(
                      label: comboMoves[i].move.name,
                      count: comboMoves[i].move.count,
                      isActive: i == safeIndex,
                      onTap: () => onStepSelected(i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Current step info
              if (currentMove != null)
                Row(
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
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              // Journal
              JournalList(comboId: comboId),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
        // Pinned jot composer — lifted above the shell's bottom nav
        // (house pattern, see move_list_screen FAB).
        Padding(
          padding: EdgeInsets.only(
            bottom: kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom,
          ),
          child: JotComposer(comboId: comboId),
        ),
      ],
    );
  }
}

class _SmOverlay extends ConsumerWidget {
  const _SmOverlay({required this.comboId});

  final String comboId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final smState = ref.watch(comboDetailStateProvider(comboId));
    final notifier = ref.read(comboDetailStateProvider(comboId).notifier);

    if (smState is! sm.Deleting &&
        smState is! sm.SavingNotes &&
        smState is! sm.SavingLog &&
        smState is! sm.ErrorState) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: smState is sm.ErrorState
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(smState.message,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      TextButton(
                        onPressed: () => notifier.send(sm.Cancel()),
                        child: const Text('OK', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLoader(color: Colors.white),
                    SizedBox(height: AppSpacing.md),
                    Text('Working...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
        ),
      ),
    );
  }
}
