// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/color_setting_tile.dart';
import 'package:breakdex/features/flashcard_review/widgets/state_picker_sheet.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/core/design/icons.dart';

class StatePickerOverlay extends StatelessWidget {
  const StatePickerOverlay({
    super.key,
    required this.currentState,
    required this.moveName,
    required this.onCancel,
    required this.onSave,
  });

  final LearningState currentState;
  final String moveName;
  final VoidCallback onCancel;
  final ValueChanged<LearningState> onSave;

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatePickerSheet(
                currentState: currentState,
                moveName: moveName,
                onSelected: onSave,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: onCancel, child: Text(l10n.mdCancel)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryPickerOverlay extends ConsumerWidget {
  const CategoryPickerOverlay({
    super.key,
    required this.currentCategory,
    required this.onCancel,
    required this.onSave,
  });

  final String currentCategory;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final entityNames = ref.watch(entityNamesProvider);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 340,
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.mdMoveCategoryTitle(entityNames.moveSingular),
                style: AppTypography.titleSmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (categories.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final category in categories)
                      _EditableCategoryChip(
                        label: category.name,
                        color: category.color,
                        selected: category.name == currentCategory,
                        onTap: () => onSave(category.name),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final created = await _showAddCategoryDialog(
                        context,
                        ref,
                      );
                      if (created != null) onSave(created);
                    },
                    icon: const AppIconView(AppIcon.add, size: 18),
                    label: Text(l10n.mdAddNew),
                  ),
                  TextButton(onPressed: onCancel, child: Text(l10n.mdCancel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showAddCategoryDialog(
    final BuildContext context,
    final WidgetRef ref,
  ) {
    return showDialog<String>(
      context: context,
      builder: (final context) {
        final l10n = AppLocalizations.of(context);
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        String? errorText;
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
            title: Text(l10n.mdNewCategoryTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.mdCategoryNameHint,
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ColorSettingTile(
                  title: l10n.mdCategoryColorTile,
                  subtitle: formatColorHex(selectedColor),
                  color: selectedColor,
                  onTap: () async {
                    final nextColor = await showColorEditorDialog(
                      context,
                      initialColor: selectedColor,
                      title: l10n.mdCategoryColorDialogTitle,
                      subtitle: l10n.mdCategoryColorDialogSubtitle,
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
                child: Text(l10n.mdCancel),
              ),
              TextButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => errorText = l10n.mdCategoryNameEmpty);
                    return;
                  }
                  final exists = ref
                      .read(categoriesProvider)
                      .any((final item) => item.name == name);
                  if (exists) {
                    setDialogState(() => errorText = l10n.nameTakenError(name));
                    unawaited(HapticFeedback.heavyImpact());
                    return;
                  }

                  await ref
                      .read(categoriesProvider.notifier)
                      .addCategory(name, selectedColor);
                  if (!context.mounted) return;
                  unawaited(HapticFeedback.mediumImpact());
                  Navigator.pop(context, name);
                },
                child: Text(l10n.mdAdd),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CountEditorOverlay extends StatefulWidget {
  const CountEditorOverlay({
    super.key,
    required this.initialCount,
    required this.onCancel,
    required this.onSave,
  });

  final int initialCount;
  final VoidCallback onCancel;
  final ValueChanged<int> onSave;

  @override
  State<CountEditorOverlay> createState() => _CountEditorOverlayState();
}

class _CountEditorOverlayState extends State<CountEditorOverlay> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.mdUpdateCountTitle, style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CountButton(
                    icon: AppIcon.remove.resolve(context),
                    onPressed: () =>
                        setState(() => _count = (_count - 1).clamp(0, 9999)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    '$_count',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _CountButton(
                    icon: AppIcon.add.resolve(context),
                    onPressed: () =>
                        setState(() => _count = (_count + 1).clamp(0, 9999)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(l10n.mdCancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => widget.onSave(_count),
                    child: Text(l10n.mdSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmActionOverlay extends StatelessWidget {
  const ConfirmActionOverlay({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                content,
                style: AppTypography.bodyMedium.copyWith(color: cs.secondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancel, child: Text(l10n.mdCancel)),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: onConfirm,
                    style: isDestructive
                        ? FilledButton.styleFrom(
                            backgroundColor: AppColors.actionAgain,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenameOverlay extends ConsumerStatefulWidget {
  const RenameOverlay({
    super.key,
    required this.draftName,
    required this.onDraftChanged,
    required this.onCancel,
    required this.onSave,
    this.isConflict = false,
    this.conflictName,
  });

  final String draftName;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;
  final bool isConflict;
  final String? conflictName;

  @override
  ConsumerState<RenameOverlay> createState() => _RenameOverlayState();
}

class _RenameOverlayState extends ConsumerState<RenameOverlay> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draftName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final entityNames = ref.watch(entityNamesProvider);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isConflict
                    ? l10n.mdNameConflictTitle
                    : l10n.mdRenameEntity(entityNames.moveSingular),
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.isConflict)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.mdNameConflictBody(
                      widget.conflictName ?? '',
                      entityNames.moveSingular.toLowerCase(),
                      entityNames.comboSingular.toLowerCase(),
                    ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.actionAgain,
                    ),
                  ),
                ),
              TextField(
                controller: _controller,
                autofocus: true,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(hintText: l10n.mdRenameHint),
                onChanged: widget.onDraftChanged,
                onSubmitted: (final val) {
                  if (val.trim().isNotEmpty) widget.onSave(val.trim());
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(l10n.mdCancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {
                      final val = _controller.text.trim();
                      if (val.isNotEmpty) widget.onSave(val);
                    },
                    child: Text(l10n.mdSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavingOverlay extends StatelessWidget {
  const SavingOverlay({super.key, required this.message});
  final String message;

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              const SizedBox(height: AppSpacing.lg),
              Text(message, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableCategoryChip extends StatelessWidget {
  const _EditableCategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Colors.white : color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(icon),
      padding: const EdgeInsets.all(12),
    );
  }
}
