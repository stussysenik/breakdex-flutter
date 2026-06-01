import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/move_creation.dart';
import '../../core/providers.dart';
import '../../core/state_machines/move_creation/provider.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/video_service.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../../shared/widgets/video_player_widget.dart';

class AddScreen extends ConsumerWidget {
  const AddScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Add Content'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {},
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenEdge),
              child: Column(
                children: [
                  _ChoiceCard(
                    emoji: '🤸',
                    title: 'New Move',
                    subtitle:
                        'Capture or import a single move to track and review',
                    onTap: () => _startClipFlow(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChoiceCard(
                    emoji: '✨',
                    title: 'New Combo',
                    subtitle:
                        'Build a sequence of moves with a visual beat grid to see your composition',
                    onTap: () => context.push<String>('/create-combo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startClipFlow(final BuildContext context, final WidgetRef ref) async {
    final pickResult = await VideoPickerSheet.show(context);
    if (pickResult == null || !context.mounted) return;

    final metadata = await _showMetadataSheet(context, ref, pickResult);
    if (metadata == null || !context.mounted) return;

    final notifier = ref.read(moveCreationStateProvider.notifier);
    notifier.start(
      CreateMoveRequest(
        name: metadata.name,
        category: metadata.category,
        localVideoPath: pickResult.localPath,
        originalVideoName: pickResult.originalFileName,
        videoFileSize: pickResult.fileSize,
        videoCreationDate: pickResult.creationDate,
        count: metadata.count,
        learningState: metadata.learningState.dbValue,
      ),
    );
  }

  Future<_MetadataResult?> _showMetadataSheet(
    final BuildContext context,
    final WidgetRef ref,
    final VideoPickResult pickResult,
  ) {
    return showModalBottomSheet<_MetadataResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => _ClipMetadataForm(pickResult: pickResult),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataResult {
  _MetadataResult({
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

class _ClipMetadataForm extends ConsumerStatefulWidget {
  const _ClipMetadataForm({required this.pickResult});
  final VideoPickResult pickResult;

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
    if (widget.pickResult.originalFileName != null) {
      final name = p.basenameWithoutExtension(widget.pickResult.originalFileName!);
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
  Widget build(final BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final selectedCategory = categories.any((final cat) => cat.name == _selectedCategory)
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
                  width: 36, height: 4,
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

              Text('NAME', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: AppTypography.titleLarge,
                decoration: InputDecoration(
                  hintText: 'e.g. Flare, Windmill...',
                  errorText: _errorText,
                  border: InputBorder.none,
                  hintStyle: AppTypography.titleLarge.copyWith(color: colorScheme.outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('CATEGORY', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
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
                        Text('BEAT COUNT', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _CountButton(
                              icon: Icons.remove,
                              onTap: _count > 1 ? () => setState(() => _count--) : null,
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
                              icon: Icons.add,
                              onTap: _count < 32 ? () => setState(() => _count++) : null,
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
                        Text('STATUS', style: AppTypography.labelLarge.copyWith(color: colorScheme.secondary, letterSpacing: 1.5)),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButton<LearningState>(
                          value: _selectedState,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: LearningState.values.map((final s) {
                            return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                          }).toList(),
                          onChanged: (final s) => setState(() => _selectedState = s!),
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
