// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.  discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: avoid_slow_async_io, discarded_futures

import 'dart:async';
import 'package:breakdex/core/platform/io.dart';
import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/app_metadata.dart';
import 'package:breakdex/core/models/add_flow_order.dart';
import 'package:breakdex/core/models/app_mode.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/move_detail_caption.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/app_storage_paths.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/native_share_sheet.dart';
import 'package:breakdex/core/services/video_path_resolver.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/services/native_video_album.dart';
import 'package:breakdex/core/utils/share_sheet.dart';
import 'package:breakdex/features/settings/widgets/accent_color_section.dart';
import 'package:breakdex/features/settings/widgets/rating_colors_section.dart';
import 'package:breakdex/features/settings/widgets/review_card_display_section.dart';
import 'package:breakdex/features/settings/widgets/review_fill_color_section.dart';
import 'package:breakdex/features/settings/widgets/review_states_section.dart';
import 'package:breakdex/core/services/stats_export_service.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/state_pill.dart';
import 'package:breakdex/features/flashcard_review/widgets/rating_button_row.dart';
import 'package:breakdex/shared/widgets/action_tile.dart';
import 'package:breakdex/core/services/view_names_service.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/shared/widgets/color_setting_tile.dart';
import 'package:breakdex/shared/widgets/settings_list_group.dart';
import 'package:breakdex/features/settings/widgets/cloud_sync_section.dart';
import 'package:breakdex/features/dev/sync_cutover_panel.dart';
import 'package:breakdex/shared/widgets/shake_detector.dart';
import 'package:breakdex/features/stats/providers/stats_providers.dart';
import 'package:breakdex/features/settings/recently_deleted_screen.dart';
import 'package:breakdex/core/design/icons.dart';

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
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeSettingProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final categories = ref.watch(categoriesProvider);
    final moves =
        ref.watch(_settingsMovesProvider).valueOrNull ?? const <Move>[];
    final archivedMoveCount =
        ref.watch(archivedMovesCountProvider).valueOrNull ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final viewNames = ref.watch(viewNamesProvider);
    final entityNames = ref.watch(entityNamesProvider);
    final palette = ref.watch(accessiblePaletteProvider);
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
                label: l10n.setBack,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        AppIconView(
                          AppIcon.back,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        Text(
                          l10n.setBack,
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
                l10n.navSettings,
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── PRACTICE & REVIEW ──────────────────────────────────────────
            _SettingsSection(
              title: l10n.setSectionPractice,
              child: Column(
                children: [
                  _SettingsPanel(
                    title: l10n.setPanelAppMode,
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
                    title: l10n.setPanelLearningEngine,
                    child: const _FsrsToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelQuietMode,
                    child: const _QuietModeToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelViewComposer,
                    child: const ReviewCardDisplaySection(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelPartyMode,
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
                    title: l10n.setPanelVideoEditor,
                    child: const _VideoEditorToggle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelAddFlow,
                    child: _SegmentedPicker<AddFlowOrder>(
                      values: AddFlowOrder.values,
                      selected: ref.watch(addFlowOrderProvider),
                      labelOf: (final o) => o.displayName,
                      onChanged: (final o) {
                        HapticFeedback.selectionClick();
                        ref.read(addFlowOrderProvider.notifier).set(o);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelStatsTab,
                    child: const _StatsTabToggle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── VISUALS & STYLE ───────────────────────────────────────────
            _SettingsSection(
              title: l10n.setSectionVisuals,
              subtitle: l10n.setSectionVisualsSubtitle,
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
                          title: l10n.setPanelAppTheme,
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
                          title: l10n.setPanelAccessibility,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SegmentedPicker<AccessiblePalette>(
                                values: AccessiblePalette.values,
                                selected: palette,
                                labelOf: (final p) => p.displayName,
                                onChanged: (final p) => ref
                                    .read(accessiblePaletteProvider.notifier)
                                    .set(p),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                palette.description,
                                style: AppTypography.caption.copyWith(
                                  color: colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _AccessiblePalettePreview(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: l10n.setPanelTypography,
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
                          title: l10n.setPanelReviewStates,
                          action: TextButton(
                            onPressed: () async {
                              await HapticFeedback.mediumImpact();
                              await ref
                                  .read(learningStateLabelsProvider.notifier)
                                  .reset();
                              await ref
                                  .read(learningStateColorsProvider.notifier)
                                  .resetAll();
                            },
                            child: Text(l10n.setReset),
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
                          title: l10n.setPanelColors,
                          child: Column(
                            children: [
                              _SettingsSubPanel(
                                title: l10n.setAccentColorLabel,
                                action: TextButton(
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref
                                        .read(accentColorProvider.notifier)
                                        .reset();
                                  },
                                  child: Text(l10n.setReset),
                                ),
                                child: const AccentColorSection(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _SettingsSubPanel(
                                title: l10n.setRatingColorsLabel,
                                action: TextButton(
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref
                                        .read(ratingColorsProvider.notifier)
                                        .resetAll();
                                  },
                                  child: Text(l10n.setReset),
                                ),
                                child: const RatingColorsSection(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _SettingsSubPanel(
                                title: l10n.setReviewCardFillLabel,
                                action: TextButton(
                                  onPressed: () async {
                                    await HapticFeedback.mediumImpact();
                                    await ref
                                        .read(reviewFillColorProvider.notifier)
                                        .reset();
                                  },
                                  child: Text(l10n.setReset),
                                ),
                                child: const ReviewFillColorSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: panelWidth,
                        child: _SettingsPanel(
                          title: l10n.setPanelGlobalLabels,
                          child: SettingsListGroup(
                            children: [
                              ActionTile(
                                icon: AppIcon.notes.resolve(context),
                                label: l10n.setLabelArsenalTitle(
                                  viewNames['title'] ?? 'Arsenal',
                                ),
                                onTap: () => _showRenameArsenalDialog(
                                  context,
                                  ref,
                                  viewNames['title'] ?? 'Arsenal',
                                ),
                              ),
                              ActionTile(
                                icon: AppIcon.move.resolve(context),
                                label: l10n.setLabelMovesDataBank(
                                  entityNames.movePlural,
                                ),
                                onTap: () => _showRenameEntityDialog(
                                  context,
                                  ref,
                                  current: entityNames,
                                  singularField: EntityNameField.moveSingular,
                                  pluralField: EntityNameField.movePlural,
                                ),
                              ),
                              ActionTile(
                                icon: AppIcon.link.resolve(context),
                                label: l10n.setLabelCombosDataBank(
                                  entityNames.comboPlural,
                                ),
                                onTap: () => _showRenameEntityDialog(
                                  context,
                                  ref,
                                  current: entityNames,
                                  singularField: EntityNameField.comboSingular,
                                  pluralField: EntityNameField.comboPlural,
                                ),
                              ),
                            ],
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
              title: l10n.setSectionLibrary,
              subtitle: l10n.setSectionLibrarySubtitle,
              child: Column(
                children: [
                  _SettingsPanel(
                    title: l10n.setPanelMoveCategories,
                    action: TextButton.icon(
                      onPressed: () => _showAddCategoryDialog(context, ref),
                      icon: const AppIconView(AppIcon.add, size: 16),
                      label: Text(l10n.setAdd),
                    ),
                    child: SettingsListGroup(
                      children: [
                        for (final cat in categories)
                          _CategoryRow(
                            name: cat.name,
                            color: cat.color,
                            isDefault: cat.isDefault,
                            usageCount: categoryUsage[cat.name] ?? 0,
                            onTap: () => context.push(
                              '/breakdex/moves/${Uri.encodeComponent(cat.name)}',
                            ),
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
                  _SettingsPanel(
                    title: l10n.setPanelMoveCaption,
                    child: _SegmentedPicker<MoveDetailCaption>(
                      values: MoveDetailCaption.values,
                      selected: ref.watch(moveDetailCaptionProvider),
                      labelOf: (final c) => c.displayName,
                      fontSize: 11,
                      onChanged: (final c) {
                        HapticFeedback.selectionClick();
                        ref.read(moveDetailCaptionProvider.notifier).set(c);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _PhotosAccessTile(),
                  const SizedBox(height: AppSpacing.md),
                  const CloudSyncSection(),
                  const SizedBox(height: AppSpacing.md),
                  _SettingsPanel(
                    title: l10n.setPanelBackupReset,
                    child: Column(
                      children: [
                        _DataActionTileAsync(
                          icon: AppIcon.share.resolve(context),
                          label: l10n.setActionExportStats,
                          onTap: (final tileContext) async {
                            final origin = sharePositionOrigin(tileContext);
                            final stats = await ref.read(
                              statsBundleProvider.future,
                            );
                            final summary =
                                StatsExportService.generateTextSummary(stats);
                            await NativeShareSheet.shareText(
                              text: summary,
                              sharePositionOrigin: origin,
                            );
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DataActionTileAsync(
                          icon: AppIcon.download.resolve(context),
                          label: l10n.setActionExportJson,
                          onTap: (final tileContext) async {
                            final origin = sharePositionOrigin(tileContext);
                            final db = ref.read(databaseProvider);
                            final prefs = ref.read(sharedPreferencesProvider);
                            final result =
                                await StatsExportService.generateJsonExport(
                                  db,
                                  prefs,
                                );
                            final dir =
                                await AppStoragePaths.documentsDirectory();
                            final exportsDir = Directory(
                              p.join(dir.path, 'Exports'),
                            );
                            if (!await exportsDir.exists())
                              await exportsDir.create(recursive: true);
                            final file = File(
                              p.join(
                                exportsDir.path,
                                StatsExportService.exportFilename,
                              ),
                            );
                            await file.writeAsString(result.json, flush: true);
                            await NativeShareSheet.shareFiles(
                              filePaths: [file.path],
                              sharePositionOrigin: origin,
                            );
                            return l10n.setExportedRecords(result.totalRecords);
                          },
                          showResultSnackBar: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DataActionTileAsync(
                          icon: AppIcon.upload.resolve(context),
                          label: l10n.setActionImportJson,
                          onTap: (_) async {
                            await _showImportFlow(context, ref);
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ActionTile(
                          icon: AppIcon.restore.resolve(context),
                          label: l10n.setActionRecentlyDeleted(
                            archivedMoveCount,
                          ),
                          onTap: () =>
                              context.push('/settings-panel/recently-deleted'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ActionTile(
                          icon: AppIcon.menu.resolve(context),
                          label: l10n.setActionSystemStatus,
                          onTap: () =>
                              context.push('/settings-panel/system-status'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Dev-only sync-cutover panel (task 2.2). Flag OFF ⇒ this
                        // tile is never built, so it tree-shakes away and release
                        // builds stay byte-identical (design D2). Pushed via a
                        // MaterialPageRoute so no app router config is touched.
                        if (kDevSyncPanelEnabled) ...[
                          ActionTile(
                            icon: AppIcon.sync.resolve(context),
                            label: 'Sync cutover (dev)',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SyncCutoverPanel(),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        ActionTile(
                          icon: AppIcon.delete.resolve(context),
                          label: l10n.setActionClearData,
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
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (final ctx) => StatefulBuilder(
        builder: (final ctx, final setDialogState) {
          final controller = TextEditingController();
          var canConfirm = false;
          return AlertDialog(
            title: Text(l10n.setClearTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.setClearBody),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.setClearConfirmPrompt,
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
                child: Text(l10n.setCancel),
              ),
              TextButton(
                onPressed: canConfirm ? () => Navigator.pop(ctx, true) : null,
                child: Text(
                  l10n.setClearConfirmButton,
                  style: const TextStyle(color: AppColors.actionAgain),
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
          p.join(
            exportsDir.path,
            'breakdex_preclear_${DateTime.now().millisecondsSinceEpoch}.json',
          ),
        );
        await backupFile.writeAsString(backup.json, flush: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.setClearBackupSaved(backupFile.path.split('/').last),
              ),
            ),
          );
        }
      } on Object catch (e) {
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

  Future<void> _showImportFlow(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(validation.error ?? l10n.setImportInvalid)),
      );
      return;
    }

    if (!context.mounted) return;

    // Show mode selection dialog
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(l10n.setImportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.setImportSummary(
                validation.moveCount,
                validation.reviewCount,
                validation.comboCount,
                validation.battleResultCount,
                validation.categoryCount > 0
                    ? l10n.setImportSummaryCategories(validation.categoryCount)
                    : '',
              ),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.setImportModeLabel),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.replaceAll),
              child: Text(l10n.setImportModeReplace),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.merge),
              child: Text(l10n.setImportModeMerge),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.setCancel),
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
        builder: (_) => const Center(child: AppLoader()),
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

      final msg = l10n.setImported(
        importResult.totalImported,
        importResult.movesWithMissingVideos.isNotEmpty
            ? l10n.setImportedRelink(importResult.movesWithMissingVideos.length)
            : '',
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on Object catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.setImportFailed('$e'))));
    }
  }

  Future<void> _showCategoryActionsSheet(
    final BuildContext context,
    final WidgetRef ref,
    final Category category, {
    required final int usageCount,
  }) async {
    final l10n = AppLocalizations.of(context);
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
                leading: const AppIconView(AppIcon.edit),
                title: Text(l10n.setCategoryEdit),
                onTap: () =>
                    Navigator.pop(context, _CategorySheetAction.rename),
              ),
              if (!category.isDefault)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIconView(
                    AppIcon.delete,
                    color: AppColors.actionAgain,
                  ),
                  title: Text(
                    l10n.setCategoryDelete,
                    style: const TextStyle(color: AppColors.actionAgain),
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
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (final context) {
        final controller = TextEditingController(text: cat.name);
        Color selectedColor = cat.color;
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
            title: Text(l10n.setRenameCategoryTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.setCategoryNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ColorSettingTile(
                  title: l10n.setCategoryColorTile,
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: l10n.setCategoryColorEditorTitle,
                      subtitle: l10n.setCategoryColorEditorSubtitle,
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
                child: Text(l10n.setCancel),
              ),
              TextButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.setCategoryNameEmpty)),
                    );
                    return;
                  }

                  final exists = ref
                      .read(categoriesProvider)
                      .any(
                        (final item) =>
                            item.name == newName && item.name != cat.name,
                      );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.setCategoryExists(newName))),
                    );
                    return;
                  }

                  ref
                      .read(categoriesProvider.notifier)
                      .renameCategory(cat.name, newName, selectedColor);
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Text(l10n.setSave),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(l10n.setRenamePageTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.setPageTitleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.setCancel),
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
            child: Text(l10n.setSave),
          ),
        ],
      ),
    );
  }

  void _showRenameEntityDialog(
    final BuildContext context,
    final WidgetRef ref, {
    required final EntityNames current,
    required final EntityNameField singularField,
    required final EntityNameField pluralField,
  }) {
    final l10n = AppLocalizations.of(context);
    final singular = TextEditingController(
      text: current.forField(singularField),
    );
    final plural = TextEditingController(text: current.forField(pluralField));
    showDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(l10n.setRenameDataBankTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: singular,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.setSingularLabel,
                hintText: l10n.setSingularHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: plural,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.setPluralLabel,
                hintText: l10n.setPluralHint,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.setDataBankHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.setCancel),
          ),
          TextButton(
            onPressed: () async {
              final notifier = ref.read(entityNamesProvider.notifier);
              await notifier.rename(singularField, singular.text);
              await notifier.rename(pluralField, plural.text);
              await HapticFeedback.mediumImpact();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.setSave),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(
          l10n.setRenameStateTitle(defaultLearningStateLabels[state]!),
        ),
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
            child: Text(l10n.setCancel),
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
            child: Text(l10n.setSave),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (final context) {
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
            title: Text(l10n.setNewCategoryTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.setCategoryNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ColorSettingTile(
                  title: l10n.setCategoryColorTile,
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: l10n.setCategoryColorEditorTitle,
                      subtitle: l10n.setCategoryColorEditorSubtitle,
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
                child: Text(l10n.setCancel),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.setCategoryNameEmpty)),
                    );
                    return;
                  }

                  final exists = ref
                      .read(categoriesProvider)
                      .any((final item) => item.name == name);
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.setCategoryExists(name))),
                    );
                    return;
                  }

                  ref
                      .read(categoriesProvider.notifier)
                      .addCategory(name, selectedColor);
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Text(l10n.setAdd),
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
    final l10n = AppLocalizations.of(context);
    if (usageCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (final ctx) => AlertDialog(
          title: Text(l10n.setCategoryInUseTitle),
          content: Text(l10n.setCategoryInUseBody(usageCount, category.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.setOk),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }
}

/// Live preview of how the color-carried signals (learning states + review
/// ratings) render under the currently-selected accessible palette. Because
/// the palette rebuilds the whole app theme, these widgets recolor in place as
/// soon as a new palette is chosen — no restart, no navigation.
class _AccessiblePalettePreview extends StatelessWidget {
  const _AccessiblePalettePreview();

  @override
  Widget build(final BuildContext context) {
    final semantic = AppSemanticTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final state in LearningState.values) StatePill(state: state),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final rating in ReviewRating.values)
              _RatingPreviewChip(
                icon: RatingButtonRow.iconForRating(rating),
                label: rating.displayText,
                color: semantic.colorForRating(rating),
              ),
          ],
        ),
      ],
    );
  }
}

class _RatingPreviewChip extends StatelessWidget {
  const _RatingPreviewChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final AppIcon icon;
  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconView(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final meta = [
      if (isDefault) l10n.setCategoryDefault,
      usageCount == 0
          ? l10n.setCategoryUnused
          : l10n.setCategoryMoveCount(usageCount),
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
      trailing: AppIconView(
        AppIcon.forward,
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
  const _SettingsSubPanel({
    required this.title,
    required this.child,
    this.action,
  });

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
            ?action,
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
    final l10n = AppLocalizations.of(context);
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
              } on Object catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.setError('$e'))),
                  );
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
              const SizedBox(width: 18, height: 18, child: AppLoader(size: 6))
            else
              AppIconView(
                AppIcon.forward,
                color: colorScheme.secondary,
                size: 20,
              ),
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
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(photoLibraryAccessStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsPanel(
      title: l10n.setPanelPhotoLibrary,
      child: status.when(
        data: (final access) => SettingsListGroup(
          children: [
            SettingsListRow(
              title: _statusDisplayName(l10n, access),
              subtitle: _statusDescription(l10n, access),
              leading: AppIconView(
                _statusIcon(access),
                size: 20,
                color: access == PhotoLibraryAccessStatus.authorized
                    ? AppColors.actionGood
                    : colorScheme.secondary,
              ),
              onTap:
                  access == PhotoLibraryAccessStatus.denied ||
                      access == PhotoLibraryAccessStatus.restricted
                  ? () => NativeVideoAlbum().openSettings()
                  : access == PhotoLibraryAccessStatus.notDetermined
                  ? () => ref.invalidate(photoLibraryAccessStatusProvider)
                  : null,
              trailing:
                  access == PhotoLibraryAccessStatus.denied ||
                      access == PhotoLibraryAccessStatus.restricted
                  ? AppIconView(
                      AppIcon.share,
                      size: 16,
                      color: colorScheme.secondary,
                    )
                  : null,
            ),
          ],
        ),
        loading: () => SettingsListGroup(
          children: [
            SettingsListRow(
              title: l10n.setPanelPhotoLibrary,
              subtitle: l10n.setPhotoChecking,
              leading: const SizedBox(
                width: 20,
                height: 20,
                child: AppLoader(size: 6),
              ),
            ),
          ],
        ),
        error: (_, _) => SettingsListGroup(
          children: [
            SettingsListRow(
              title: l10n.setPanelPhotoLibrary,
              subtitle: l10n.setPhotoUnableCheck,
              leading: const AppIconView(AppIcon.error, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusDisplayName(
    final AppLocalizations l10n,
    final PhotoLibraryAccessStatus status,
  ) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined =>
        l10n.setPhotoStatusNotDetermined,
      PhotoLibraryAccessStatus.restricted => l10n.setPhotoStatusRestricted,
      PhotoLibraryAccessStatus.denied => l10n.setPhotoStatusDenied,
      PhotoLibraryAccessStatus.authorized => l10n.setPhotoStatusFullAccess,
      PhotoLibraryAccessStatus.limited => l10n.setPhotoStatusLimited,
      PhotoLibraryAccessStatus.unknown => l10n.setPhotoStatusUnknown,
    };
  }

  static String _statusDescription(
    final AppLocalizations l10n,
    final PhotoLibraryAccessStatus status,
  ) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined => l10n.setPhotoDescNotDetermined,
      PhotoLibraryAccessStatus.restricted => l10n.setPhotoDescOpenSettings,
      PhotoLibraryAccessStatus.denied => l10n.setPhotoDescOpenSettings,
      PhotoLibraryAccessStatus.authorized => l10n.setPhotoDescAuthorized,
      PhotoLibraryAccessStatus.limited => l10n.setPhotoDescLimited,
      PhotoLibraryAccessStatus.unknown => l10n.setPhotoDescUnknown,
    };
  }

  static AppIcon _statusIcon(final PhotoLibraryAccessStatus status) {
    return switch (status) {
      PhotoLibraryAccessStatus.notDetermined => AppIcon.help,
      PhotoLibraryAccessStatus.restricted => AppIcon.warning,
      PhotoLibraryAccessStatus.denied => AppIcon.close,
      PhotoLibraryAccessStatus.authorized => AppIcon.check,
      PhotoLibraryAccessStatus.limited => AppIcon.photo,
      PhotoLibraryAccessStatus.unknown => AppIcon.error,
    };
  }
}

class _PartyCycleDurationSlider extends ConsumerWidget {
  static const _minMs = 1000;
  static const _maxMs = 15000;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final durationMs = ref.watch(partyCycleDurationMsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setShakeCycleDuration,
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
                l10n.setSecondsSuffix((durationMs / 1000).toStringAsFixed(1)),
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
              l10n.setSecondsSuffix((_minMs / 1000).toStringAsFixed(1)),
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            Text(
              l10n.setSecondsSuffix((_maxMs / 1000).toStringAsFixed(1)),
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setComboModeTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setComboModeDesc,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setSimplifiedEditorTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setSimplifiedEditorDesc,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setFsrsTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnabled ? l10n.setFsrsEnabledDesc : l10n.setFsrsDisabledDesc,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setShakeDiscoverTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setShakeDiscoverDesc,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setQuietModeTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setQuietModeDesc,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.setStatsTabTitle,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.setStatsTabDesc,
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // The row's label is inert — only the switch toggles — so automation
        // needs a handle on the control itself (task 6.3).
        Semantics(
          identifier: 'stats-tab-switch',
          child: Switch(
            value: isEnabled,
            activeThumbColor: colorScheme.primary,
            onChanged: (_) {
              ref.read(showStatsTabProvider.notifier).toggle();
            },
          ),
        ),
      ],
    );
  }
}
