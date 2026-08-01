import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/features/flow/providers/aura_providers.dart';
import 'package:breakdex/shared/widgets/app_sheet.dart';

// ---------------------------------------------------------------------------
// AuraPresetPicker — horizontal scroll of preset "team" chips.
// ---------------------------------------------------------------------------

/// Horizontal scrolling row of aura preset chips, inspired by Pokemon team
/// selection.
///
/// - **Tap** a chip to switch the active preset.
/// - **Long press** to rename or delete the preset via a bottom sheet.
/// - **"+"** chip at the end creates a new preset via name input sheet.
///
/// The active preset chip gets a filled primary background, while inactive
/// chips use a muted surface treatment — matching the `_TypeChip` pattern
/// from [LabScreen].
class AuraPresetPicker extends ConsumerWidget {
  const AuraPresetPicker({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final presetsAsync = ref.watch(auraPresetsProvider);
    final activeAsync = ref.watch(activeAuraProvider);

    return presetsAsync.when(
      loading: () => const SizedBox(height: 36),
      error: (_, _) => const SizedBox(height: 36),
      data: (final presets) {
        final activeId = activeAsync.valueOrNull?.id;

        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            itemCount: presets.length + 1, // +1 for the "+" button
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (final context, final index) {
              // Last item = "add new preset" chip.
              if (index == presets.length) {
                return _AddPresetChip(
                  onTap: () => _showCreatePresetSheet(context, ref),
                );
              }

              final preset = presets[index];
              final isActive = preset.id == activeId;

              return _PresetChip(
                label: preset.name,
                isActive: isActive,
                onTap: () => _activatePreset(ref, preset.id),
                onLongPress: () =>
                    _showPresetOptionsSheet(context, ref, preset),
              );
            },
          ),
        );
      },
    );
  }

  /// Switch the active preset — single tap, no confirmation.
  Future<void> _activatePreset(
    final WidgetRef ref,
    final String presetId,
  ) async {
    unawaited(HapticFeedback.selectionClick());
    await ref.read(auraDaoProvider).setActivePreset(presetId);
  }

  /// Bottom sheet for creating a new preset with a name input.
  Future<void> _showCreatePresetSheet(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final name = await showAppSheet<String>(
      context: context,
      builder: (_) => const _PresetNameSheet(title: 'New Aura Preset'),
    );

    if (name == null || name.trim().isEmpty) return;

    final dao = ref.read(auraDaoProvider);
    final id = const Uuid().v4();
    await dao.insertPreset(
      AuraPresetsCompanion.insert(id: id, name: name.trim()),
    );
    // Auto-activate the newly created preset.
    await dao.setActivePreset(id);
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Bottom sheet with rename/delete options for an existing preset.
  Future<void> _showPresetOptionsSheet(
    final BuildContext context,
    final WidgetRef ref,
    final AuraPreset preset,
  ) async {
    unawaited(HapticFeedback.lightImpact());

    final action = await showAppSheet<_PresetAction>(
      context: context,
      builder: (final ctx) => _PresetOptionsSheet(presetName: preset.name),
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case _PresetAction.rename:
        final newName = await showAppSheet<String>(
          context: context,
          builder: (_) => _PresetNameSheet(
            title: 'Rename Preset',
            initialValue: preset.name,
          ),
        );
        if (newName != null && newName.trim().isNotEmpty) {
          // Update preset name directly via the database.
          final db = ref.read(databaseProvider);
          await (db.update(db.auraPresets)
                ..where((final t) => t.id.equals(preset.id)))
              .write(AuraPresetsCompanion(name: Value(newName.trim())));
        }

      case _PresetAction.delete:
        // Delete the preset. The links remain — they are not preset-scoped
        // in this schema version. Presets are organizational labels only.
        final db = ref.read(databaseProvider);
        await (db.delete(
          db.auraPresets,
        )..where((final t) => t.id.equals(preset.id))).go();
        unawaited(HapticFeedback.mediumImpact());
    }
  }
}

// ---------------------------------------------------------------------------
// Chip widgets
// ---------------------------------------------------------------------------

/// A single preset chip. Filled when active, outlined when inactive.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.moderate01,
        curve: AppMotion.productive,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// The "+" chip for adding a new preset.
class _AddPresetChip extends StatelessWidget {
  const _AddPresetChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconView(AppIcon.add, size: 16, color: colorScheme.secondary),
            const SizedBox(width: 4),
            Text(
              'New',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheets
// ---------------------------------------------------------------------------

enum _PresetAction { rename, delete }

/// Bottom sheet presenting rename/delete actions for a preset.
class _PresetOptionsSheet extends StatelessWidget {
  const _PresetOptionsSheet({required this.presetName});

  final String presetName;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.lg,
          AppSpacing.screenEdge,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              presetName,
              style: AppTypography.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: AppIconView(AppIcon.edit, color: colorScheme.onSurface),
              title: Text('Rename', style: AppTypography.bodyMedium),
              onTap: () => Navigator.pop(context, _PresetAction.rename),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const AppIconView(
                AppIcon.delete,
                color: Color(0xFFC23B2A),
              ),
              title: Text(
                'Delete',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFFC23B2A),
                ),
              ),
              onTap: () => Navigator.pop(context, _PresetAction.delete),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with a text field for naming/renaming a preset.
class _PresetNameSheet extends StatefulWidget {
  const _PresetNameSheet({required this.title, this.initialValue});

  final String title;
  final String? initialValue;

  @override
  State<_PresetNameSheet> createState() => _PresetNameSheetState();
}

class _PresetNameSheetState extends State<_PresetNameSheet> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _isEmpty = _controller.text.trim().isEmpty;
    _controller.addListener(() {
      final empty = _controller.text.trim().isEmpty;
      if (empty != _isEmpty) setState(() => _isEmpty = empty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isEmpty) return;
    Navigator.pop(context, _controller.text.trim());
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.lg,
        AppSpacing.screenEdge,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Preset name',
            textField: true,
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., Power Style, Footwork Flow...',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isEmpty ? null : _submit,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
