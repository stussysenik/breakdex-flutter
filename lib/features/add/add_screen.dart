import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/app_mode.dart';
import '../../core/models/move_creation.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../../shared/widgets/settings_gear_button.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isParty = appMode == AppMode.party;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Move'),
        actions: const [SettingsGearButton(), SizedBox(width: AppSpacing.sm)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_call_rounded,
                size: isParty ? 64 : 56,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _startClipFlow(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Select a Clip'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
              if (!isParty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Import a video clip to create a new move',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startClipFlow(BuildContext context, WidgetRef ref) async {
    final pickResult = await VideoPickerSheet.show(context);
    if (pickResult == null || !context.mounted) return;

    final metadata = await _showMetadataSheet(context, ref);
    if (metadata == null || !context.mounted) return;

    try {
      final creationService = ref.read(moveCreationServiceProvider);
      final result = await creationService.createMove(
        CreateMoveRequest(
          name: metadata.name,
          category: metadata.category,
          localVideoPath: pickResult.localPath,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "${result.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<_MetadataResult?> _showMetadataSheet(
    BuildContext context,
    WidgetRef ref,
  ) {
    return showModalBottomSheet<_MetadataResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => _ClipMetadataForm(),
    );
  }
}

class _MetadataResult {
  final String name;
  final String category;
  const _MetadataResult({required this.name, required this.category});
}

class _ClipMetadataForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClipMetadataForm> createState() => _ClipMetadataFormState();
}

class _ClipMetadataFormState extends ConsumerState<_ClipMetadataForm> {
  final _nameController = TextEditingController();
  String? _selectedCategory;
  String? _errorText;
  bool _nameEmpty = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final empty = _nameController.text.trim().isEmpty;
    if (empty != _nameEmpty || _errorText != null) {
      setState(() {
        _nameEmpty = empty;
        _errorText = null;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCategory == null) return;

    final naming = ref.read(reviewableNamingServiceProvider);
    final normalized = naming.normalize(name);
    final isTaken = await naming.isNameTaken(normalized);
    if (!mounted) return;

    if (isTaken) {
      setState(() => _errorText = '"$normalized" already exists.');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    Navigator.pop(
      context,
      _MetadataResult(name: normalized, category: _selectedCategory!),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final selectedCategory = categories.any((cat) => cat.name == _selectedCategory)
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first.name : null);

    if (selectedCategory != _selectedCategory && selectedCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategory = selectedCategory);
      });
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.xl,
          AppSpacing.screenEdge,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Name Your Move', style: AppTypography.titleMedium.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Move name',
                errorText: _errorText,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Category', style: AppTypography.caption.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final cat in categories)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat.name);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategory == cat.name ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _selectedCategory == cat.name ? Colors.white : cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(cat.name, style: AppTypography.caption.copyWith(
                            color: _selectedCategory == cat.name ? Colors.white : colorScheme.onSurface,
                          )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nameEmpty || selectedCategory == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: const Text('Create Move'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
