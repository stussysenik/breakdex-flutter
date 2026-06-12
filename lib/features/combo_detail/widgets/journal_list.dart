import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/services/video_path_resolver.dart';
import '../../../core/utils/diagnostics.dart';
import '../../../core/utils/time_format.dart';

/// Jots longer than this read better at bodyMedium (16); shorter ones sit
/// on bodySmall (14). The 14/16 fluid-type rule from the journal grid.
const _fluidTypeThreshold = 120;

final _journalEntriesProvider =
    StreamProvider.family<List<ComboNoteEntry>, String>((final ref, final id) {
  return ref.watch(comboNoteEntriesDaoProvider).watchByComboId(id);
});

/// The combo journal: append-only ledger on a strict 56/16/fluid grid —
/// 56px timestamp column, 16px gutter, fluid body.
class JournalList extends ConsumerWidget {
  const JournalList({super.key, required this.comboId});

  final String comboId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(_journalEntriesProvider(comboId));
    final entries = entriesAsync.valueOrNull ?? const <ComboNoteEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JOURNAL',
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (entries.isEmpty)
          Text(
            'Nothing jotted yet — the first take starts the story.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (final context, final index) =>
                _JournalRow(entry: entries[index]),
          ),
      ],
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({required this.entry});

  final ComboNoteEntry entry;

  bool get _muted => entry.kind == 'status' || entry.kind == 'duplicate';

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = entry.body.length > _fluidTypeThreshold
        ? AppTypography.bodyMedium
        : AppTypography.bodySmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 56px timestamp column
        SizedBox(
          width: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relativeTime(entry.createdAt),
                style: AppTypography.caption.copyWith(
                  color: _muted
                      ? colorScheme.secondary.withValues(alpha: 0.6)
                      : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(entry.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        // 16px gutter
        const SizedBox(width: AppSpacing.md),
        // fluid body
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.body,
                style: _muted
                    ? AppTypography.bodySmall.copyWith(
                        color: colorScheme.secondary.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      )
                    : bodyStyle.copyWith(color: colorScheme.onSurface),
              ),
              if (entry.videoPath != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _VideoRefChip(entry: entry),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A linked video reference: name + size when it resolves; a graceful
/// "no longer available" fallback (logged) when it doesn't.
class _VideoRefChip extends StatelessWidget {
  const _VideoRefChip({required this.entry});

  final ComboNoteEntry entry;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final basename = p.basename(entry.videoPath!);
    final absolute = VideoPathResolver.toAbsolute(entry.videoPath!);
    final file = File(absolute);
    final exists = file.existsSync();

    if (!exists) {
      DiagnosticsLog.info(
        'JournalList',
        'video ref miss entry=${entry.id} path=${entry.videoPath}',
      );
      return Text(
        'video no longer available — was $basename',
        style: AppTypography.caption.copyWith(
          color: colorScheme.secondary.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final sizeMb = file.lengthSync() / (1024 * 1024);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(
        '/video-viewer',
        extra: {'videoPath': absolute, 'title': basename},
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline,
                size: 16, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                '$basename · ${sizeMb.toStringAsFixed(1)} MB',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
