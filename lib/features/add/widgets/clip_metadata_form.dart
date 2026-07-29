import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';

/// The authored metadata for one clip. `AddScreen` turns it into a
/// `CreateMoveRequest`; the form itself writes no records.
class ClipMetadataResult {
  ClipMetadataResult({
    required this.name,
    required this.category,
    required this.count,
    required this.learningState,
  });
  final String name;
  final String category;
  final int count;
  final LearningState learningState;
}

/// The move-authoring surface: everything the user fills in for one picked clip
/// before it becomes a move record.
///
/// `AddScreen` presents it as a modal sheet once a clip is picked, but it holds
/// no route or picker dependency — construct it with any [VideoPickResult] to
/// render it in isolation (see `add_screen_previews.dart`). A path that resolves
/// to nothing degrades to the player's status card rather than throwing, which
/// is what makes a stub result safe in a preview.
///
/// Returns a [ClipMetadataResult] through `Navigator.pop`, or null when
/// dismissed.
class ClipMetadataForm extends ConsumerStatefulWidget {
  const ClipMetadataForm({super.key, required this.pickResult});
  final VideoPickResult pickResult;

  @override
  ConsumerState<ClipMetadataForm> createState() => _ClipMetadataFormState();
}

class _ClipMetadataFormState extends ConsumerState<ClipMetadataForm> {
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
    if (widget.pickResult.originalFileName != null) {
      final name = p.basenameWithoutExtension(
        widget.pickResult.originalFileName!,
      );
      _nameController.text = name.replaceAll('_', ' ').replaceAll('-', ' ');
    }
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

    final l10n = AppLocalizations.of(context);
    final naming = ref.read(reviewableNamingServiceProvider);
    final normalized = naming.normalize(name);
    final isTaken = await naming.isNameTaken(normalized);
    if (!mounted) return;

    if (isTaken) {
      setState(() => _errorText = l10n.nameTakenError(normalized));
      unawaited(HapticFeedback.heavyImpact());
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    Navigator.pop(
      context,
      ClipMetadataResult(
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
  Widget build(final BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final entityNames = ref.watch(entityNamesProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final selectedCategory =
        categories.any((final cat) => cat.name == _selectedCategory)
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: RobustVideoPlayer(
                    videoPath: widget.pickResult.localPath,
                    autoPlay: true,
                    looping: true,
                    muted: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                l10n.fieldNameLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: AppTypography.titleLarge,
                decoration: InputDecoration(
                  hintText: l10n.addNameHint,
                  errorText: _errorText,
                  border: InputBorder.none,
                  hintStyle: AppTypography.titleLarge.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.fieldCategoryLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: categories.map((final cat) {
                  final active = cat.name == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat.name.toUpperCase()),
                    selected: active,
                    onSelected: (final val) {
                      if (val) setState(() => _selectedCategory = cat.name);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fieldBeatCountLabel,
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _CountButton(
                              icon: AppIcon.remove.resolve(context),
                              onTap: _count > 1
                                  ? () => setState(() => _count--)
                                  : null,
                            ),
                            SizedBox(
                              width: 48,
                              child: Text(
                                _count.toString(),
                                textAlign: TextAlign.center,
                                style: AppTypography.titleLarge,
                              ),
                            ),
                            _CountButton(
                              icon: AppIcon.add.resolve(context),
                              onTap: _count < 32
                                  ? () => setState(() => _count++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fieldStatusLabel,
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButton<LearningState>(
                          value: _selectedState,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: LearningState.values.map((final s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (final s) =>
                              setState(() => _selectedState = s!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nameEmpty || selectedCategory == null
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: colorScheme.surface,
                    disabledBackgroundColor: colorScheme.onSurface.withValues(
                      alpha: 0.1,
                    ),
                    disabledForegroundColor: colorScheme.onSurface.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(
                    l10n.saveEntityButton(
                      entityNames.moveSingular.toUpperCase(),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: enabled
                ? colorScheme.outline.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
