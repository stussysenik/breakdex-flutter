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
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/services/app_storage_paths.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/native_share_sheet.dart';
import '../../core/services/video_path_resolver.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/share_sheet.dart';
import 'widgets/cloud_sync_section.dart';
import 'widgets/accent_color_section.dart';
import 'widgets/rating_colors_section.dart';
import 'widgets/review_card_display_section.dart';
import 'widgets/review_states_section.dart';
import '../../core/services/stats_export_service.dart';
import '../../shared/widgets/action_tile.dart';
import '../../core/services/view_names_service.dart';
import '../../shared/widgets/color_setting_tile.dart';
import '../../shared/widgets/settings_list_group.dart';
import '../stats/providers/stats_providers.dart';
import 'recently_deleted_screen.dart';

final _settingsMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

enum ReviewSettingsResetAction { cardPlayback, states, all }

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
    final archivedMoveCount =
        ref.watch(archivedMovesCountProvider).valueOrNull ?? 0;
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
            const SizedBox(height: AppSpacing.lg),

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
            const SizedBox(height: AppSpacing.lg),

            // Cloud Sync — no auth dependency, iCloud uses device Apple ID
            const CloudSyncSection(),
            const SizedBox(height: AppSpacing.lg),

            _SettingsSection(
              title: 'Categories',
              subtitle: 'Used across review, decks, stats, and albums.',
              child: _SettingsPanel(
                title: 'Move Semantics',
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
                        onTap: () => _showCategoryActionsSheet(
                          context,
                          ref,
                          cat,
                          usageCount: categoryUsage[cat.name] ?? 0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SettingsSection(
              title: 'Review',
              subtitle:
                  'Quiet playback, first-look card details, and review states.',
              child: _SettingsPanel(
                title: 'Cards & States',
                action: PopupMenuButton<ReviewSettingsResetAction>(
                  tooltip: 'Reset review settings',
                  onSelected: (action) async {
                    await HapticFeedback.mediumImpact();
                    switch (action) {
                      case ReviewSettingsResetAction.cardPlayback:
                        await ref
                            .read(reviewCardDisplaySettingsProvider.notifier)
                            .reset();
                        await ref
                            .read(silentPracticePlaybackProvider.notifier)
                            .reset();
                      case ReviewSettingsResetAction.states:
                        await ref
                            .read(learningStateLabelsProvider.notifier)
                            .reset();
                        await ref
                            .read(learningStateColorsProvider.notifier)
                            .resetAll();
                      case ReviewSettingsResetAction.all:
                        await ref
                            .read(reviewCardDisplaySettingsProvider.notifier)
                            .reset();
                        await ref
                            .read(silentPracticePlaybackProvider.notifier)
                            .reset();
                        await ref
                            .read(learningStateLabelsProvider.notifier)
                            .reset();
                        await ref
                            .read(learningStateColorsProvider.notifier)
                            .resetAll();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ReviewSettingsResetAction.cardPlayback,
                      child: Text('Reset card + playback'),
                    ),
                    PopupMenuItem(
                      value: ReviewSettingsResetAction.states,
                      child: Text('Reset state names + colors'),
                    ),
                    PopupMenuItem(
                      value: ReviewSettingsResetAction.all,
                      child: Text('Reset all review settings'),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card & Playback',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const ReviewCardDisplaySection(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'State Names & Colors',
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ReviewStatesSection(
                      onRename: (state, currentLabel) =>
                          _showRenameLearningStateDialog(
                            context,
                            ref,
                            state,
                            currentLabel,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SettingsSection(
              title: 'Colors',
              subtitle: 'Accent and grading colors.',
              child: Column(
                children: [
                  _SettingsPanel(
                    title: 'Accent',
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
                  _SettingsPanel(
                    title: 'Ratings',
                    action: TextButton(
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        await ref
                            .read(ratingColorsProvider.notifier)
                            .resetAll();
                      },
                      child: const Text('Reset'),
                    ),
                    child: const RatingColorsSection(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SettingsSection(
              title: 'Diagnostics',
              subtitle:
                  'Developer-facing recovery signals for crashes, loading, and self-healing flows.',
              child: _SettingsPanel(
                title: 'Provenance',
                action: TextButton(
                  onPressed: () => ref.invalidate(provenanceReportProvider),
                  child: const Text('Refresh'),
                ),
                child: Builder(
                  builder: (tileContext) {
                    final provenanceReport = ref.watch(
                      provenanceReportProvider,
                    );
                    return provenanceReport.when(
                      data: (report) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.headline,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SettingsListGroup(
                            children: [
                              SettingsListRow(
                                title: 'Recent events scanned',
                                subtitle:
                                    '${report.totalEvents} journal entries from the local provenance ledger.',
                              ),
                              SettingsListRow(
                                title: 'Crash signals',
                                subtitle:
                                    '${report.crashCount} recent Flutter/platform captures.',
                              ),
                              SettingsListRow(
                                title: 'Retrieval failures',
                                subtitle:
                                    '${report.retrievalFailureCount} recent video loading failures.',
                              ),
                              SettingsListRow(
                                title: 'DB recovery activity',
                                subtitle:
                                    '${report.databaseRecoveryCount} recent database recovery events.',
                              ),
                            ],
                          ),
                          if (report.recentCriticalEvents.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Latest critical signals',
                              style: AppTypography.caption.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SettingsListGroup(
                              children: report.recentCriticalEvents
                                  .map(
                                    (event) => SettingsListRow(
                                      title: event.eventType,
                                      subtitle: report.describeEvent(event),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _DataActionTileAsync(
                            icon: Icons.bug_report_outlined,
                            label: 'Export Provenance Log',
                            onTap: (_) async {
                              final origin = sharePositionOrigin(tileContext);
                              final file = await ref
                                  .read(provenanceJournalServiceProvider)
                                  .journalFile();
                              if (!await file.exists()) {
                                await file.writeAsString('', flush: true);
                              }
                              await NativeShareSheet.shareFiles(
                                filePaths: [file.path],
                                sharePositionOrigin: origin,
                              );
                              return 'Shared provenance ledger for debugging';
                            },
                            showResultSnackBar: true,
                          ),
                        ],
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text(
                        'Diagnostics unavailable: $error',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.actionAgain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SettingsSection(
              title: 'Data',
              subtitle: 'Backups, imports, and destructive actions.',
              child: _SettingsPanel(
                title: 'Backup & Reset',
                child: Column(
                  children: [
                    _DataActionTileAsync(
                      icon: Icons.ios_share,
                      label: 'Export Stats',
                      onTap: (tileContext) async {
                        final origin = sharePositionOrigin(tileContext);
                        final stats = await ref.read(
                          statsBundleProvider.future,
                        );
                        final summary = StatsExportService.generateTextSummary(
                          stats,
                        );
                        await NativeShareSheet.shareText(
                          text: summary,
                          sharePositionOrigin: origin,
                        );
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DataActionTileAsync(
                      icon: Icons.file_download_outlined,
                      label: 'Export Full Backup',
                      onTap: (tileContext) async {
                        final origin = sharePositionOrigin(tileContext);
                        final db = ref.read(databaseProvider);
                        final prefs = ref.read(sharedPreferencesProvider);
                        final result =
                            await StatsExportService.generateJsonExport(
                              db,
                              prefs,
                            );
                        final dir = await AppStoragePaths.documentsDirectory();
                        final exportsDir = Directory(
                          p.join(dir.path, 'Exports'),
                        );
                        if (!await exportsDir.exists()) {
                          await exportsDir.create(recursive: true);
                        }
                        final file = File(
                          p.join(
                            exportsDir.path,
                            StatsExportService.exportFilename,
                          ),
                        );
                        await file.writeAsString(result.json, flush: true);
                        final fileSize = await file.length();
                        debugPrint(
                          '[SettingsExport] Prepared backup at ${file.path}'
                          ' ($fileSize bytes)',
                        );
                        if (fileSize == 0) {
                          throw const FileSystemException(
                            'Exported backup file is empty',
                          );
                        }
                        await NativeShareSheet.shareFiles(
                          filePaths: [file.path],
                          sharePositionOrigin: origin,
                        );
                        return 'Exported ${result.totalRecords} records (${result.moveCount} moves, ${result.reviewCount} reviews, ${result.comboCount} combos)';
                      },
                      showResultSnackBar: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DataActionTileAsync(
                      icon: Icons.file_upload_outlined,
                      label: 'Import Backup',
                      onTap: (_) async {
                        await _showImportFlow(context, ref);
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ActionTile(
                      icon: Icons.restore_from_trash_outlined,
                      label: archivedMoveCount == 0
                          ? 'Recently Deleted'
                          : 'Recently Deleted ($archivedMoveCount)',
                      onTap: () => context.push('/settings/recently-deleted'),
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
            const SizedBox(height: AppSpacing.lg),

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
              await HapticFeedback.mediumImpact();
              final db = ref.read(databaseProvider);
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
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required int usageCount,
  }) async {
    final action = await showModalBottomSheet<_CategorySheetAction>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
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

  void _showRenameLearningStateDialog(
    BuildContext context,
    WidgetRef ref,
    LearningState state,
    String current,
  ) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool isDefault;
  final int usageCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final meta = [
      if (isDefault) 'Default',
      usageCount == 0 ? 'Unused' : '$usageCount moves',
    ].join(' · ');

    return SettingsListRow(
      onTap: onTap,
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
