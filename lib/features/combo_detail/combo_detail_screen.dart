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
import '../../core/models/combo_stats.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/timeline_node.dart';
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

  /// Index of the timeline node currently being pressed (for scale animation).
  int? _pressedNode;

  @override
  Widget build(BuildContext context) {
    final comboStream = ref
        .watch(comboRepositoryProvider)
        .watchById(widget.comboId);
    final comboMovesStream = ref
        .watch(comboRepositoryProvider)
        .watchComboMoves(widget.comboId);
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
                final states = comboMoves
                    .map(
                      (cm) => LearningState.fromString(cm.move.learningState),
                    )
                    .toList();
                final overallState = compositeState(states);

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenEdge),
                  children: [
                    // Header row: back breadcrumb + delete button
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

                    // Timeline with tap-scale bounce
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < comboMoves.length; i++)
                            GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _pressedNode = i),
                              onTapUp: (_) {
                                setState(() {
                                  _pressedNode = null;
                                  _activeIndex = i;
                                });
                                HapticFeedback.selectionClick();
                              },
                              onTapCancel: () =>
                                  setState(() => _pressedNode = null),
                              child: AnimatedScale(
                                scale: _pressedNode == i ? 0.85 : 1.0,
                                duration: AppMotion.fast02,
                                curve: AppMotion.expressive,
                                child: TimelineNode(
                                  index: i + 1,
                                  style: i == safeIndex
                                      ? TimelineNodeStyle.active
                                      : TimelineNodeStyle.inactive,
                                  showLeadingLine: i > 0,
                                  showTrailingLine: i < comboMoves.length - 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Video with overlay
                    if (currentMove?.videoPath != null)
                      RobustVideoPlayer(
                        videoPath: currentMove!.videoPath!,
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
                      Text(
                        currentMove.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          StatePill(
                            state: LearningState.fromString(
                              currentMove.learningState,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Overall combo state
                    Row(
                      children: [
                        Text(
                          'Combo State:',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatePill(state: overallState),
                      ],
                    ),
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
