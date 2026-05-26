import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/move_creation.dart';
import '../../core/providers.dart';
import '../../core/state_machines/move_creation/machine.dart';
import '../../core/state_machines/move_creation/provider.dart';
import '../../core/services/categories_service.dart';
import '../../shared/widgets/video_picker_sheet.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChoiceCard(
                icon: Icons.video_call_rounded,
                title: 'Create Move',
                subtitle: 'Import a video clip, set its count, and add it to your library',
                onTap: () => _startClipFlow(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceCard(
                icon: Icons.linear_scale_rounded,
                title: 'Create Combo',
                subtitle: 'Build a sequence of moves with a visual beat grid to see your composition',
                onTap: () => context.push<String>('/create-combo'),
              ),
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

    final notifier = ref.read(moveCreationStateProvider.notifier);
    notifier.start(
      CreateMoveRequest(
        name: metadata.name,
        category: metadata.category,
        localVideoPath: pickResult.localPath,
        count: metadata.count,
        learningState: metadata.learningState.name,
      ),
    );

    // Listen for completion to show snackbar
    ref.listenManual(moveCreationStateProvider, (previous, next) {
      if (next is Success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "${next.result.name}"')),
        );
      } else if (next is Error && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${next.message}')),
        );
      }
    });
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataResult {
  final String name;
  final String category;
  final int count;
  final LearningState learningState;
  const _MetadataResult({
    required this.name,
    required this.category,
    required this.count,
    required this.learningState,
  });
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
  int _count = 4;
  LearningState _selectedState = LearningState.newState;

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
      _MetadataResult(
        name: normalized,
        category: _selectedCategory!,
        count: _count,
        learningState: _selectedState,
      ),
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
            Text('NAME', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: AppTypography.titleLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Windmill',
                errorText: _errorText,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('CATEGORY', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == cat.name ? colorScheme.primary : colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: _selectedCategory == cat.name ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(cat.name, style: AppTypography.caption.copyWith(
                        color: _selectedCategory == cat.name ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('KNOWLEDGE STATE', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: LearningState.values.map((state) {
                final selected = _selectedState == state;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedState = state);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? colorScheme.primary : colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(state.displayText, style: AppTypography.caption.copyWith(
                        color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('BEATS', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _CountButton(
                  icon: Icons.remove_rounded,
                  onTap: _count > 1 ? () => setState(() => _count--) : null,
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  '$_count',
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                _CountButton(
                  icon: Icons.add_rounded,
                  onTap: _count < 16 ? () => setState(() => _count++) : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nameEmpty || selectedCategory == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.onSurface,
                  foregroundColor: colorScheme.surface,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                  disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                child: const Text('SAVE MOVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: enabled ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: enabled ? colorScheme.outline.withValues(alpha: 0.4) : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 20, color: enabled ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3)),
      ),
    );
  }
}
