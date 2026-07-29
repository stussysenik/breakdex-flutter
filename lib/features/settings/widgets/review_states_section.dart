import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/color_setting_tile.dart';
import 'package:breakdex/shared/widgets/settings_list_group.dart';

const reviewStatePresetColors = [
  Color(0xFFC46F6F),
  Color(0xFFC4A84F),
  Color(0xFF9F8B5E),
  Color(0xFF6FAF6F),
  Color(0xFF5F9F8F),
  Color(0xFF6F90C4),
  Color(0xFF7C7FC2),
  Color(0xFF8E97A1),
  Color(0xFF756C63),
  Color(0xFF56616D),
];

class ReviewStatesSection extends ConsumerWidget {
  const ReviewStatesSection({super.key, required this.onRename});

  final void Function(LearningState state, String currentLabel) onRename;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final labels = ref.watch(learningStateLabelsProvider);
    final colors = ref.watch(learningStateColorsProvider);
    final mode = ref.watch(learningModeProvider);
    final customStates = ref.watch(customLearningStatesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Learning mode toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ref
                      .read(learningModeProvider.notifier)
                      .set(LearningMode.defaultMode),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l10n.setStatesModeDefault,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: mode == LearningMode.defaultMode
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        fontWeight: mode == LearningMode.defaultMode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ref
                      .read(learningModeProvider.notifier)
                      .set(LearningMode.custom),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l10n.setStatesModeCustom,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: mode == LearningMode.custom
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        fontWeight: mode == LearningMode.custom
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsListGroup(
          children: [
            for (final state in LearningState.values)
              SettingsListRow(
                onTap: () =>
                    onRename(state, resolveLearningStateLabel(labels, state)),
                leading: _StateSwatch(color: colors.forState(state)),
                title: resolveLearningStateLabel(labels, state),
                subtitle: _subtitleFor(l10n, labels, state),
                trailing: _StateRowTrailing(
                  hex: formatColorHex(colors.forState(state)),
                  onColorTap: () => _showColorPicker(context, ref, state),
                ),
              ),
            if (mode == LearningMode.custom) ...[
              for (final custom in customStates)
                SettingsListRow(
                  onTap: () => _editCustomState(context, ref, custom),
                  leading: _StateSwatch(color: custom.color),
                  title: custom.label,
                  subtitle: l10n.setStatesCustomStateSubtitle,
                  trailing: GestureDetector(
                    onTap: () => ref
                        .read(customLearningStatesProvider.notifier)
                        .remove(custom.id),
                    child: AppIconView(
                      AppIcon.close,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              SettingsListRow(
                onTap: () => _addCustomState(context, ref),
                leading: AppIconView(
                  AppIcon.add,
                  size: 18,
                  color: colorScheme.primary,
                ),
                title: l10n.setStatesAddTitle,
                subtitle: l10n.setStatesAddSubtitle,
              ),
            ],
          ],
        ),
      ],
    );
  }

  String? _subtitleFor(
    final AppLocalizations l10n,
    final Map<LearningState, String> labels,
    final LearningState state,
  ) {
    final current = resolveLearningStateLabel(labels, state);
    final original = defaultLearningStateLabels[state] ?? state.displayText;
    if (current == original) return null;
    return l10n.setStatesDefaultLabel(original);
  }

  Future<void> _showColorPicker(
    final BuildContext context,
    final WidgetRef ref,
    final LearningState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = resolveLearningStateLabel(
      ref.read(learningStateLabelsProvider),
      state,
    );
    final currentColor = ref.read(learningStateColorsProvider).forState(state);
    final selected = await showColorEditorDialog(
      context,
      initialColor: currentColor,
      title: l10n.setStatesColorTitle(label),
      subtitle: l10n.setStatesColorSubtitle(label),
      presets: reviewStatePresetColors,
    );
    if (selected == null) return;
    await HapticFeedback.mediumImpact();
    await ref
        .read(learningStateColorsProvider.notifier)
        .setColor(state, selected);
  }

  Future<void> _addCustomState(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    Color selectedColor = reviewStatePresetColors[0];
    final result = await showDialog<CustomLearningState>(
      context: context,
      builder: (final ctx) => StatefulBuilder(
        builder: (final ctx, final setDialogState) => AlertDialog(
          title: Text(l10n.setStatesNewTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.setStatesNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ColorSettingTile(
                title: l10n.setStatesColorTileTitle,
                subtitle: formatColorHex(selectedColor),
                color: selectedColor,
                onTap: () async {
                  final nextColor = await showColorEditorDialog(
                    ctx,
                    initialColor: selectedColor,
                    title: l10n.setStatesCustomColorTitle,
                    subtitle: l10n.setStatesCustomColorSubtitle,
                    presets: reviewStatePresetColors,
                  );
                  if (nextColor != null) {
                    setDialogState(() => selectedColor = nextColor);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.setStatesCancel),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final id = const Uuid().v4();
                final custom = CustomLearningState(
                  id: id,
                  label: name,
                  dbValue: 'custom_$id',
                  color: selectedColor,
                );
                Navigator.pop(ctx, custom);
              },
              child: Text(l10n.setStatesAdd),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await ref.read(customLearningStatesProvider.notifier).add(result);
  }

  Future<void> _editCustomState(
    final BuildContext context,
    final WidgetRef ref,
    final CustomLearningState custom,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: custom.label);
    Color selectedColor = custom.color;
    final result = await showDialog<CustomLearningState>(
      context: context,
      builder: (final ctx) => StatefulBuilder(
        builder: (final ctx, final setDialogState) => AlertDialog(
          title: Text(l10n.setStatesEditTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.setStatesNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ColorSettingTile(
                title: l10n.setStatesColorTileTitle,
                subtitle: formatColorHex(selectedColor),
                color: selectedColor,
                onTap: () async {
                  final nextColor = await showColorEditorDialog(
                    ctx,
                    initialColor: selectedColor,
                    title: l10n.setStatesCustomColorTitle,
                    subtitle: l10n.setStatesCustomColorSubtitle,
                    presets: reviewStatePresetColors,
                  );
                  if (nextColor != null) {
                    setDialogState(() => selectedColor = nextColor);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.setStatesCancel),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  ctx,
                  CustomLearningState(
                    id: custom.id,
                    label: name,
                    dbValue: custom.dbValue,
                    color: selectedColor,
                  ),
                );
              },
              child: Text(l10n.setStatesSave),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(customLearningStatesProvider.notifier)
        .update(custom.id, result);
  }
}

class _StateSwatch extends StatelessWidget {
  const _StateSwatch({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
    );
  }
}

class _StateRowTrailing extends StatelessWidget {
  const _StateRowTrailing({required this.hex, required this.onColorTap});

  final String hex;
  final VoidCallback onColorTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hex,
          style: AppTypography.caption.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onColorTap,
          behavior: HitTestBehavior.opaque,
          child: AppIconView(
            AppIcon.edit,
            size: 18,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
