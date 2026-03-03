import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/sync_progress.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/stats_export_service.dart';
import '../stats/providers/stats_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingProvider);
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text('Settings', style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              )),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Theme picker
            Text(
              'APPEARANCE',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ThemePicker(
              selected: theme,
              onChanged: (t) => ref.read(themeSettingProvider.notifier).set(t),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Categories
            Text(
              'CATEGORIES',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final cat in categories)
              Dismissible(
                key: ValueKey(cat.name),
                direction: cat.isDefault
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.screenEdge),
                  color: AppColors.actionAgain,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  ref.read(categoriesProvider.notifier).removeCategory(cat.name);
                },
                child: _CategoryRow(
                  name: cat.name,
                  color: cat.color,
                  isDefault: cat.isDefault,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => _showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add Category', style: AppTypography.bodySmall),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Learning State Colors
            Text(
              'LEARNING STATE COLORS',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final state in LearningState.values)
              _StateColorRow(state: state),
            const SizedBox(height: AppSpacing.xl),

            // Data section
            Text(
              'DATA',
              style: AppTypography.sectionHeader.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DataActionTileAsync(
              icon: Icons.ios_share,
              label: 'Export Stats',
              onTap: () async {
                final stats = await ref.read(statsBundleProvider.future);
                final summary =
                    StatsExportService.generateTextSummary(stats);
                await Share.share(summary);
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _DataActionTileAsync(
              icon: Icons.file_download_outlined,
              label: 'Export Full Backup',
              onTap: () async {
                final db = ref.read(databaseProvider);
                final prefs = ref.read(sharedPreferencesProvider);
                final result =
                    await StatsExportService.generateJsonExport(db, prefs);
                final dir = await getTemporaryDirectory();
                final file = File(
                  p.join(dir.path, StatsExportService.exportFilename),
                );
                await file.writeAsString(result.json);
                await Share.shareXFiles([XFile(file.path)]);
                return 'Exported ${result.totalRecords} records (${result.moveCount} moves, ${result.reviewCount} reviews, ${result.comboCount} combos)';
              },
              showResultSnackBar: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DataActionTileAsync(
              icon: Icons.file_upload_outlined,
              label: 'Import Backup',
              onTap: () async {
                await _showImportFlow(context, ref);
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _DataActionTile(
              icon: Icons.delete_forever,
              label: 'Clear All Data',
              destructive: true,
              onTap: () => _showClearDataDialog(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Cloud Sync
            _CloudSyncSection(),
            const SizedBox(height: AppSpacing.xl),

            // Version footer
            Center(
              child: Text(
                'Breakdex v0.4.0 (Build 1)',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all moves, reviews, combos, and battle results. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              final db = ref.read(databaseProvider);
              final videoService = ref.read(videoServiceProvider);
              // Delete video files before clearing DB
              final moves = await db.movesDao.getAll();
              for (final move in moves) {
                if (move.videoPath != null) {
                  await videoService.deleteVideo(move.videoPath!);
                }
              }
              // Delete all rows from every table
              await db.delete(db.reviews).go();
              await db.delete(db.comboMoves).go();
              await db.delete(db.combos).go();
              await db.delete(db.battleResults).go();
              await db.delete(db.moves).go();
              // Invalidate stats so UI refreshes
              ref.invalidate(statsBundleProvider);
            },
            child: const Text(
              'Clear Everything',
              style: TextStyle(color: AppColors.actionAgain),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportFlow(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final file = File(result.files.single.path!);
    final json = await file.readAsString();
    final validation = StatsExportService.validateImportJson(json);

    if (!validation.valid) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error ?? 'Invalid backup file')),
      );
      return;
    }

    if (!context.mounted) return;

    // Show mode selection dialog
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${validation.moveCount} moves, ${validation.reviewCount} reviews, '
              '${validation.comboCount} combos, ${validation.battleResultCount} battle results'
              '${validation.categoryCount > 0 ? ', ${validation.categoryCount} categories' : ''}.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Import mode:'),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.replaceAll),
              child: const Text('Replace All (clear existing data first)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.merge),
              child: const Text('Merge (skip duplicates)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (mode == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final importResult = await StatsExportService.importFromJson(
        db, prefs, json, mode,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      // Invalidate all providers so UI refreshes
      ref.invalidate(statsBundleProvider);
      ref.invalidate(categoriesProvider);

      final msg = 'Imported ${importResult.totalImported} records'
          '${importResult.movesWithMissingVideos.isNotEmpty ? ' (${importResult.movesWithMissingVideos.length} moves need video re-linking)' : ''}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Category name'),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: categoryPresetColors.map((c) {
                    final isSelected = c.toARGB32() == selectedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: c.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                )]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(categoriesProvider.notifier)
                        .addCategory(name, selectedColor);
                    HapticFeedback.mediumImpact();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onChanged});

  final ThemeSetting selected;
  final ValueChanged<ThemeSetting> onChanged;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: ThemeSetting.values.map((t) {
          final isSelected = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )]
                      : null,
                ),
                child: Center(
                  child: Text(
                    t.displayName,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.secondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.color,
    required this.isDefault,
  });

  final String name;
  final Color color;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(name, style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          )),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'default',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateColorRow extends StatelessWidget {
  const _StateColorRow({required this.state});

  final LearningState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: state.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(state.displayText, style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            )),
          ),
          Text(
            '#${state.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataActionTile extends StatelessWidget {
  const _DataActionTile({
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
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

class _DataActionTileAsync extends StatefulWidget {
  const _DataActionTileAsync({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showResultSnackBar = false,
  });

  final IconData icon;
  final String label;
  final Future<String?> Function() onTap;
  final bool showResultSnackBar;

  @override
  State<_DataActionTileAsync> createState() => _DataActionTileAsyncState();
}

class _DataActionTileAsyncState extends State<_DataActionTileAsync> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                final msg = await widget.onTap();
                if (widget.showResultSnackBar &&
                    msg != null &&
                    mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: colorScheme.onSurface, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              widget.label,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right, color: colorScheme.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CloudSyncSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLOUD SYNC',
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!isLoggedIn)
          _DataActionTile(
            icon: Icons.cloud_outlined,
            label: 'Sign in to sync',
            onTap: () => context.push('/auth'),
          )
        else
          _LoggedInSyncPanel(),
      ],
    );
  }
}

class _LoggedInSyncPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authServiceProvider);
    final autoSync = ref.watch(autoSyncEnabledProvider);
    final pendingCount =
        ref.watch(pendingChangesCountProvider).valueOrNull ?? 0;
    final syncProgress = ref.watch(syncProgressProvider);
    final syncService = ref.read(syncServiceProvider);
    final lastSync = syncService.lastSyncAt;

    final isSyncing = syncProgress.whenOrNull(
          data: (p) =>
              p.phase != SyncPhase.complete && p.phase != SyncPhase.error,
        ) ??
        false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email display
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle, color: AppColors.accent, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  auth.userEmail,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Auto-sync toggle
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.sync, color: colorScheme.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Auto-sync',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: autoSync,
                onChanged: (_) =>
                    ref.read(autoSyncEnabledProvider.notifier).toggle(),
                activeTrackColor: AppColors.accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Sync now button
        _DataActionTile(
          icon: Icons.cloud_sync,
          label: isSyncing
              ? 'Syncing...'
              : 'Sync Now${pendingCount > 0 ? ' ($pendingCount pending)' : ''}',
          onTap: isSyncing
              ? () {}
              : () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(syncServiceProvider).sync();
                },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Last sync time
        if (lastSync != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Text(
              'Last synced: ${_formatLastSync(lastSync)}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // Sign out
        _DataActionTile(
          icon: Icons.logout,
          label: 'Sign Out',
          destructive: true,
          onTap: () async {
            HapticFeedback.mediumImpact();
            await ref.read(authServiceProvider).logout();
            ref.invalidate(isLoggedInProvider);
            ref.invalidate(moveRepositoryProvider);
            ref.invalidate(comboRepositoryProvider);
            ref.invalidate(reviewRepositoryProvider);
          },
        ),
      ],
    );
  }

  String _formatLastSync(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
