import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/database/daos/combos_dao.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/move_creation.dart';
import '../../core/models/reviewable_item.dart'
    show ComboVideoPath, MoveVideoPath;
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/media_playback_coordinator.dart';
import '../../core/services/thumbnail_load_coordinator.dart';
import '../../core/services/video_service.dart';
import '../../core/utils/diagnostics.dart';
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

final _searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

class _SearchQueryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void onChanged(final String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = value;
    });
  }
}
final _dismissedReliabilityReportEpochProvider = StateProvider<int?>(
  (final ref) => null,
);

final _combosStreamProvider = StreamProvider<List<(Combo, int)>>((final ref) {
  final stream = ref.watch(comboRepositoryProvider).watchAllWithMoveCounts();
  return stream.map((final combos) {
    debugPrint('[MoveList] _combosStreamProvider emitted ${combos.length} combos');
    return combos;
  });
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

  Future<void> set(final ViewMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

final _movesStreamProvider = StreamProvider<List<Move>>((final ref) {
  final stream = ref.watch(moveRepositoryProvider).watchAll();
  return stream.map((final moves) {
    debugPrint('[MoveList] _movesStreamProvider emitted ${moves.length} moves');
    return moves;
  });
});

// -- Screen ------------------------------------------------------------------

class MoveListScreen extends ConsumerWidget {
  MoveListScreen({super.key});

  final ThumbnailLoadCoordinator _thumbnailCoordinator =
      ThumbnailLoadCoordinator();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final movesAsync = ref.watch(_movesStreamProvider);
    final combosAsync = ref.watch(_combosStreamProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final viewMode = ref.watch(_viewModeProvider);
    final viewNames = ref.watch(viewNamesProvider);
    final segment = ref.watch(_arsenalSegmentProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final title = viewNames['title'] ?? 'Moves';

    return Scaffold(
      body: ThumbnailCoordinatorScope(
        coordinator: _thumbnailCoordinator,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top padding for the header
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

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
                          onChanged: (final v) =>
                              ref.read(_searchQueryProvider.notifier).onChanged(v),
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
              const SliverToBoxAdapter(child: SyncOnboardingCard()),
              const SliverToBoxAdapter(child: _StartupVideoReliabilityBanner()),

              // Content — sliver-based for compositor-friendly scrolling
              segment == ArsenalSegment.moves
                  ? movesAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (final e, _) => SliverFillRemaining(
                        child: Center(child: Text('Error: $e')),
                      ),
                      data: (final moves) {
                        final filtered = searchQuery.isEmpty
                            ? moves
                            : moves
                                  .where(
                                    (final m) => m.name.toLowerCase().contains(
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
                      error: (final e, _) => SliverFillRemaining(
                        child: Center(child: Text('Error: $e')),
                      ),
                      data: (final combosWithCounts) {
                        final filtered = searchQuery.isEmpty
                            ? combosWithCounts
                            : combosWithCounts
                                  .where(
                                    (final c) => c.$1.name.toLowerCase().contains(
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
                          ViewMode.list => _CombosContentSliver(
                            combos: filtered,
                          ),
                        };
                      },
                    ),

              // Bottom padding so last items aren't hidden behind frosted nav bar
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom:
                      kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom +
                      AppSpacing.xxl,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom:
              kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom +
              AppSpacing.sm,
        ),
        child:
            Semantics(
                  label: segment == ArsenalSegment.moves
                      ? 'Add new move'
                      : 'Create new combo',
                  button: true,
                  child: FloatingActionButton(
                    onPressed: switch (segment) {
                      ArsenalSegment.moves => () => _startMoveCreationFlow(
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
                        unawaited(HapticFeedback.mediumImpact());
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

  Future<void> _startMoveCreationFlow(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    final draft = await showModalBottomSheet<({String name, String category})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MoveMetadataSheet(),
    );
    if (draft == null || !context.mounted) return;

    final videoIntent = await showModalBottomSheet<_MoveVideoIntent>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) =>
          _MoveVideoPromptSheet(name: draft.name, category: draft.category),
    );
    if (videoIntent == null || !context.mounted) return;

    ({String localPath, String? originalVideoName})? videoAttachment;
    if (videoIntent == _MoveVideoIntent.addNow) {
      videoAttachment = await _captureVideoAttachment(context, ref);
      if (!context.mounted) return;
      if (videoAttachment == null) {
        final saveWithoutVideo = await _confirmCreateWithoutVideo(context);
        if (!context.mounted || !saveWithoutVideo) return;
      }
    }

    try {
      final result = await ref
          .read(moveCreationServiceProvider)
          .createMove(
            CreateMoveRequest(
              name: draft.name,
              category: draft.category,
              localVideoPath: videoAttachment?.localPath,
              originalVideoName: videoAttachment?.originalVideoName,
            ),
          );
      if (!context.mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      CelebrationOverlay.show(context, title: result.name);
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

  Future<({String localPath, String? originalVideoName})?>
  _captureVideoAttachment(final BuildContext context, final WidgetRef ref) async {
    MediaPlaybackCoordinator.shared.pauseAll();
    final pickerResult = await VideoPickerSheet.show(context);
    if (!context.mounted || pickerResult == null) return null;

    var videoPath = pickerResult.localPath;
    MediaPlaybackCoordinator.shared.pauseAll();
    final editedPath = await context.push<String>(
      '/video-editor',
      extra: {'videoPath': videoPath},
    );
    if (!context.mounted || editedPath == null) return null;

    if (editedPath != videoPath) {
      await ref.read(videoServiceProvider).replaceVideo(videoPath);
      videoPath = editedPath;
    }

    return (
      localPath: videoPath,
      originalVideoName: pickerResult.originalFileName,
    );
  }

  Future<bool> _confirmCreateWithoutVideo(final BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (final dialogContext) => AlertDialog(
        title: const Text('Create Without Video?'),
        content: const Text(
          'No video was attached. You can still create the move now and add or trim a video later from the move detail screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create Move'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _StartupVideoReliabilityBanner extends ConsumerWidget {
  const _StartupVideoReliabilityBanner();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final report = ref.watch(videoReliabilityReportProvider).valueOrNull;
    if (report == null || !report.hasUserSignal) {
      return const SizedBox.shrink();
    }

    final reportEpoch = report.completedAt.millisecondsSinceEpoch;
    final dismissedEpoch = ref.watch(_dismissedReliabilityReportEpochProvider);
    if (dismissedEpoch == reportEpoch) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final hasRecovery = report.restoredLocally > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        0,
        AppSpacing.screenEdge,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: hasRecovery
              ? AppColors.accent.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasRecovery
                ? AppColors.accent.withValues(alpha: 0.25)
                : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasRecovery ? Icons.download_done_rounded : Icons.cloud_sync,
                color: hasRecovery
                    ? AppColors.accent
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.detail,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                splashRadius: 18,
                onPressed: () {
                  ref
                          .read(
                            _dismissedReliabilityReportEpochProvider.notifier,
                          )
                          .state =
                      reportEpoch;
                },
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MoveVideoIntent { addNow, skipForNow }

// -- Move Metadata Sheet -----------------------------------------------------

class _MoveMetadataSheet extends ConsumerStatefulWidget {
  const _MoveMetadataSheet();

  @override
  ConsumerState<_MoveMetadataSheet> createState() => _MoveMetadataSheetState();
}

class _MoveMetadataSheetState extends ConsumerState<_MoveMetadataSheet> {
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

  Future<void> _submit(final String? selectedCategory) async {
    if (_nameEmpty || selectedCategory == null) return;

    final naming = ref.read(reviewableNamingServiceProvider);
    final normalized = naming.normalize(_nameController.text);
    final isTaken = await naming.isNameTaken(normalized);
    if (!mounted) return;

    if (isTaken) {
      setState(() => _errorText = '"$normalized" already exists.');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    Navigator.pop(context, (name: normalized, category: selectedCategory));
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
    final selectedCategory =
        categories.any((final cat) => cat.name == _selectedCategory)
        ? _selectedCategory
        : (categories.isNotEmpty ? categories.first.name : null);

    if (selectedCategory != _selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedCategory = selectedCategory);
        }
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
        child:
            ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
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
                        Text(
                          'Add Move',
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set the name and category here. Notes stay in the move detail view so creation stays focused.',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.secondary,
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
                            onSubmitted: (_) => _submit(selectedCategory),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Category',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required so the move keeps its meaning across review, stats, flow, and the gallery.',
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
                                selected: selectedCategory == cat.name,
                                onTap: () => setState(
                                  () => _selectedCategory = cat.name,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Semantics(
                          label: 'Continue to video options',
                          button: true,
                          enabled: !_nameEmpty && selectedCategory != null,
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _nameEmpty || selectedCategory == null
                                  ? null
                                  : () => _submit(selectedCategory),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: colorScheme.primary
                                    .withValues(alpha: 0.3),
                                disabledForegroundColor: Colors.white
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.moderate02)
                .slideY(
                  begin: 0.05,
                  duration: AppMotion.moderate02,
                  curve: AppMotion.entrance,
                ),
      ),
    );
  }

  Widget _buildCategoryChip(
    final BuildContext context, {
    required final String label,
    required final Color color,
    required final bool selected,
    required final VoidCallback onTap,
  }) {
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

class _MoveVideoPromptSheet extends StatelessWidget {
  const _MoveVideoPromptSheet({required this.name, required this.category});

  final String name;
  final String category;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Video Now?',
              style: AppTypography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '“$name” is ready in $category. You can attach a video now using the Apple picker flow, then trim or replace it later from the move detail screen.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _MoveVideoIntent.addNow),
                icon: const Icon(Icons.video_call),
                label: const Text('Add Video'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.pop(context, _MoveVideoIntent.skipForNow),
                child: const Text('Skip For Now'),
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
  Widget build(final BuildContext context, final WidgetRef ref) {
    return _PillToggleRow<ViewMode>(
      items: ViewMode.values,
      selected: viewMode,
      iconOf: (final m) => switch (m) {
        ViewMode.list => Icons.view_list_rounded,
        ViewMode.grid => Icons.grid_view_rounded,
      },
      labelOf: (final m) =>
          viewNames[m.name] ??
          switch (m) {
            ViewMode.list => 'List',
            ViewMode.grid => 'Gallery',
          },
      onSelected: (final m) {
        HapticFeedback.selectionClick();
        ref.read(_viewModeProvider.notifier).set(m);
      },
      onLongPress: (final m) => _showRenameDialog(context, ref, m),
    );
  }

  Future<void> _showRenameDialog(
    final BuildContext context,
    final WidgetRef ref,
    final ViewMode mode,
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
      builder: (final ctx) => AlertDialog(
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
      unawaited(
        ref.read(viewNamesProvider.notifier).rename(mode.name, newName),
      );
      unawaited(HapticFeedback.mediumImpact());
    }
  }
}

// -- Arsenal Segment Control -------------------------------------------------

class _ArsenalSegmentControl extends ConsumerWidget {
  const _ArsenalSegmentControl({required this.segment});

  final ArsenalSegment segment;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return _PillToggleRow(
      items: ArsenalSegment.values,
      selected: segment,
      iconOf: (final s) => switch (s) {
        ArsenalSegment.moves => Icons.sports_martial_arts,
        ArsenalSegment.combos => Icons.linear_scale_rounded,
      },
      labelOf: (final s) => switch (s) {
        ArsenalSegment.moves => 'Moves',
        ArsenalSegment.combos => 'Combos',
      },
      onSelected: (final s) {
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
  Widget build(final BuildContext context) {
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
/// Animations are delegated to the row widgets so that [Dismissible] gesture
/// detection is not blocked by [flutter_animate]'s transform-based effects.
Widget _sliverStaggeredList({
  required final int itemCount,
  required final Widget Function(int index) builder,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
    sliver: SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (_, final index) => builder(index),
    ),
  );
}

/// 2-column SliverGrid shared by both Moves and Combos grid modes.
Widget _sliverArsenalGrid({
  required final int itemCount,
  required final Widget Function(int index) builder,
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
      itemBuilder: (_, final index) => builder(index),
    ),
  );
}

// -- Empty State -------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, this.isCombo = false});

  final bool hasSearch;
  final bool isCombo;

  @override
  Widget build(final BuildContext context) {
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
  Widget build(final BuildContext context) {
    return _sliverStaggeredList(
      itemCount: moves.length,
      builder: (final index) => _MoveRow(move: moves[index], index: index),
    );
  }
}

// -- Grid View ---------------------------------------------------------------

class _MoveGridSliver extends StatelessWidget {
  const _MoveGridSliver({required this.moves});

  final List<Move> moves;

  @override
  Widget build(final BuildContext context) {
    return _sliverArsenalGrid(
      itemCount: moves.length,
      builder: (final index) => _MoveGridCell(move: moves[index]),
    );
  }
}
