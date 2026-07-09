import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/services/video_path_resolver.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/metadata_video_picker_sheet.dart';

/// A video picker that lists library-referenced videos first:
/// "THIS COMBO'S MOVES" (with file info), then "RECENT TAKES",
/// then "Import new from Photos…" as the last row.
class LibraryVideoPickerSheet extends ConsumerWidget {
  const LibraryVideoPickerSheet({
    super.key,
    required this.comboId,
    required this.onVideoPicked,
  });

  final String comboId;
  final void Function(String relativePath, String? hash) onVideoPicked;

  /// Shows the picker as a modal bottom sheet.
  static Future<void> show(
    final BuildContext context, {
    required final String comboId,
    required final void Function(String relativePath, String? hash) onVideoPicked,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LibraryVideoPickerSheet(
        comboId: comboId,
        onVideoPicked: onVideoPicked,
      ),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final comboVideos = ref.watch(_comboMoveVideosProvider(comboId));
    final recentTakes = ref.watch(_recentTakesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenEdge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Attach Video',
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Section: This Combo's Moves
          comboVideos.when(
            loading: () => const Center(child: AppLoader()),
            error: (final e, _) => Text('Error: $e'),
            data: (final videos) {
              if (videos.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "THIS COMBO'S MOVES",
                    style: AppTypography.sectionHeader.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...videos.map((final pair) {
                        final move = pair.$1;
                        return _VideoRow(
                          label: move.name,
                          subtitle: '${p.basename(move.videoPath ?? '')} · ${_fileSizeMb(move.videoPath)}',
                          onTap: () {
                            Navigator.pop(context);
                            onVideoPicked(move.videoPath!, move.contentHash);
                          },
                        );
                      }),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
          // Section: Recent Takes
          recentTakes.when(
            loading: () => const SizedBox.shrink(),
            error: (final e, _) => const SizedBox.shrink(),
            data: (final entries) {
              if (entries.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT TAKES',
                    style: AppTypography.sectionHeader.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...entries.map((final entry) => _VideoRow(
                        label: p.basename(entry.videoPath ?? ''),
                        subtitle: entry.body.length > 60
                            ? '${entry.body.substring(0, 60)}…'
                            : entry.body,
                        onTap: () {
                          Navigator.pop(context);
                          onVideoPicked(entry.videoPath!, entry.videoHash);
                        },
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
          // Import from Photos (last row)
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: colorScheme.primary),
            title: Text(
              'Import new from Photos…',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final picked = await MetadataVideoPickerSheet.show(context);
              if (picked != null) {
                onVideoPicked(picked.localPath, null);
              }
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(Icons.play_circle_outline, color: colorScheme.primary, size: 20),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: colorScheme.secondary),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

String _fileSizeMb(final String? relativePath) {
  if (relativePath == null) return '';
  try {
    final absolute = VideoPathResolver.toAbsolute(relativePath);
    final file = File(absolute);
    if (!file.existsSync()) return '';
    final mb = file.lengthSync() / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  } on Object catch (_) {
    return '';
  }
}

// -- Providers --

final _comboMoveVideosProvider =
    FutureProvider.family<List<(Move, int)>, String>((final ref, final comboId) {
  return ref.watch(combosDaoProvider).getComboMoveVideos(comboId);
});

final _recentTakesProvider =
    StreamProvider<List<ComboNoteEntry>>((final ref) {
  return ref.watch(comboNoteEntriesDaoProvider).watchRecentTakeRefs(limit: 5);
});
