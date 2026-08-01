import 'dart:async';

import 'package:flutter/material.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/move_archive_reason.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/app_screen.dart';
import 'package:breakdex/shared/widgets/settings_list_group.dart';

final archivedMovesProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(movesDaoProvider).watchArchived();
});

final archivedMovesCountProvider = StreamProvider<int>((final ref) {
  return ref
      .watch(movesDaoProvider)
      .watchArchived()
      .map((final moves) => moves.length);
});

class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final archivedMovesAsync = ref.watch(archivedMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScreen.fill(
      title: 'Recently Deleted',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moves deleted from Photos stay here for 30 days so you can restore them or remove them permanently.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: archivedMovesAsync.when(
                data: (final moves) {
                  if (moves.isEmpty) {
                    return Center(
                      child: Text(
                        'Nothing in Recently Deleted.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.only(
                      bottom: AppScreen.bottomInsetOf(context),
                    ),
                    children: [
                      SettingsListGroup(
                        children: [
                          for (final move in moves)
                            _ArchivedMoveRow(move: move),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (final error, final stackTrace) => Center(
                  child: Text(
                    'Recently Deleted could not be loaded.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedMoveRow extends ConsumerWidget {
  const _ArchivedMoveRow({required this.move});

  final Move move;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final archiveReason =
        MoveArchiveReason.fromDbValue(move.archiveReason) ??
        MoveArchiveReason.externalAlbumDelete;
    final archivedAt = move.archivedAt;
    final subtitle = archivedAt == null
        ? archiveReason.title
        : '${archiveReason.title} • ${_formatDate(archivedAt)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: AppIconView(AppIcon.restore, color: colorScheme.secondary),
      title: Text(
        move.name,
        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: colorScheme.secondary),
      ),
      trailing: PopupMenuButton<_ArchivedMoveAction>(
        onSelected: (final action) async {
          unawaited(HapticFeedback.mediumImpact());
          switch (action) {
            case _ArchivedMoveAction.restore:
              await _restore(context, ref);
            case _ArchivedMoveAction.deletePermanently:
              await _deletePermanently(context, ref);
          }
        },
        itemBuilder: (final context) => const [
          PopupMenuItem(
            value: _ArchivedMoveAction.restore,
            child: Text('Restore'),
          ),
          PopupMenuItem(
            value: _ArchivedMoveAction.deletePermanently,
            child: Text('Delete permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(final BuildContext context, final WidgetRef ref) async {
    try {
      await ref
          .read(managedAlbumReconciliationServiceProvider)
          .restoreArchivedMove(move);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Move restored.')));
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    }
  }

  Future<void> _deletePermanently(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text(
          'This removes the move and its media from Breakdex.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppSemanticTheme.of(context).actionAgain),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref
        .read(managedAlbumReconciliationServiceProvider)
        .permanentlyDeleteArchivedMove(move);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Move deleted permanently.')));
  }

  static String _formatDate(final DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$month/$day/$year';
  }
}

enum _ArchivedMoveAction { restore, deletePermanently }
