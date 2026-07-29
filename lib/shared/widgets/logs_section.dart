import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/utils/time_format.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/providers.dart';

/// Live log entries for a move or combo. Keyed on (type, id) so the family
/// caches one stream per entity. Backed by Drift `.watch()` queries, it
/// re-emits on every add/edit/delete — the section updates instantly.
final _logEntriesProvider =
    StreamProvider.family<List<dynamic>, ({String type, String id})>((
      final ref,
      final key,
    ) {
      return key.type == 'move'
          ? ref.watch(moveNoteEntriesDaoProvider).watchByMoveId(key.id)
          : ref.watch(comboNoteEntriesDaoProvider).watchByComboId(key.id);
    });

class LogsSection extends ConsumerWidget {
  const LogsSection({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  final String entityId;
  final String entityType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final logsAsync = ref.watch(
      _logEntriesProvider((type: entityType, id: entityId)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LOGS',
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
            IconButton(
              onPressed: () => _showAddLogDialog(context, ref),
              icon: const AppIconView(AppIcon.add, size: 20),
              color: colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Builder(
          builder: (final context) {
            final logs = logsAsync.valueOrNull ?? const <dynamic>[];
            if (logs.isEmpty) {
              return Text(
                'No entries yet.',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (final context, final index) {
                final log = logs[index];
                // `log` is a polymorphic note-entry row (move- or combo-scoped);
                // both variants expose createdAt/body/id but share no supertype.
                // ignore_for_file: avoid_dynamic_calls
                final DateTime date = log.createdAt as DateTime;
                final String body = log.body as String;
                final String id = log.id as String;

                return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${relativeTime(date)} · ${DateFormat('HH:mm').format(date)}',
                              style: AppTypography.caption.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _editLog(context, ref, id, body),
                                  child: AppIconView(
                                    AppIcon.edit,
                                    size: 14,
                                    color: colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                GestureDetector(
                                  onTap: () => _deleteLog(context, ref, id),
                                  child: AppIconView(
                                    AppIcon.close,
                                    size: 14,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 250.ms, delay: (50 * index).ms)
                    .slideX(
                      begin: 0.05,
                      end: 0,
                      duration: 250.ms,
                      delay: (50 * index).ms,
                    );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddLogDialog(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Add Log Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'What did you work on?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (entityType == 'move') {
        await ref
            .read(moveNoteEntriesDaoProvider)
            .addEntry(id: const Uuid().v4(), moveId: entityId, body: result);
      } else {
        await ref
            .read(comboNoteEntriesDaoProvider)
            .addEntry(id: const Uuid().v4(), comboId: entityId, body: result);
      }
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _deleteLog(
    final BuildContext context,
    final WidgetRef ref,
    final String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (entityType == 'move') {
        await ref.read(moveNoteEntriesDaoProvider).deleteEntry(id);
      } else {
        await ref.read(comboNoteEntriesDaoProvider).deleteEntry(id);
      }
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _editLog(
    final BuildContext context,
    final WidgetRef ref,
    final String id,
    final String currentBody,
  ) async {
    final controller = TextEditingController(text: currentBody);
    final result = await showDialog<String>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Edit Log Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'What did you work on?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentBody) {
      if (entityType == 'move') {
        await ref.read(moveNoteEntriesDaoProvider).updateEntry(id, result);
      } else {
        await ref.read(comboNoteEntriesDaoProvider).updateEntry(id, result);
      }
      unawaited(HapticFeedback.selectionClick());
    }
  }
}
