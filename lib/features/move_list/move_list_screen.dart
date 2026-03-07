import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/view_names_service.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_picker_sheet.dart';

// -- Providers ---------------------------------------------------------------

enum ViewMode { list, grid }

enum ArsenalSegment { moves, combos }

final _arsenalSegmentProvider = StateProvider<ArsenalSegment>(
  (_) => ArsenalSegment.moves,
);

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _combosStreamProvider = StreamProvider<List<(Combo, int)>>((ref) {
  return ref.watch(comboRepositoryProvider).watchAllWithMoveCounts();
});

final _viewModeProvider = NotifierProvider<_ViewModeNotifier, ViewMode>(
  _ViewModeNotifier.new,
);

class _ViewModeNotifier extends Notifier<ViewMode> {
  static const _key = 'arsenal_view_mode';

  @override
  ViewMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key);
    if (value == 'grid') return ViewMode.grid;
    return ViewMode.list;
  }

  Future<void> set(ViewMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

final _movesStreamProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

// -- Screen ------------------------------------------------------------------

class MoveListScreen extends ConsumerWidget {
  const MoveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(_movesStreamProvider);
    final combosAsync = ref.watch(_combosStreamProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final viewMode = ref.watch(_viewModeProvider);
    final viewNames = ref.watch(viewNamesProvider);
    final segment = ref.watch(_arsenalSegmentProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final title = viewNames['title'] ?? 'Arsenal';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenEdge,
                AppSpacing.lg,
                AppSpacing.screenEdge,
                0,
              ),
              child: Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: Semantics(
                label: 'Search',
                textField: true,
                child: TextField(
                  onChanged: (v) =>
                      ref.read(_searchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: segment == ArsenalSegment.moves
                        ? 'Search moves...'
                        : 'Search combos...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Moves / Combos segment toggle
            _ArsenalSegmentControl(segment: segment),
            const SizedBox(height: AppSpacing.sm),

            _ViewModeToggle(viewMode: viewMode, viewNames: viewNames),
            const SizedBox(height: AppSpacing.sm),

            // Content
            Expanded(
              child: segment == ArsenalSegment.moves
                  ? movesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (moves) {
                        final filtered = searchQuery.isEmpty
                            ? moves
                            : moves
                                  .where(
                                    (m) => m.name.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ),
                                  )
                                  .toList();

                        if (filtered.isEmpty) {
                          return _EmptyState(
                            hasSearch: searchQuery.isNotEmpty,
                            isCombo: false,
                          );
                        }

                        return switch (viewMode) {
                          ViewMode.grid => _MoveGrid(moves: filtered),
                          ViewMode.list => _MoveList(moves: filtered),
                        };
                      },
                    )
                  : combosAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (combosWithCounts) {
                        final filtered = searchQuery.isEmpty
                            ? combosWithCounts
                            : combosWithCounts
                                  .where(
                                    (c) => c.$1.name.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ),
                                  )
                                  .toList();

                        if (filtered.isEmpty) {
                          return _EmptyState(
                            hasSearch: searchQuery.isNotEmpty,
                            isCombo: true,
                          );
                        }

                        return switch (viewMode) {
                          ViewMode.grid => _ComboGrid(combos: filtered),
                          ViewMode.list => _CombosContent(combos: filtered),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          Semantics(
                label: segment == ArsenalSegment.moves
                    ? 'Add new move'
                    : 'Create new combo',
                button: true,
                child: FloatingActionButton(
                  onPressed: switch (segment) {
                    ArsenalSegment.moves => () => _startVideoFirstFlow(
                      context,
                      ref,
                    ),
                    ArsenalSegment.combos => () => context.push('/create-combo'),
                  },
                  backgroundColor: AppColors.accent,
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
    );
  }

  /// Video-first creation flow:
  /// FAB → VideoPickerSheet → optional editor → _VideoNamingSheet → save.
  /// If user taps "Skip", falls through to a simplified name-only sheet.
  Future<void> _startVideoFirstFlow(BuildContext context, WidgetRef ref) async {
    // 1. Open video picker immediately
    final pickerResult = await VideoPickerSheet.show(context);
    if (!context.mounted) return;

    // User cancelled picker entirely
    if (pickerResult == null) return;

    // 2. Optional video editor
    String videoPath = pickerResult.localPath;
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': videoPath},
    );
    if (!context.mounted) return;
    if (editedPath == null) return; // Cancel → back to arsenal, done
    if (editedPath != videoPath) {
      await ref.read(videoServiceProvider).replaceVideo(videoPath);
    }
    videoPath = editedPath;

    // 3. Generate thumbnail for naming sheet background
    final thumbPath = await VideoService().generateThumbnail(videoPath);

    if (!context.mounted) return;

    // 4. Show naming sheet with video thumbnail background
    final result =
        await showModalBottomSheet<({String name, String? category})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _VideoNamingSheet(videoPath: videoPath, thumbnailPath: thumbPath),
        );

    if (result == null || result.name.isEmpty || !context.mounted) return;

    HapticFeedback.mediumImpact();
    _createMove(ref, result.name, result.category, videoPath);
  }

  void _createMove(
    WidgetRef ref,
    String name,
    String? category,
    String? videoPath,
  ) {
    ref
        .read(moveRepositoryProvider)
        .insert(
          MovesCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            category: Value(category ?? 'default'),
            videoPath: Value(videoPath),
          ),
        );
  }
}

// -- Video Naming Sheet (video-first flow) -----------------------------------

/// Frosted-glass naming sheet shown after video pick/record.
/// Background: video thumbnail with dark gradient scrim.
/// Foreground: autofocused name field + category row + save button.
class _VideoNamingSheet extends ConsumerStatefulWidget {
  const _VideoNamingSheet({required this.videoPath, this.thumbnailPath});

  final String videoPath;
  final String? thumbnailPath;

  @override
  ConsumerState<_VideoNamingSheet> createState() => _VideoNamingSheetState();
}

class _VideoNamingSheetState extends ConsumerState<_VideoNamingSheet> {
  final _nameController = TextEditingController();
  String? _selectedCategory;
  bool _nameEmpty = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final empty = _nameController.text.trim().isEmpty;
    if (empty != _nameEmpty) setState(() => _nameEmpty = empty);
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

    return Stack(
      children: [
        // Thumbnail background
        if (widget.thumbnailPath != null)
          Positioned.fill(
            child: Image.file(
              File(widget.thumbnailPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        // Dark gradient scrim
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),
        // Frosted glass content panel
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenEdge,
              AppSpacing.xl,
              AppSpacing.screenEdge,
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child:
                Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(
                                  alpha: 0.7,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name this move',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Semantics(
                                    label: 'Move name',
                                    textField: true,
                                    child: TextField(
                                      controller: _nameController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Move name',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Category chips
                                  Text(
                                    'Category',
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      _buildCategoryChip(
                                        context,
                                        label: 'None',
                                        color: colorScheme.secondary,
                                        selected: _selectedCategory == null,
                                        onTap: () => setState(
                                          () => _selectedCategory = null,
                                        ),
                                      ),
                                      for (final cat in categories)
                                        _buildCategoryChip(
                                          context,
                                          label: cat.name,
                                          color: cat.color,
                                          selected:
                                              _selectedCategory == cat.name,
                                          onTap: () => setState(
                                            () => _selectedCategory = cat.name,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  // Full-width save button
                                  Semantics(
                                    label: 'Save move',
                                    button: true,
                                    enabled: !_nameEmpty,
                                    child: SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _nameEmpty
                                          ? null
                                          : () => Navigator.pop(context, (
                                              name: _nameController.text.trim(),
                                              category: _selectedCategory,
                                            )),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: AppColors
                                            .accent
                                            .withValues(alpha: 0.3),
                                        disabledForegroundColor: Colors.white
                                            .withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: AppMotion.moderate02)
                    .slideY(
                      begin: 0.05,
                      duration: AppMotion.moderate02,
                      curve: AppMotion.entrance,
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- View Mode Toggle --------------------------------------------------------

class _ViewModeToggle extends ConsumerWidget {
  const _ViewModeToggle({required this.viewMode, required this.viewNames});

  final ViewMode viewMode;
  final Map<String, String> viewNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PillToggleRow<ViewMode>(
      items: ViewMode.values,
      selected: viewMode,
      iconOf: (m) => switch (m) {
        ViewMode.list => Icons.view_list_rounded,
        ViewMode.grid => Icons.grid_view_rounded,
      },
      labelOf: (m) =>
          viewNames[m.name] ??
          switch (m) {
            ViewMode.list => 'List',
            ViewMode.grid => 'Gallery',
          },
      onSelected: (m) {
        HapticFeedback.selectionClick();
        ref.read(_viewModeProvider.notifier).set(m);
      },
      onLongPress: (m) => _showRenameDialog(context, ref, m),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ViewMode mode,
  ) async {
    final controller = TextEditingController(
      text:
          viewNames[mode.name] ??
          switch (mode) {
            ViewMode.list => 'List',
            ViewMode.grid => 'Gallery',
          },
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename View'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'View name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      ref.read(viewNamesProvider.notifier).rename(mode.name, newName);
      HapticFeedback.mediumImpact();
    }
  }
}

// -- Arsenal Segment Control -------------------------------------------------

class _ArsenalSegmentControl extends ConsumerWidget {
  const _ArsenalSegmentControl({required this.segment});

  final ArsenalSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PillToggleRow(
      items: ArsenalSegment.values,
      selected: segment,
      iconOf: (s) => switch (s) {
        ArsenalSegment.moves => Icons.sports_martial_arts,
        ArsenalSegment.combos => Icons.playlist_play,
      },
      labelOf: (s) => switch (s) {
        ArsenalSegment.moves => 'Moves',
        ArsenalSegment.combos => 'Combos',
      },
      onSelected: (s) {
        HapticFeedback.selectionClick();
        ref.read(_arsenalSegmentProvider.notifier).state = s;
      },
    );
  }
}

/// Shared pill-toggle row used by both _ViewModeToggle and _ArsenalSegmentControl.
class _PillToggleRow<T> extends StatelessWidget {
  const _PillToggleRow({
    super.key,
    required this.items,
    required this.selected,
    required this.iconOf,
    required this.labelOf,
    required this.onSelected,
    this.onLongPress,
  });

  final List<T> items;
  final T selected;
  final IconData Function(T) iconOf;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final void Function(T)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Row(
        children: [
          for (final item in items) ...[
            if (item != items.first) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (selected != item) onSelected(item);
                },
                onLongPress: onLongPress != null
                    ? () => onLongPress!(item)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == item
                        ? AppColors.accent
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconOf(item),
                        size: 16,
                        color: selected == item
                            ? Colors.white
                            : colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labelOf(item),
                        style: AppTypography.caption.copyWith(
                          color: selected == item
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: selected == item
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- Combos Content ----------------------------------------------------------

class _CombosContent extends StatelessWidget {
  const _CombosContent({required this.combos});

  final List<(Combo, int)> combos;

  @override
  Widget build(BuildContext context) {
    return _staggeredList(
      itemCount: combos.length,
      builder: (index) {
        final (combo, moveCount) = combos[index];
        return _ComboRow(combo: combo, moveCount: moveCount);
      },
    );
  }
}

/// A combo list row with swipe-to-delete, move-count dots, and a colored
/// leading bar. Mirrors the `_MoveRow` pattern for consistent UX.
class _ComboRow extends ConsumerWidget {
  const _ComboRow({required this.combo, required this.moveCount});

  final Combo combo;
  final int moveCount;

  /// Max dots rendered before showing a "+N" overflow indicator.
  static const _maxDots = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(combo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.screenEdge),
        decoration: BoxDecoration(
          color: AppColors.actionAgain,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        ref.read(comboRepositoryProvider).delete(combo.id);
      },
      child: Semantics(
        identifier: 'combo-row-${combo.id}',
        label: '${combo.name}, $moveCount moves',
        button: true,
        child: InkWell(
        onTap: () => context.go('/arsenal/combo/${combo.id}'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Leading accent bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.sm),
                      bottomLeft: Radius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.playlist_play, color: AppColors.accent, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          combo.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (moveCount > 0) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _MoveCountDots(count: moveCount),
                        ],
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Renders small dots representing the number of moves in a combo.
/// Caps at [_ComboRow._maxDots] and shows a "+N" overflow label.
class _MoveCountDots extends StatelessWidget {
  const _MoveCountDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotsToShow = count.clamp(0, _ComboRow._maxDots);
    final overflow = count - dotsToShow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < dotsToShow; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ).animate().scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: AppMotion.fast02,
            delay: Duration(milliseconds: i * 20),
            curve: AppMotion.expressive,
          ),
        ],
        if (overflow > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+$overflow',
            style: AppTypography.caption.copyWith(
              color: colorScheme.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

// -- Combo Grid View ---------------------------------------------------------

// -- Shared arsenal layout builders -------------------------------------------

/// Staggered-animated ListView shared by both Moves and Combos list modes.
Widget _staggeredList({
  required int itemCount,
  required Widget Function(int index) builder,
}) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
    itemCount: itemCount,
    itemBuilder: (_, index) => builder(index)
        .animate()
        .fadeIn(
          duration: AppMotion.moderate01,
          delay: Duration(milliseconds: index.clamp(0, 15) * 40),
        )
        .slideY(
          begin: 0.03,
          duration: AppMotion.moderate02,
          delay: Duration(milliseconds: index.clamp(0, 15) * 40),
        ),
  );
}

/// 2-column GridView shared by both Moves and Combos grid modes.
Widget _arsenalGrid({
  required int itemCount,
  required Widget Function(int index) builder,
}) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.8,
    ),
    itemCount: itemCount,
    itemBuilder: (_, index) => builder(index),
  );
}

/// Shared grid card shell for both move and combo grid cells.
class _GridCardShell extends StatelessWidget {
  const _GridCardShell({
    required this.onTap,
    required this.background,
    required this.name,
    required this.topRightWidget,
    this.subtitle,
  });

  final VoidCallback onTap;
  final Widget background;
  final String name;
  final Widget topRightWidget;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            background,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
            ),
            Positioned(top: 8, right: 8, child: topRightWidget),
          ],
        ),
      ),
    );
  }
}

/// Grid layout for combos — mirrors `_MoveGrid` but uses a styled placeholder
/// instead of a video thumbnail (combos don't have their own video).
class _ComboGrid extends StatelessWidget {
  const _ComboGrid({required this.combos});

  final List<(Combo, int)> combos;

  @override
  Widget build(BuildContext context) {
    return _arsenalGrid(
      itemCount: combos.length,
      builder: (index) {
        final (combo, moveCount) = combos[index];
        return _ComboGridCell(combo: combo, moveCount: moveCount);
      },
    );
  }
}

/// A single combo card in grid view. Shows an accent-gradient placeholder
/// with a playlist icon, the combo name, move-count dots, and a count pill.
class _ComboGridCell extends ConsumerWidget {
  const _ComboGridCell({required this.combo, required this.moveCount});

  final Combo combo;
  final int moveCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GridCardShell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/arsenal/combo/${combo.id}');
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.playlist_play,
            size: 48,
            color: AppColors.accent.withValues(alpha: 0.4),
          ),
        ),
      ),
      name: combo.name,
      subtitle: moveCount > 0 ? _MoveCountDots(count: moveCount) : null,
      topRightWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_play, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '$moveCount',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Empty State -------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, this.isCombo = false});

  final bool hasSearch;
  final bool isCombo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCombo ? Icons.playlist_play : Icons.sports_martial_arts,
            size: 64,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasSearch
                ? 'No results'
                : isCombo
                ? 'No combos yet'
                : 'No moves yet',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              isCombo
                  ? 'Tap + to create your first combo'
                  : 'Tap + to add your first move',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- List View ---------------------------------------------------------------

class _MoveList extends StatelessWidget {
  const _MoveList({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    return _staggeredList(
      itemCount: moves.length,
      builder: (index) => _MoveRow(move: moves[index]),
    );
  }
}

// -- Grid View ---------------------------------------------------------------

class _MoveGrid extends StatelessWidget {
  const _MoveGrid({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    return _arsenalGrid(
      itemCount: moves.length,
      builder: (index) => _MoveGridCell(move: moves[index]),
    );
  }
}

class _MoveGridCell extends ConsumerWidget {
  const _MoveGridCell({required this.move});

  final Move move;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningState = LearningState.fromString(move.learningState);
    final colorScheme = Theme.of(context).colorScheme;

    return _GridCardShell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/arsenal/move/${move.id}');
      },
      background: move.videoPath != null
          ? _GridThumbnail(videoPath: move.videoPath!)
          : Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.videocam_off,
                size: 40,
                color: colorScheme.secondary,
              ),
            ),
      name: move.name,
      subtitle: move.category != 'default'
          ? _CategoryLabel(
              category: move.category,
              overrideTextColor: Colors.white70,
            )
          : null,
      topRightWidget: StatePill(state: learningState),
    );
  }
}

