import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/learning_state.dart';
import '../../../core/services/categories_service.dart';
import '../../../shared/widgets/color_setting_tile.dart';
import '../../flashcard_review/widgets/state_picker_sheet.dart';

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
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
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
                'Move Category',
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
                      final created = await _showAddCategoryDialog(context, ref);
                      if (created != null) onSave(created);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                  ),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showAddCategoryDialog(final BuildContext context, final WidgetRef ref) {
    return showDialog<String>(
      context: context,
      builder: (final context) {
        final controller = TextEditingController();
        Color selectedColor = categoryPresetColors[0];
        String? errorText;
        return StatefulBuilder(
          builder: (final context, final setDialogState) => AlertDialog(
            title: const Text('New Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Category name',
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
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setDialogState(
                      () => errorText = 'Category name cannot be empty.',
                    );
                    return;
                  }
                  final exists = ref
                      .read(categoriesProvider)
                      .any((final item) => item.name == name);
                  if (exists) {
                    setDialogState(() => errorText = '"$name" already exists.');
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
                child: const Text('Add'),
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
              Text('Update Count', style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CountButton(
                    icon: Icons.remove,
                    onPressed: () => setState(() => _count = (_count - 1).clamp(0, 9999)),
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
                    icon: Icons.add,
                    onPressed: () => setState(() => _count = (_count + 1).clamp(0, 9999)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => widget.onSave(_count),
                    child: const Text('Save'),
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
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
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

class RenameOverlay extends StatefulWidget {
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
  State<RenameOverlay> createState() => _RenameOverlayState();
}

class _RenameOverlayState extends State<RenameOverlay> {
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
                widget.isConflict ? 'Name Conflict' : 'Rename Move',
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.isConflict)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'The name "${widget.conflictName}" is already taken by another move or combo.',
                    style: AppTypography.caption.copyWith(color: AppColors.actionAgain),
                  ),
                ),
              TextField(
                controller: _controller,
                autofocus: true,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Enter new name',
                ),
                onChanged: widget.onDraftChanged,
                onSubmitted: (final val) {
                  if (val.trim().isNotEmpty) widget.onSave(val.trim());
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {
                      final val = _controller.text.trim();
                      if (val.isNotEmpty) widget.onSave(val);
                    },
                    child: const Text('Save'),
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
              const CircularProgressIndicator(),
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
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
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
