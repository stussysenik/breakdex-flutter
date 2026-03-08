import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/sync_progress.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/stats_export_service.dart';
import '../../shared/widgets/action_tile.dart';
import '../../core/services/view_names_service.dart';
import '../stats/providers/stats_providers.dart';

final _settingsMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

/// Reusable color swatch grid for category/rating color pickers.
Widget _colorSwatchGrid({
  required List<Color> colors,
  required Color selected,
  required ValueChanged<Color> onSelected,
  double size = 32,
}) {
  return Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: colors.map((c) {
      final isSelected = c.toARGB32() == selected.toARGB32();
      return GestureDetector(
        onTap: () => onSelected(c),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: isSelected
                ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
      );
    }).toList(),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingProvider);
    final viewingMode = ref.watch(viewingModeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final categories = ref.watch(categoriesProvider);
    final moves =
        ref.watch(_settingsMovesProvider).valueOrNull ?? const <Move>[];
    final colorScheme = Theme.of(context).colorScheme;
    final categoryUsage = <String, int>{};
    for (final move in moves) {
      categoryUsage[move.category] = (categoryUsage[move.category] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                'Settings',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SettingsSection(
              title: 'Appearance',
              subtitle:
                  'Standardized controls for theme, typography, and naming.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTwoColumn = constraints.maxWidth >= 640;
                  final panelWidth = isTwoColumn
                      ? (constraints.maxWidth - AppSpacing.md) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Viewing',
                          child: _SegmentedPicker<ViewingMode>(
                            values: ViewingMode.values,
                            selected: viewingMode,
                            labelOf: (mode) => mode.displayName,
                            onChanged: (mode) => ref
                                .read(viewingModeProvider.notifier)
                                .set(mode),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Theme',
                          child: _SegmentedPicker<ThemeSetting>(
                            values: ThemeSetting.values,
                            selected: theme,
                            labelOf: (t) => t.displayName,
                            onChanged: (t) =>
                                ref.read(themeSettingProvider.notifier).set(t),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Font',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: AppFontFamily.values.map((f) {
                              final isSelected = f == fontFamily;
                              return ChoiceChip(
                                label: Text(f.displayName),
                                selected: isSelected,
                                onSelected: (_) =>
                                    ref.read(fontFamilyProvider.notifier).set(f),
                                selectedColor: colorScheme.primary,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outline.withValues(
                                          alpha: 0.45,
                                        ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                labelStyle: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final viewNames = ref.watch(viewNamesProvider);
                          return SizedBox(
                            width: panelWidth,
                            child: _SettingsPanel(
                              title: 'Labels',
                              child: ActionTile(
                                icon: Icons.title,
                                label:
                                    'Page Title: ${viewNames['title'] ?? 'Arsenal'}',
                                onTap: () => _showRenameArsenalDialog(
                                  context,
                                  ref,
                                  viewNames['title'] ?? 'Arsenal',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SettingsSection(
              title: 'Categories',
              subtitle:
                  'These semantic labels drive review, decks, stats, and gallery organization.',
              child: _SettingsPanel(
                title: 'Move Semantics',
                child: Column(
                  children: [
                    for (final cat in categories)
                      Dismissible(
                        key: ValueKey(cat.name),
                        direction: cat.isDefault
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(
                            right: AppSpacing.screenEdge,
                          ),
                          color: AppColors.actionAgain,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(categoriesProvider.notifier)
                              .removeCategory(cat.name);
                        },
                        confirmDismiss: (_) => _confirmDeleteCategory(
                          context,
                          cat,
                          usageCount: categoryUsage[cat.name] ?? 0,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              _showRenameCategoryDialog(context, ref, cat),
                          child: _CategoryRow(
                            name: cat.name,
                            color: cat.color,
                            isDefault: cat.isDefault,
                            usageCount: categoryUsage[cat.name] ?? 0,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showAddCategoryDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Add Category',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SettingsSection(
              title: 'Colors',
              subtitle:
                  'Outlined panels keep system color choices visually consistent.',
              child: Column(
                children: [
                  _SettingsPanel(
                    title: 'Learning States',
                    child: Column(
                      children: [
                        for (final state in LearningState.values)
                          _StateColorRow(state: state),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SettingsPanel(
                    title: 'Accent',
                    child: _AccentColorSection(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SettingsPanel(
                    title: 'Ratings',
                    child: _RatingColorsSection(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SettingsSection(
              title: 'Data',
              subtitle:
                  'Backups, imports, and destructive actions are grouped together.',
              child: _SettingsPanel(
                title: 'Backup & Reset',
                child: Column(
                  children: [
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
                        final result = await StatsExportService.generateJsonExport(
                          db,
                          prefs,
                        );
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
                    ActionTile(
                      icon: Icons.delete_forever,
                      label: 'Clear All Data',
                      destructive: true,
                      onTap: () => _showClearDataDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Cloud Sync
            _CloudSyncSection(),
            const SizedBox(height: AppSpacing.xl),

            // Version footer
            Center(
              child: Text(
                'Breakdex v0.5.0 (Build 1)',
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
              await db.delete(db.fsrsCards).go();
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
        db,
        prefs,
        json,
        mode,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      // Invalidate all providers so UI refreshes
      ref.invalidate(statsBundleProvider);
      ref.invalidate(categoriesProvider);

      final msg =
          'Imported ${importResult.totalImported} records'
          '${importResult.movesWithMissingVideos.isNotEmpty ? ' (${importResult.movesWithMissingVideos.length} moves need video re-linking)' : ''}';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: cat.name);
        Color selectedColor = cat.color;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Rename Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Category name'),
                ),
                const SizedBox(height: AppSpacing.md),
                _colorSwatchGrid(
                  colors: categoryPresetColors,
                  selected: selectedColor,
                  onSelected: (c) => setDialogState(() => selectedColor = c),
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
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category name cannot be empty.'),
                      ),
                    );
                    return;
                  }

                  final exists = ref
                      .read(categoriesProvider)
                      .any(
                        (item) => item.name == newName && item.name != cat.name,
                      );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$newName" already exists.')),
                    );
                    return;
                  }

                  final movesDao = ref.read(databaseProvider).movesDao;
                  ref
                      .read(categoriesProvider.notifier)
                      .renameCategory(
                        cat.name,
                        newName,
                        selectedColor,
                        movesDao,
                      );
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameArsenalDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Page Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Page title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(viewNamesProvider.notifier).rename('title', name);
                HapticFeedback.mediumImpact();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
                _colorSwatchGrid(
                  colors: categoryPresetColors,
                  selected: selectedColor,
                  onSelected: (c) => setDialogState(() => selectedColor = c),
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
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category name cannot be empty.'),
                      ),
                    );
                    return;
                  }

                  final exists = ref
                      .read(categoriesProvider)
                      .any((item) => item.name == name);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$name" already exists.')),
                    );
                    return;
                  }

                  ref
                      .read(categoriesProvider.notifier)
                      .addCategory(name, selectedColor);
                  HapticFeedback.mediumImpact();
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

  Future<bool> _confirmDeleteCategory(
    BuildContext context,
    Category category, {
    required int usageCount,
  }) async {
    if (usageCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category In Use'),
          content: Text(
            'Reassign the $usageCount move${usageCount == 1 ? '' : 's'} in "${category.name}" before deleting it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete "${category.name}"?'),
            content: const Text(
              'This removes the category label from settings. Existing moves must be reassigned first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.actionAgain),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Generic segmented picker — replaces _ThemePicker and _FontPicker.
class _SegmentedPicker<T> extends StatelessWidget {
  const _SegmentedPicker({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.fontSize,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labelOf(v),
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.secondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
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
    required this.usageCount,
  });

  final String name;
  final Color color;
  final bool isDefault;
  final int usageCount;

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
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
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
          const SizedBox(width: 8),
          Text(
            usageCount == 0 ? 'Unused' : '$usageCount moves',
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.sectionHeader.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
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
            child: Text(
              state.displayText,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '#${state.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: AppTypography.caption.copyWith(color: colorScheme.secondary),
          ),
        ],
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
    final messenger = ScaffoldMessenger.of(context);
    return InkWell(
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                final msg = await widget.onTap();
                if (widget.showResultSnackBar && msg != null && mounted) {
                  messenger.showSnackBar(SnackBar(content: Text(msg)));
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.22),
          ),
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
          ActionTile(
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

    final isSyncing =
        syncProgress.whenOrNull(
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
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
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
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.22),
            ),
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
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Sync now button
        ActionTile(
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
        ActionTile(
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

// -- Accent Color Section -----------------------------------------------------

/// Curated accent color palette for global UI personalization.
const _accentPresetColors = [
  Color(0xFF2362A2), // Default blue
  Color(0xFF6929C4), // Violet
  Color(0xFF8A3FFC), // Purple
  Color(0xFFDA1E28), // Red
  Color(0xFFFF6F00), // Amber
  Color(0xFF198038), // Green
  Color(0xFF08BDBA), // Teal
  Color(0xFF33B1FF), // Sky blue
  Color(0xFFE040FB), // Magenta
  Color(0xFFFF7EB6), // Pink
  Color(0xFFD4A017), // Gold
  Color(0xFFA2AAB4), // Neutral
];

class _AccentColorSection extends ConsumerWidget {
  const _AccentColorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Accent Color',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(accentColorProvider.notifier).reset();
              },
              child: Text(
                'Reset',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '#${accent.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _colorSwatchGrid(
          colors: _accentPresetColors,
          selected: accent,
          size: 36,
          onSelected: (c) {
            HapticFeedback.mediumImpact();
            ref.read(accentColorProvider.notifier).set(c);
          },
        ),
      ],
    );
  }
}

// -- Rating Colors Section ---------------------------------------------------

/// Preset palette for rating color customization.
const _ratingPresetColors = [
  Color(0xFFDA1E28), // Red
  Color(0xFFFF6F00), // Amber
  Color(0xFF8E6A00), // Gold
  Color(0xFFE040FB), // Purple
  Color(0xFF198038), // Green
  Color(0xFF08BDBA), // Teal
  Color(0xFF2362A2), // Blue
  Color(0xFF6929C4), // Violet
];

class _RatingColorsSection extends ConsumerWidget {
  const _RatingColorsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rc = ref.watch(ratingColorsProvider);

    final entries = [
      ('AGAIN', 'again', rc.again, Icons.close_rounded),
      ('HARD', 'hard', rc.hard, Icons.remove_rounded),
      ('GOOD', 'good', rc.good, Icons.check_rounded),
      ('EASY', 'easy', rc.easy, Icons.star_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rating Buttons',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(ratingColorsProvider.notifier).resetAll();
              },
              child: Text(
                'Reset',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (label, key, color, icon) in entries)
          _RatingColorRow(
            label: label,
            colorKey: key,
            currentColor: color,
            icon: icon,
          ),
      ],
    );
  }
}

class _RatingColorRow extends ConsumerWidget {
  const _RatingColorRow({
    required this.label,
    required this.colorKey,
    required this.currentColor,
    required this.icon,
  });

  final String label;
  final String colorKey;
  final Color currentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _showColorPicker(context, ref),
        child: Row(
          children: [
            Icon(icon, size: 18, color: currentColor),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Color'),
        content: _colorSwatchGrid(
          colors: _ratingPresetColors,
          selected: currentColor,
          size: 40,
          onSelected: (c) {
            HapticFeedback.mediumImpact();
            ref.read(ratingColorsProvider.notifier).setColor(colorKey, c);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