class _GridThumbnail extends StatefulWidget {
  const _GridThumbnail({required this.videoPath});
  final String videoPath;

  @override
  State<_GridThumbnail> createState() => _GridThumbnailState();
}

class _GridThumbnailState extends State<_GridThumbnail> {
  final _videoService = VideoService();
  String? _thumbPath;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await _videoService.generateThumbnail(widget.videoPath);
    if (mounted) {
      setState(() {
        _thumbPath = path;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loaded && _thumbPath != null) {
      return Image.file(File(_thumbPath!), fit: BoxFit.cover);
    }
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: _loaded
          ? Icon(Icons.videocam_off, size: 40, color: colorScheme.secondary)
          : const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}

// -- List Row ----------------------------------------------------------------

class _MoveRow extends ConsumerWidget {
  const _MoveRow({required this.move});

  final Move move;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = LearningState.fromString(move.learningState);
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(move.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.screenEdge),
        color: AppColors.actionAgain,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        ref.read(moveRepositoryProvider).delete(move.id);
      },
      child: Semantics(
        identifier: 'move-row-${move.id}',
        label: '${move.name}, ${state.displayText}',
        button: true,
        child: InkWell(
          onTap: () => context.go('/arsenal/move/${move.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: state.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sm),
                        bottomLeft: Radius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  move.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (move.category != 'default') ...[
                                  const SizedBox(height: 2),
                                  _CategoryLabel(category: move.category),
                                ],
                              ],
                            ),
                          ),
                          StatePill(state: state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Inline Category Label ---------------------------------------------------

/// Small color dot + category name shown inline on each move row/grid cell.
/// Replaces the old filter-chip approach — category is always visible without
/// needing to toggle a filter.
class _CategoryLabel extends ConsumerWidget {
  const _CategoryLabel({required this.category, this.overrideTextColor});

  final String category;
  final Color? overrideTextColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final match = categories.where((c) => c.name == category).firstOrNull;
    final dotColor = match?.color ?? Theme.of(context).colorScheme.secondary;
    final textColor =
        overrideTextColor ?? Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          category,
          style: AppTypography.caption.copyWith(color: textColor, fontSize: 10),
        ),
      ],
    );
  }
}
