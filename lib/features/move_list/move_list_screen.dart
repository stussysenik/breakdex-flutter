import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _viewModeProvider =
    NotifierProvider<_ViewModeNotifier, ViewMode>(_ViewModeNotifier.new);

class _ViewModeNotifier extends Notifier<ViewMode> {
  static const _key = 'arsenal_view_mode';

  @override
  ViewMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key);
    return value == 'grid' ? ViewMode.grid : ViewMode.list;
  }

  Future<void> set(ViewMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

final _movesStreamProvider = StreamProvider<List<Move>>((ref) {
  final category = ref.watch(_selectedCategoryProvider);
  final repo = ref.watch(moveRepositoryProvider);
  if (category != null) {
    return repo.watchByCategory(category);
  }
  return repo.watchAll();
});

// -- Screen ------------------------------------------------------------------

class MoveListScreen extends ConsumerWidget {
  const MoveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(_movesStreamProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final viewMode = ref.watch(_viewModeProvider);
    final viewNames = ref.watch(viewNamesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final title = viewNames[viewMode.name] ??
        (viewMode == ViewMode.list ? 'Arsenal' : 'Gallery');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenEdge, AppSpacing.lg, AppSpacing.screenEdge, 0,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
              child: TextField(
                onChanged: (v) =>
                    ref.read(_searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search moves...',
                  prefixIcon:
                      Icon(Icons.search, color: colorScheme.secondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category filter chips
            const _CategoryChips(),
            const SizedBox(height: AppSpacing.sm),

            // View mode toggle
            _ViewModeToggle(viewMode: viewMode, viewNames: viewNames),
            const SizedBox(height: AppSpacing.sm),

            // Content
            Expanded(
              child: movesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (moves) {
                  final filtered = searchQuery.isEmpty
                      ? moves
                      : moves
                          .where((m) => m.name
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                          .toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(hasSearch: searchQuery.isNotEmpty);
                  }

                  if (viewMode == ViewMode.grid) {
                    return _MoveGrid(moves: filtered);
                  }
                  return _MoveList(moves: filtered);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMoveSheet(context, ref),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAddMoveSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final selectedCategory = ref.read(_selectedCategoryProvider);

    final result = await showModalBottomSheet<
        ({String name, String? category, bool pickVideo})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _AddMoveSheet(
        nameController: nameController,
        initialCategory: selectedCategory,
      ),
    );

    if (result == null || result.name.isEmpty || !context.mounted) return;

    String? videoPath;
    if (result.pickVideo) {
      final pickerResult = await VideoPickerSheet.show(context);
      videoPath = pickerResult?.localPath;
    }

    if (context.mounted) {
      HapticFeedback.mediumImpact();
      _createMove(ref, result.name, result.category, videoPath);
    }
  }

  void _createMove(
      WidgetRef ref, String name, String? category, String? videoPath) {
    ref.read(moveRepositoryProvider).insert(
          MovesCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            category: Value(category ?? 'default'),
            videoPath: Value(videoPath),
          ),
        );
  }
}

// -- Add Move Sheet ----------------------------------------------------------

class _AddMoveSheet extends ConsumerStatefulWidget {
  const _AddMoveSheet({
    required this.nameController,
    required this.initialCategory,
  });

  final TextEditingController nameController;
  final String? initialCategory;

  @override
  ConsumerState<_AddMoveSheet> createState() => _AddMoveSheetState();
}

class _AddMoveSheetState extends ConsumerState<_AddMoveSheet> {
  late String? _selectedCategory = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
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
          Text('Add Move',
              style: AppTypography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              )),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: widget.nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Move name'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category selector
          Text('Category',
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              )),
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
                onTap: () => setState(() => _selectedCategory = null),
              ),
              for (final cat in categories)
                _buildCategoryChip(
                  context,
                  label: cat.name,
                  color: cat.color,
                  selected: _selectedCategory == cat.name,
                  onTap: () => setState(() => _selectedCategory = cat.name),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    (
                      name: widget.nameController.text.trim(),
                      category: _selectedCategory,
                      pickVideo: true,
                    ),
                  ),
                  icon: const Icon(Icons.video_library),
                  label: const Text('Pick Video'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    (
                      name: widget.nameController.text.trim(),
                      category: _selectedCategory,
                      pickVideo: false,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : colorScheme.surfaceContainerHighest,
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

// -- Category Chips ----------------------------------------------------------

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(_selectedCategoryProvider);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        children: [
          _chip(
            context,
            label: 'All',
            color: AppColors.accent,
            selected: selected == null,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_selectedCategoryProvider.notifier).state = null;
            },
          ),
          for (final cat in categories) ...[
            const SizedBox(width: AppSpacing.sm),
            _chip(
              context,
              label: cat.name,
              color: cat.color,
              selected: selected == cat.name,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(_selectedCategoryProvider.notifier).state = cat.name;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
  const _ViewModeToggle({
    required this.viewMode,
    required this.viewNames,
  });

  final ViewMode viewMode;
  final Map<String, String> viewNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Row(
        children: [
          for (final mode in ViewMode.values) ...[
            if (mode != ViewMode.values.first) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (viewMode != mode) {
                    HapticFeedback.selectionClick();
                    ref.read(_viewModeProvider.notifier).set(mode);
                  }
                },
                onLongPress: () => _showRenameDialog(context, ref, mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: viewMode == mode
                        ? AppColors.accent
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode == ViewMode.list
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        size: 16,
                        color: viewMode == mode
                            ? Colors.white
                            : colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        viewNames[mode.name] ??
                            (mode == ViewMode.list ? 'Arsenal' : 'Gallery'),
                        style: AppTypography.caption.copyWith(
                          color: viewMode == mode
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: viewMode == mode
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

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, ViewMode mode) async {
    final controller = TextEditingController(
      text: viewNames[mode.name] ??
          (mode == ViewMode.list ? 'Arsenal' : 'Gallery'),
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

// -- Empty State -------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_martial_arts,
              size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasSearch ? 'No results' : 'No moves yet',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first move',
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      itemCount: moves.length,
      itemBuilder: (context, index) => _MoveRow(move: moves[index]),
    );
  }
}

// -- Grid View ---------------------------------------------------------------

class _MoveGrid extends StatelessWidget {
  const _MoveGrid({required this.moves});

  final List<Move> moves;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: moves.length,
      itemBuilder: (context, index) => _MoveGridCell(move: moves[index]),
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/arsenal/move/${move.id}');
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (move.videoPath != null)
              _GridThumbnail(videoPath: move.videoPath!)
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.videocam_off,
                    size: 40, color: colorScheme.secondary),
              ),

            // Gradient scrim at bottom
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
                child: Text(
                  move.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // State pill in top-right
            Positioned(
              top: 8,
              right: 8,
              child: StatePill(state: learningState),
            ),
          ],
        ),
      ),
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
      return Image.file(
        File(_thumbPath!),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.videocam, size: 40, color: colorScheme.secondary),
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
                // Thumbnail
                if (move.videoPath != null)
                  _Thumbnail(videoPath: move.videoPath!)
                else
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.videocam_off,
                        size: 20, color: colorScheme.secondary),
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
                          child: Text(
                            move.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
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
    );
  }
}

// -- List Thumbnail ----------------------------------------------------------

class _Thumbnail extends StatefulWidget {
  const _Thumbnail({required this.videoPath});
  final String videoPath;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
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
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _loaded && _thumbPath != null
          ? Image.file(
              File(_thumbPath!),
              fit: BoxFit.cover,
              width: 44,
              height: 44,
            )
          : Icon(Icons.videocam, size: 20, color: colorScheme.secondary),
    );
  }
}
