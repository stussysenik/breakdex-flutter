import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer, VideoPlaceholder;
import '../../shared/widgets/video_picker_sheet.dart';

class MoveDetailScreen extends ConsumerWidget {
  const MoveDetailScreen({super.key, required this.moveId});

  final String moveId;

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
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_left,
                          color: colorScheme.secondary, size: 20),
                      Text(
                        'Move',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Video player
                if (move.videoPath != null)
                  RobustVideoPlayer(
                    videoPath: move.videoPath!,
                    onRepick: () => _addOrReplaceVideo(context, ref, move),
                    onEdit: () => _editVideo(context, ref, move),
                  )
                else
                  GestureDetector(
                    onTap: () => _addOrReplaceVideo(context, ref, move),
                    child: const VideoPlaceholder(
                      icon: Icons.add_a_photo,
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
                Row(children: [StatePill(state: state)]),
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
                  _ActionTile(
                    icon: Icons.edit,
                    label: 'Edit Video',
                    onTap: () => _editVideo(context, ref, move),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: Icons.delete_outline,
                    label: 'Remove Video',
                    destructive: true,
                    onTap: () => _removeVideo(context, ref, move),
                  ),
                ] else
                  _ActionTile(
                    icon: Icons.videocam,
                    label: 'Add Video',
                    onTap: () => _addOrReplaceVideo(context, ref, move),
                  ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.text_fields,
                  label: 'Rename',
                  onTap: () => _rename(context, ref, move),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
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

  Future<void> _addOrReplaceVideo(BuildContext context, WidgetRef ref, Move move) async {
    final result = await VideoPickerSheet.show(context);
    if (result == null) return;
    await ref.read(moveRepositoryProvider).update(
      MovesCompanion(
        id: Value(move.id),
        videoPath: Value(result.localPath),
      ),
    );
  }

  Future<void> _editVideo(BuildContext context, WidgetRef ref, Move move) async {
    if (move.videoPath == null) return;
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': move.videoPath},
    );
    if (editedPath != null && context.mounted) {
      await ref.read(moveRepositoryProvider).update(
        MovesCompanion(
          id: Value(move.id),
          videoPath: Value(editedPath),
        ),
      );
    }
  }

  Future<void> _removeVideo(BuildContext context, WidgetRef ref, Move move) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Video?'),
        content: const Text('The video file will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.actionAgain)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    HapticFeedback.mediumImpact();
    if (move.videoPath != null) {
      await ref.read(videoServiceProvider).deleteVideo(move.videoPath!);
    }
    await ref.read(moveRepositoryProvider).update(
      MovesCompanion(
        id: Value(move.id),
        videoPath: const Value(null),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Move move) async {
    final controller = TextEditingController(text: move.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Move'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Move name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == move.name) return;
    await ref.read(moveRepositoryProvider).update(
      MovesCompanion(
        id: Value(move.id),
        name: Value(newName),
      ),
    );
  }

  Future<void> _deleteMove(BuildContext context, WidgetRef ref, Move move) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Move?'),
        content: const Text('This will permanently delete this move and its video.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.actionAgain)),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = destructive ? AppColors.actionAgain : colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: color),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: colorScheme.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}
