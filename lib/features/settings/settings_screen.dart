import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/app_metadata.dart';
import '../../core/models/app_mode.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/native_share_sheet.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/native_video_album.dart';
import '../../core/utils/share_sheet.dart';
import 'widgets/accent_color_section.dart';
import 'widgets/rating_colors_section.dart';
import 'widgets/review_card_display_section.dart';
import 'widgets/review_states_section.dart';
import '../../core/services/stats_export_service.dart';
import '../../shared/widgets/action_tile.dart';
import '../../core/services/view_names_service.dart';
import '../../shared/widgets/color_setting_tile.dart';
import '../../shared/widgets/settings_list_group.dart';
import 'widgets/cloud_sync_section.dart';
import '../../shared/widgets/shake_detector.dart';
import '../stats/providers/stats_providers.dart';
import 'recently_deleted_screen.dart';

final _settingsMovesProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

enum ReviewSettingsResetAction { cardPlayback, states, all }

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.isTab = false});

  const SettingsScreen.tab({super.key}) : isTab = true;

  final bool isTab;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = ref.watch(themeSettingProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final categories = ref.watch(categoriesProvider);
    final moves =
        ref.watch(_settingsMovesProvider).valueOrNull ?? const <Move>[];
    final archivedMoveCount =
        ref.watch(archivedMovesCountProvider).valueOrNull ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final viewNames = ref.watch(viewNamesProvider);
    final categoryUsage = <String, int>{};
    for (final move in moves) {
      categoryUsage[move.category] = (categoryUsage[move.category] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          children: [
            if (!isTab)
              Semantics(
                identifier: 'settings-back',
                label: 'Back',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        Text(
                          'Back',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!isTab) const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                'Settings',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── PRACTICE & REVIEW ──────────────────────────────────────────
            _SettingsSection(
              title: 'Practice & Review',
              subtitle: 'Learning engine, view composer, and session controls.',
              child: Column(
                children: [
                  _SettingsPanel(
                    title: 'App Mode',
                    child: _SegmentedPicker<AppMode>(
                      values: AppMode.values,
                      selected: ref.watch(appModeProvider),
                      labelOf: (final m) => m.displayName,
                      onChanged: (final m) {
                        HapticFeedback.selectionClick();
                        ref.read(appModeProvider.notifier).set(m);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Learning Engine',
                    child: const _FsrsToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Quiet Mode',
                    child: const _QuietModeToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Review View Composer',
                    child: const ReviewCardDisplaySection(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Party Mode',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ShakeDiscoveryToggle(),
                        const SizedBox(height: AppSpacing.md),
                        _PartyCycleDurationSlider(),
                        const SizedBox(height: AppSpacing.md),
                        _PartyComboModeToggle(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Video Editor',
                    child: const _VideoEditorToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Stats Tab',
                    child: const _StatsTabToggle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── VISUALS & STYLE ───────────────────────────────────────────
            _SettingsSection(
              title: 'Visuals & Style',
              subtitle: 'Theme, typography, colors, and global labels.',
              child: LayoutBuilder(
                builder: (final context, final constraints) {
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
                          title: 'App Theme',
                          child: _SegmentedPicker<ThemeSetting>(
                            values: ThemeSetting.values,
                            selected: theme,
                            labelOf: (final t) => t.displayName,
                            onChanged: (final t) =>
                                ref.read(themeSettingProvider.notifier).set(t),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Typography',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: AppFontFamily.values.map((final f) {
                              final isSelected = f == fontFamily;
                              return ChoiceChip(
                                label: Text(f.displayName),
                                selected: isSelected,
                                onSelected: (_) => ref
                                    .read(fontFamilyProvider.notifier)
                                    .set(f),
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
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Review States',
                          action: TextButton(
                            onPressed: () async {
                              await HapticFeedback.mediumImpact();
                              await ref.read(learningStateLabelsProvider.notifier).reset();
                              await ref.read(learningStateColorsProvider.notifier).resetAll();
                            },
                            child: const Text('Reset'),
                          ),
                          child: ReviewStatesSection(
                            onRename: (final state, final currentLabel) =>
                                _showRenameLearningStateDialog(
                                  context,
                                  ref,
                                  state,
                                  currentLabel,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Colors',
                          child: Column(
                            children: [
                              _SettingsSubPanel(
                                title: 'Accent Color',
                                action: TextButton(
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref.read(accentColorProvider.notifier).reset();
                                  },
                                  child: const Text('Reset'),
                                ),
                                child: const AccentColorSection(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _SettingsSubPanel(
                                title: 'Rating Colors',
                                action: TextButton(
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref.read(ratingColorsProvider.notifier).resetAll();
                                  },
                                  child: const Text('Reset'),
                                ),
                                child: const RatingColorsSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: 'Global Labels',
                          child: ActionTile(
                            icon: Icons.title,
                            label: 'Arsenal Title: ${viewNames['title'] ?? 'Arsenal'}',
                            onTap: () => _showRenameArsenalDialog(
                              context,
                              ref,
                              viewNames['title'] ?? 'Arsenal',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── LIBRARY & DATA ─────────────────────────────────────────────
            _SettingsSection(
              title: 'Library & Data',
              subtitle: 'Categories, backups, and photo library access.',
              child: Column(
                children: [
                  _SettingsPanel(
                    title: 'Move Categories',
                    action: TextButton.icon(
                      onPressed: () => _showAddCategoryDialog(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                    child: SettingsListGroup(
                      children: [
                        for (final cat in categories)
                          _CategoryRow(
                            name: cat.name,
                            color: cat.color,
                            isDefault: cat.isDefault,
                            usageCount: categoryUsage[cat.name] ?? 0,
                            onTap: () =>
                                context.push('/breakdex/moves/${Uri.encodeComponent(cat.name)}'),
                            onLongPress: () => _showCategoryActionsSheet(
                              context,
                              ref,
                              cat,
                              usageCount: categoryUsage[cat.name] ?? 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _PhotosAccessTile(),
                  const SizedBox(height: AppSpacing.md),
                  const CloudSyncSection(),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: 'Backup & Reset',
                    child: Column(
                      children: [
                        _DataActionTileAsync(
                          icon: Icons.ios_share,
                          label: 'Export Stats Summary',
                          onTap: (final tileContext) async {
                            final origin = sharePositionOrigin(tileContext);
                            final stats = await ref.read(statsBundleProvider.future);
                            final summary = StatsExportService.generateTextSummary(stats);
                            await NativeShareSheet.shareText(text: summary, sharePositionOrigin: origin);
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DataActionTileAsync(
                          icon: Icons.file_download_outlined,
                          label: 'Export Full JSON Backup',
                          onTap: (final tileContext) async {
                            final origin = sharePositionOrigin(tileContext);
                            final db = ref.read(databaseProvider);
                            final prefs = ref.read(sharedPreferencesProvider);
                            final result = await StatsExportService.generateJsonExport(db, prefs);
                            final dir = await AppStoragePaths.documentsDirectory();
                            final exportsDir = Directory(p.join(dir.path, 'Exports'));
                            if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
                            final file = File(p.join(exportsDir.path, StatsExportService.exportFilename));
                            await file.writeAsString(result.json, flush: true);
                            await NativeShareSheet.shareFiles(filePaths: [file.path], sharePositionOrigin: origin);
                            return 'Exported ${result.totalRecords} records';
                          },
                          showResultSnackBar: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DataActionTileAsync(
                          icon: Icons.file_upload_outlined,
                          label: 'Import from JSON',
                          onTap: (_) async {
                            await _showImportFlow(context, ref);
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ActionTile(
                          icon: Icons.restore_from_trash_outlined,
                          label: archivedMoveCount == 0 ? 'Recently Deleted' : 'Recently Deleted ($archivedMoveCount)',
                          onTap: () => context.push('/settings-panel/recently-deleted'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ActionTile(
                          icon: Icons.terminal_rounded,
                          label: 'System Status & Logs',
                          onTap: () => context.push('/settings-panel/system-status'),
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Version footer
            Center(
              child: Text(
                AppMetadata.footerLabel,
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

  void _showClearDataDialog(final BuildContext context, final WidgetRef ref) {
    showDialog(
      context: context,
      builder: (final ctx) => StatefulBuilder(
        builder: (final ctx, final setDialogState) {
          final controller = TextEditingController();
          var canConfirm = false;
          return AlertDialog(
            title: const Text('Clear All Data?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes all moves, reviews, combos, and battle results. A backup will be created automatically before clearing.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Type DELETE to confirm:',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (final value) {
                    setDialogState(() {
                      canConfirm = value.trim() == 'DELETE';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: canConfirm
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text(
                  'Clear Everything',
                  style: TextStyle(color: AppColors.actionAgain),
                ),
              ),
            ],
          );
        },
      ),
    ).then((final confirmed) async {
      if (confirmed != true) return;
      await HapticFeedback.mediumImpact();

      // Auto-export a backup before clearing
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      try {
        final backup = await StatsExportService.generateJsonExport(db, prefs);
        final dir = await AppStoragePaths.documentsDirectory();
        final exportsDir = Directory(p.join(dir.path, 'Exports'));
        if (!await exportsDir.exists()) {
          await exportsDir.create(recursive: true);
        }
        final backupFile = File(
          p.join(exportsDir.path, 'breakdex_preclear_${DateTime.now().millisecondsSinceEpoch}.json'),
        );
        await backupFile.writeAsString(backup.json, flush: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pre-clear backup saved to ${backupFile.path.split('/').last}')),
          );
        }
      } catch (e) {
        debugPrint('Pre-clear backup failed: $e');
      }

      final videoService = ref.read(videoServiceProvider);
      // Delete video files before clearing DB
      final moves = await db.movesDao.getAllIncludingArchived();
      for (final move in moves) {
        if (move.videoPath != null) {
          await videoService.deleteVideo(
            VideoPathResolver.toAbsolute(move.videoPath!),
          );
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
    });
  }

  Future<void> _showImportFlow(final BuildContext context, final WidgetRef ref) async {
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
      builder: (final ctx) => AlertDialog(
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
              child: const Text('Replace All (overwrite existing, keep extras)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.merge),
              child: const Text('Merge (skip duplicates, keep everything)'),
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
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
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

  Future<void> _showCategoryActionsSheet(
    final BuildContext context,
    final WidgetRef ref,
    final Category category, {
    required final int usageCount,
  }) async {
    final action = await showModalBottomSheet<_CategorySheetAction>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (final context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: AppTypography.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit category'),
                onTap: () =>
                    Navigator.pop(context, _CategorySheetAction.rename),
              ),
              if (!category.isDefault)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.actionAgain,
                  ),
                  title: const Text(
                    'Delete category',
                    style: TextStyle(color: AppColors.actionAgain),
                  ),
                  onTap: () =>
                      Navigator.pop(context, _CategorySheetAction.delete),
                ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case _CategorySheetAction.rename:
        _showRenameCategoryDialog(context, ref, category);
        return;
      case _CategorySheetAction.delete:
        final confirmed = await _confirmDeleteCategory(
          context,
          category,
          usageCount: usageCount,
        );
        if (!confirmed) return;
        await HapticFeedback.mediumImpact();
        await ref
            .read(categoriesProvider.notifier)
            .removeCategory(category.name);
        return;
    }
  }

  void _showRenameCategoryDialog(
    final BuildContext context,
    final WidgetRef ref,
    final Category cat,
  ) {
    showDialog(
      context: context,
      builder: (final context) {
        final controller = TextEditingController(text: cat.name);
        Color selectedColor = cat.color;
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
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
                ColorSettingTile(
                  title: 'Category color',
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: 'Category Color',
                      subtitle: 'Pick any color for this category label.',
                      presets: categoryPresetColors,
                    );
                    if (nextColor == null || !context.mounted) return;
                    setDialogState(() => selectedColor = nextColor);
                  },
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
                        (final item) => item.name == newName && item.name != cat.name,
                      );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$newName" already exists.')),
                    );
                    return;
                  }

                  ref
                      .read(categoriesProvider.notifier)
                      .renameCategory(
                        cat.name,
                        newName,
                        selectedColor,
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
    final BuildContext context,
    final WidgetRef ref,
    final String current,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (final ctx) => AlertDialog(
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

  void _showRenameLearningStateDialog(
    final BuildContext context,
    final WidgetRef ref,
    final LearningState state,
    final String current,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text('Rename ${defaultLearningStateLabels[state]}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: defaultLearningStateLabels[state],
          ),
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
                ref
                    .read(learningStateLabelsProvider.notifier)
                    .rename(state, name);
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

  void _showAddCategoryDialog(final BuildContext context, final WidgetRef ref) {
    showDialog(
      context: context,
      builder: (final context) {
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
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
                ColorSettingTile(
                  title: 'Category color',
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: 'Category Color',
                      subtitle: 'Pick any color for this category label.',
                      presets: categoryPresetColors,
                    );
                    if (nextColor == null || !context.mounted) return;
                    setDialogState(() => selectedColor = nextColor);
                  },
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
                      .any((final item) => item.name == name);
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
    final BuildContext context,
    final Category category, {
    required final int usageCount,
  }) async {
    if (usageCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (final ctx) => AlertDialog(
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

    return true;
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
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: values.map((final v) {
          final isSelected = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final Color color;
  final bool isDefault;
  final int usageCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = [
      if (isDefault) 'Default',
      usageCount == 0 ? 'Unused' : '$usageCount moves',
    ].join(' · ');

    return SettingsListRow(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: name,
      subtitle: meta,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.secondary,
        size: 18,
      ),
    );
  }
}

enum _CategorySheetAction { rename, delete }

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
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
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SettingsSubPanel extends StatelessWidget {
  const _SettingsSubPanel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...switch (action) {
                final value? => <Widget>[value],
                null => const <Widget>[],
              },
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
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
  final Future<String?> Function(BuildContext context) onTap;
  final bool showResultSnackBar;

  @override
  State<_DataActionTileAsync> createState() => _DataActionTileAsyncState();
}

class _DataActionTileAsyncState extends State<_DataActionTileAsync> {
  bool _loading = false;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    return InkWell(
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                final msg = await widget.onTap(context);
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

class _PhotosAccessTile extends ConsumerWidget {
  const _PhotosAccessTile();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final status = ref.watch(photoLibraryAccessStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsPanel(
      title: 'Photo Library',
      child: status.when(
        data: (final access) => SettingsListGroup(
          children: [
            SettingsListRow(
              title: _statusDisplayName(access),
              subtitle: _statusDescription(access),
              leading: Icon(
                _statusIcon(access),
                size: 20,
                color: access == PhotoLibraryAccessStatus.authorized
                    ? AppColors.actionGood
                    : colorScheme.secondary,
              ),
              onTap: access == PhotoLibraryAccessStatus.denied ||
                      access == PhotoLibraryAccessStatus.restricted
                  ? () => NativeVideoAlbum().openSettings()
                  : access == PhotoLibraryAccessStatus.notDetermined
                      ? () => ref.invalidate(photoLibraryAccessStatusProvider)
                      : null,
              trailing: access == PhotoLibraryAccessStatus.denied ||
                      access == PhotoLibraryAccessStatus.restricted
                  ? Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.secondary,
                    )
                  : null,
            ),
          ],
        ),
        loading: () => const SettingsListGroup(
          children: [
            SettingsListRow(
              title: 'Photo Library',
              subtitle: 'Checking access…',
              leading: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
        error: (_, _) => const SettingsListGroup(
          children: [
            SettingsListRow(
              title: 'Photo Library',
              subtitle: 'Unable to check access',
              leading: Icon(Icons.error_outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusDisplayName(final PhotoLibraryAccessStatus status) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined => 'Not Determined',
      PhotoLibraryAccessStatus.restricted => 'Restricted',
      PhotoLibraryAccessStatus.denied => 'Denied',
      PhotoLibraryAccessStatus.authorized => 'Full Access',
      PhotoLibraryAccessStatus.limited => 'Limited Access',
      PhotoLibraryAccessStatus.unknown => 'Unknown',
    };
  }

  static String _statusDescription(final PhotoLibraryAccessStatus status) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined => 'Tap to request access',
      PhotoLibraryAccessStatus.restricted => 'Tap to open Settings',
      PhotoLibraryAccessStatus.denied => 'Tap to open Settings',
      PhotoLibraryAccessStatus.authorized => 'All photos available',
      PhotoLibraryAccessStatus.limited => 'Some photos may be unavailable',
      PhotoLibraryAccessStatus.unknown => 'Could not determine access',
    };
  }

  static IconData _statusIcon(final PhotoLibraryAccessStatus status) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined => Icons.help_outline,
      PhotoLibraryAccessStatus.restricted => Icons.lock_outline,
      PhotoLibraryAccessStatus.denied => Icons.block,
      PhotoLibraryAccessStatus.authorized => Icons.check_circle_outline,
      PhotoLibraryAccessStatus.limited => Icons.photo_library_outlined,
      PhotoLibraryAccessStatus.unknown => Icons.error_outline,
    };
  }
}

class _PartyCycleDurationSlider extends ConsumerWidget {
  static const _minMs = 1000;
  static const _maxMs = 15000;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final durationMs = ref.watch(partyCycleDurationMsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shake cycle duration',
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: durationMs.toDouble(),
                min: _minMs.toDouble(),
                max: _maxMs.toDouble(),
                divisions: (_maxMs - _minMs) ~/ 100,
                activeColor: colorScheme.primary,
                onChanged: (final value) {
                  ref
                      .read(partyCycleDurationMsProvider.notifier)
                      .set(value.round());
                },
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${(durationMs / 1000).toStringAsFixed(1)}s',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_minMs / 1000).toStringAsFixed(1)}s',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            Text(
              '${(_maxMs / 1000).toStringAsFixed(1)}s',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PartyComboModeToggle extends ConsumerWidget {
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isEnabled = ref.watch(partyComboModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Combo mode',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shake to discover random combos instead of moves',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: isEnabled,
          activeThumbColor: colorScheme.primary,
          onChanged: (_) {
            ref.read(partyComboModeProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}

class _VideoEditorToggle extends ConsumerWidget {
  const _VideoEditorToggle();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final useSimplified = ref.watch(useSimplifiedVideoEditorProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use simplified editor',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Switch to the legacy editor if the robust editor is unstable.',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: useSimplified,
          activeThumbColor: colorScheme.primary,
          onChanged: (_) {
            ref.read(useSimplifiedVideoEditorProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}

class _FsrsToggle extends ConsumerWidget {
  const _FsrsToggle();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isEnabled = ref.watch(fsrsEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FSRS (Spaced Repetition)',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnabled
                    ? 'Smart scheduling enabled'
                    : 'Manual progression only',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: isEnabled,
          activeThumbColor: colorScheme.primary,
          onChanged: (final value) {
            ref.read(fsrsEnabledProvider.notifier).set(enabled: value);
          },
        ),
      ],
    );
  }
}

class _ShakeDiscoveryToggle extends ConsumerWidget {
  const _ShakeDiscoveryToggle();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isEnabled = ref.watch(shakeEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shake to Discover',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shake your device to shuffle items in Party mode.',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: isEnabled,
          activeThumbColor: colorScheme.primary,
          onChanged: (final value) {
            ref.read(shakeEnabledProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}

class _QuietModeToggle extends ConsumerWidget {
  const _QuietModeToggle();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isEnabled = ref.watch(quietModeEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep music playing',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Videos will start muted to avoid interrupting your music.',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: isEnabled,
          activeThumbColor: colorScheme.primary,
          onChanged: (final value) {
            ref.read(quietModeEnabledProvider.notifier).set(enabled: value);
          },
        ),
      ],
    );
  }
}

class _StatsTabToggle extends ConsumerWidget {
  const _StatsTabToggle();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isEnabled = ref.watch(showStatsTabProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Show Stats Tab',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enable the insights tab in the bottom navigation.',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: isEnabled,
          activeThumbColor: colorScheme.primary,
          onChanged: (_) {
            ref.read(showStatsTabProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}

