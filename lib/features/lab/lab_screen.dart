import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../shared/widgets/app_segmented_control.dart';
import '../../shared/widgets/settings_gear_button.dart';
import 'providers/lab_providers.dart';
import 'widgets/lab_board_view.dart';
import 'widgets/lab_list_view.dart';
import 'widgets/lab_sets_view.dart';

/// The Lab tab — a space for organizing training projects and practice sets.
///
/// Features a quick-log input at the top for capturing ideas on the fly,
/// a list/board view toggle matching the Arsenal tab pattern, and a FAB
/// for creating new labs. The board view provides kanban-style columns
/// for the 4-stage lab progression: Idea -> Attempting -> Landed -> Clean.
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key});

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  final _quickLogController = TextEditingController();

  @override
  void dispose() {
    _quickLogController.dispose();
    super.dispose();
  }

  /// Submit a quick log entry (not tied to any specific lab).
  Future<void> _submitQuickLog() async {
    final content = _quickLogController.text.trim();
    if (content.isEmpty) return;

    final dao = ref.read(labEntriesDaoProvider);
    await dao.insertEntry(
      LabEntriesCompanion.insert(
        id: const Uuid().v4(),
        content: content,
      ),
    );

    _quickLogController.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      unawaited(HapticFeedback.lightImpact());
    }
  }

  /// Show bottom sheet for creating a new lab.
  Future<void> _showCreateLabSheet() async {
    final result = await showModalBottomSheet<({String name, String type})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateLabSheet(),
    );

    if (result == null || !mounted) return;

    final dao = ref.read(labsDaoProvider);
    await dao.insertLab(
      LabsCompanion.insert(
        id: const Uuid().v4(),
        name: result.name,
        labType: Value(result.type),
      ),
    );

    unawaited(HapticFeedback.mediumImpact());
  }

  /// Whether the quick-log input and FAB should be visible for this mode.
  ///
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(labViewModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
                slivers: [
                  // Header: title + segment toggle + quick log
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      viewMode,
                      colorScheme,
                      true,
                    ),
                  ),

                  // Content — switches based on selected mode
                  switch (viewMode) {
                    LabViewMode.projects =>
                      const LabListView(labTypeFilter: 'project'),
                    LabViewMode.board => const LabBoardView(),
                    LabViewMode.sets => const LabSetsView(),
                  },

                  // Bottom padding for frosted nav bar
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight +
                          MediaQuery.of(context).padding.bottom +
                          AppSpacing.lg,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Padding(
              padding: EdgeInsets.only(
                bottom: kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Semantics(
                identifier: 'create-new-lab',
                label: 'Create new lab',
                button: true,
                child: FloatingActionButton(
                  onPressed: _showCreateLabSheet,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: AppMotion.moderate02,
                    curve: AppMotion.expressive,
                  )
                  .fadeIn(duration: AppMotion.moderate01),
            ),
    );
  }

  /// Shared header widget: title + 3-segment toggle + quick log.
  Widget _buildHeader(
    BuildContext context,
    LabViewMode viewMode,
    ColorScheme colorScheme,
    bool showQuickLog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + gear
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lab',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SettingsGearButton(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 5-segment toggle: Projects | Board | Sets | Aura | Calendar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: AppSegmentedControl<LabViewMode>(
            items: const [
              AppSegmentedControlItem(
                value: LabViewMode.projects,
                label: 'Projects',
                icon: Icons.trip_origin,
              ),
              AppSegmentedControlItem(
                value: LabViewMode.board,
                label: 'Board',
                icon: Icons.grid_view_rounded,
              ),
              AppSegmentedControlItem(
                value: LabViewMode.sets,
                label: 'Sets',
                icon: Icons.playlist_play_rounded,
              ),
            ],
            selectedValue: viewMode,
            onChanged: (mode) {
              HapticFeedback.selectionClick();
              ref.read(labViewModeProvider.notifier).state = mode;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quick log input — visible in content creation modes only
        if (showQuickLog) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Quick log',
                    textField: true,
                    child: TextField(
                      controller: _quickLogController,
                      decoration: const InputDecoration(
                        hintText: 'Quick log...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitQuickLog(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  label: 'Submit quick log',
                  button: true,
                  child: IconButton.filled(
                    onPressed: _submitQuickLog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// -- Create Lab Bottom Sheet --------------------------------------------------

/// Modal bottom sheet for creating a new lab with name and type fields.
///
/// Returns a record of `({String name, String type})` on success, or null
/// if dismissed. Uses the same frosted-glass input sheet pattern as the
/// Arsenal tab's video naming flow.
class _CreateLabSheet extends StatefulWidget {
  const _CreateLabSheet();

  @override
  State<_CreateLabSheet> createState() => _CreateLabSheetState();
}

class _CreateLabSheetState extends State<_CreateLabSheet> {
  final _nameController = TextEditingController();
  String _selectedType = 'project';
  bool _nameEmpty = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final empty = _nameController.text.trim().isEmpty;
      if (empty != _nameEmpty) {
        setState(() => _nameEmpty = empty);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      (name: _nameController.text.trim(), type: _selectedType),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'New Lab',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name field
          Semantics(
            label: 'Lab name',
            textField: true,
            child: TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Lab name'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Type selector
          Text(
            'Type',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _TypeChip(
                label: 'Project',
                icon: Icons.science_outlined,
                selected: _selectedType == 'project',
                onTap: () => setState(() => _selectedType = 'project'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TypeChip(
                label: 'Set',
                icon: Icons.playlist_play_rounded,
                selected: _selectedType == 'set',
                onTap: () => setState(() => _selectedType = 'set'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save button
          Semantics(
            label: 'Create lab',
            button: true,
            enabled: !_nameEmpty,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nameEmpty ? null : _submit,
                child: const Text('Create'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Type Chip ----------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? Colors.white : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
