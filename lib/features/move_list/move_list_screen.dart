import 'dart:async';
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
import '../../core/database/daos/combos_dao.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/native_video_album.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/thumbnail_load_coordinator.dart';
import '../../core/services/video_service.dart';
import '../../core/services/view_names_service.dart';
import '../../shared/widgets/celebration_overlay.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../sync_onboarding/sync_onboarding_card.dart';

part 'widgets/move_grid_cell.dart';
part 'widgets/combo_grid_cell.dart';
part 'widgets/move_row.dart';
part 'widgets/combo_row.dart';

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
  MoveListScreen({super.key});

  final NativeVideoAlbum _videoAlbum = NativeVideoAlbum();
  final ThumbnailLoadCoordinator _thumbnailCoordinator =
      ThumbnailLoadCoordinator();

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
      body: ThumbnailCoordinatorScope(
        coordinator: _thumbnailCoordinator,
        child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Title + search + controls as pinned header
            SliverToBoxAdapter(
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
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.secondary,
                          ),
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
                ],
              ),
            ),

            // iCloud onboarding — shown once on first launch
            const SliverToBoxAdapter(
              child: SyncOnboardingCard(),
            ),

            // Content — sliver-based for compositor-friendly scrolling
            segment == ArsenalSegment.moves
                ? movesAsync.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: Center(child: Text('Error: $e')),
                    ),
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
                        return SliverFillRemaining(
                          child: _EmptyState(
                            hasSearch: searchQuery.isNotEmpty,
                            isCombo: false,
                          ),
                        );
                      }

                      return switch (viewMode) {
                        ViewMode.grid => _MoveGridSliver(moves: filtered),
                        ViewMode.list => _MoveListSliver(moves: filtered),
                      };
                    },
                  )
                : combosAsync.when(
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: Center(child: Text('Error: $e')),
                    ),
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
                        return SliverFillRemaining(
                          child: _EmptyState(
                            hasSearch: searchQuery.isNotEmpty,
                            isCombo: true,
                          ),
                        );
                      }

                      return switch (viewMode) {
                        ViewMode.grid => _ComboGridSliver(combos: filtered),
                        ViewMode.list => _CombosContentSliver(combos: filtered),
                      };
                    },
                  ),

            // Bottom padding so last items aren't hidden behind frosted nav bar
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
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Semantics(
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
                    ArsenalSegment.combos => () async {
                      final comboName = await context.push<String>(
                        '/create-combo',
                      );
                      if (!context.mounted || comboName == null) return;
                      ref.read(_arsenalSegmentProvider.notifier).state =
                          ArsenalSegment.combos;
                      HapticFeedback.mediumImpact();
                      CelebrationOverlay.show(context, title: comboName);
                    },
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
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

    try {
      await _createMove(ref, result.name, result.category, videoPath);
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$error'.contains('duplicate_card_name')
                ? 'Card names must stay unique across moves and combos.'
                : 'Could not create move: $error',
          ),
        ),
      );
    }
  }

  Future<void> _createMove(
    WidgetRef ref,
    String name,
    String? category,
    String? videoPath,
  ) async {
    final safeCategory = category ?? 'default';
    final normalizedName = ref
        .read(reviewableNamingServiceProvider)
        .normalize(name);
    final isTaken = await ref
        .read(reviewableNamingServiceProvider)
        .isNameTaken(normalizedName);
    if (isTaken) {
      throw StateError('duplicate_card_name');
    }

    final moveId = const Uuid().v4();
    await ref
        .read(moveRepositoryProvider)
        .insert(
          MovesCompanion.insert(
            id: moveId,
            name: normalizedName,
            category: Value(safeCategory),
            videoPath: Value(videoPath),
          ),
        );
    if (videoPath != null) {
      // Save to photo album (non-fatal)
      unawaited(
        _videoAlbum
            .saveToAlbum(
              videoPath: videoPath,
              albumName: NativeVideoAlbum.defaultAlbumName(),
              assetTitle: normalizedName,
              category: safeCategory,
            )
            .catchError(
              (error) => debugPrint('Album save failed (non-fatal): $error'),
            ),
      );

      // Sync hook: hash → manifest → queue upload (non-fatal, fire-and-forget)
      unawaited(
        ref.read(videoImportSyncHookProvider).onVideoImported(
          localPath: videoPath,
          moveId: moveId,
        ).catchError(
          (error) => debugPrint('Sync hook failed (non-fatal): $error'),
        ),
      );
    }
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

  Future<void> _submit(String? selectedCategory) async {
    if (_nameEmpty || selectedCategory == null) return;

    final naming = ref.read(reviewableNamingServiceProvider);
    final normalized = naming.normalize(_nameController.text);
    final isTaken = await naming.isNameTaken(normalized);
    if (!mounted) return;

    if (isTaken) {
      setState(() => _errorText = '"$normalized" already exists.');
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pop(context, (name: normalized, category: selectedCategory));
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
    final selectedCategory =
        categories.any((cat) => cat.name == _selectedCategory)
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first.name : null);

    if (selectedCategory != _selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedCategory = selectedCategory);
        }
      });
    }

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
                                      decoration: InputDecoration(
                                        hintText: 'Move name',
                                        errorText: _errorText,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) =>
                                          _submit(selectedCategory),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Category chips
                                  Text(
                                    'Category',
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Required so the move keeps its meaning across review, stats, and gallery.',
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      for (final cat in categories)
                                        _buildCategoryChip(
                                          context,
                                          label: cat.name,
                                          color: cat.color,
                                          selected:
                                              selectedCategory == cat.name,
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
                                    enabled:
                                        !_nameEmpty && selectedCategory != null,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _nameEmpty ||
                                                selectedCategory == null
                                            ? null
                                            : () => _submit(selectedCategory),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
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
              ? colorScheme.primary
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
        ArsenalSegment.combos => Icons.linear_scale_rounded,
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
              child: Semantics(
                button: true,
                selected: selected == item,
                label: labelOf(item),
                child: GestureDetector(
                  onTap: () {
                    if (selected != item) onSelected(item);
                  },
                  onLongPress: onLongPress != null
                      ? () => onLongPress!(item)
                      : null,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected == item
                            ? colorScheme.primary
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- Shared arsenal sliver layout builders ------------------------------------

/// Staggered-animated SliverList shared by both Moves and Combos list modes.
/// Uses SliverList for compositor-friendly scrolling within CustomScrollView.
Widget _sliverStaggeredList({
  required int itemCount,
  required Widget Function(int index) builder,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
    sliver: SliverList.builder(
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
    ),
  );
}

/// 2-column SliverGrid shared by both Moves and Combos grid modes.
Widget _sliverArsenalGrid({
  required int itemCount,
  required Widget Function(int index) builder,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
    sliver: SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: itemCount,
      itemBuilder: (_, index) => builder(index),
    ),
  );
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
            isCombo ? Icons.linear_scale_rounded : Icons.sports_martial_arts,
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

class _MoveListSliver extends StatelessWidget {
  const _MoveListSliver({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    return _sliverStaggeredList(
      itemCount: moves.length,
      builder: (index) => _MoveRow(move: moves[index]),
    );
  }
}

// -- Grid View ---------------------------------------------------------------

class _MoveGridSliver extends StatelessWidget {
  const _MoveGridSliver({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    return _sliverArsenalGrid(
      itemCount: moves.length,
      builder: (index) => _MoveGridCell(move: moves[index]),
    );
  }
}

