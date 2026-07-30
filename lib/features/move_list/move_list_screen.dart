// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/daos/combos_dao.dart';
import 'package:breakdex/core/design/icons.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/library_month_sections.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/core/models/move_creation.dart';
import 'package:breakdex/core/models/reviewable_item.dart'
    show ComboVideoPath, MoveVideoPath;
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/platform/native_media.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/core/services/media_playback_coordinator.dart';
import 'package:breakdex/core/services/thumbnail_load_coordinator.dart';
import 'package:breakdex/core/services/video_service.dart';
import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/services/view_names_service.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/shared/widgets/celebration_overlay.dart';
import 'package:breakdex/shared/widgets/pressable.dart';
import 'package:breakdex/shared/widgets/state_pill.dart';
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/shared/widgets/video_picker_sheet.dart';
import 'package:breakdex/shared/widgets/video_player_widget.dart';
import 'package:breakdex/features/sync_onboarding/sync_onboarding_card.dart';

part 'widgets/move_grid_cell.dart';
part 'widgets/combo_grid_cell.dart';
part 'widgets/move_row.dart';
part 'widgets/combo_row.dart';
part 'widgets/study_card.dart';

// -- Providers ---------------------------------------------------------------

/// Three view modes ordered easiest → hardest way of seeing (design.md):
/// Glance (media-first gallery), Scan (dense list), Study (rich cards). The
/// declaration order IS the fixed cycle order the toggle presents.
enum ViewMode { glance, scan, study }

/// Resolves the persisted `arsenal_view_mode` value to a [ViewMode], migrating
/// legacy names so no prior choice is lost (`grid` → Glance, `list` → Scan).
/// Unknown/absent values default to Glance — the lowest-cognitive-load mode and
/// the visual-first doctrine's natural landing.
ViewMode viewModeFromStored(final String? raw) => switch (raw) {
  'grid' || 'glance' => ViewMode.glance,
  'list' || 'scan' => ViewMode.scan,
  'study' => ViewMode.study,
  _ => ViewMode.glance,
};

/// Legacy stored values that must be re-persisted under their new name on first
/// read so the old string never lingers in preferences.
bool isLegacyViewModeValue(final String? raw) => raw == 'grid' || raw == 'list';

String _defaultViewModeLabel(final ViewMode mode) => switch (mode) {
  ViewMode.glance => 'Glance',
  ViewMode.scan => 'Scan',
  ViewMode.study => 'Study',
};

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

/// The library's combo feed. Reads `watchLibraryRows` (rather than
/// `watchAllWithMoveCounts`) because the "recently practiced" chain needs
/// `lastEntryAt`, which only that query carries — jotting a combo does not
/// touch `combos.updatedAt`.
final _combosStreamProvider = StreamProvider<List<LibraryRow>>((final ref) {
  final stream = ref.watch(combosDaoProvider).watchLibraryRows();
  return stream.map((final combos) {
    debugPrint(
      '[MoveList] _combosStreamProvider emitted ${combos.length} combos',
    );
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
    final raw = prefs.getString(_key);
    final mode = viewModeFromStored(raw);
    if (isLegacyViewModeValue(raw)) {
      // Re-persist the migrated value so the legacy string doesn't linger.
      unawaited(prefs.setString(_key, mode.name));
    }
    return mode;
  }

  Future<void> set(final ViewMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

/// The library's active ordering, persisted across launches.
///
/// Public (unlike [_viewModeProvider]) because the sort is read by the list
/// derivation and the header control, and because persistence is proven by
/// driving this notifier rather than by asserting resolver symmetry.
final librarySortProvider = NotifierProvider<LibrarySortNotifier, LibrarySort>(
  LibrarySortNotifier.new,
);

class LibrarySortNotifier extends Notifier<LibrarySort> {
  static const _key = 'library_sort';

  @override
  LibrarySort build() => librarySortFromStored(
    ref.watch(sharedPreferencesProvider).getString(_key),
  );

  Future<void> set(final LibrarySort sort) async {
    state = sort;
    await ref.read(sharedPreferencesProvider).setString(_key, sort.name);
  }
}

final _movesStreamProvider = StreamProvider<List<Move>>((final ref) {
  final stream = ref.watch(moveRepositoryProvider).watchAll();
  return stream.map((final moves) {
    debugPrint('[MoveList] _movesStreamProvider emitted ${moves.length} moves');
    return moves;
  });
});

/// The moves the library renders: the feed, filtered by the search query and
/// ordered by the active sort. Sorting is client-side (design D1) — the list is
/// already fully in memory and filtered in Dart, so the DAO ordering is left
/// alone and a sort change costs no query.
///
/// Public so the ordering can be driven and asserted without pumping the
/// screen; live Drift streams flake widget tests.
final libraryMovesProvider = Provider<AsyncValue<List<Move>>>((final ref) {
  final query = ref.watch(_searchQueryProvider).toLowerCase();
  final sort = ref.watch(librarySortProvider);
  return ref
      .watch(_movesStreamProvider)
      .whenData(
        (final moves) =>
            moves
                .where((final m) => m.name.toLowerCase().contains(query))
                .toList()
              ..sort(moveLibraryComparator(sort)),
      );
});

/// The combos the library renders. See [libraryMovesProvider].
final libraryCombosProvider = Provider<AsyncValue<List<LibraryRow>>>((
  final ref,
) {
  final query = ref.watch(_searchQueryProvider).toLowerCase();
  final sort = ref.watch(librarySortProvider);
  return ref
      .watch(_combosStreamProvider)
      .whenData(
        (final combos) =>
            combos
                .where((final c) => c.combo.name.toLowerCase().contains(query))
                .toList()
              ..sort(comboLibraryComparator(sort)),
      );
});

// -- Screen ------------------------------------------------------------------

class MoveListScreen extends ConsumerWidget {
  MoveListScreen({super.key});

  final ThumbnailLoadCoordinator _thumbnailCoordinator =
      ThumbnailLoadCoordinator();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final movesAsync = ref.watch(libraryMovesProvider);
    final combosAsync = ref.watch(libraryCombosProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final viewMode = ref.watch(_viewModeProvider);
    final viewNames = ref.watch(viewNamesProvider);
    final segment = ref.watch(_arsenalSegmentProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final title =
        viewNames['title'] ?? ref.watch(entityNamesProvider).movePlural;

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
                          onChanged: (final v) => ref
                              .read(_searchQueryProvider.notifier)
                              .onChanged(v),
                          decoration: InputDecoration(
                            hintText: segment == ArsenalSegment.moves
                                ? 'Search moves...'
                                : 'Search combos...',
                            prefixIcon: AppIconView(
                              AppIcon.search,
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

                    const LibrarySortToggle(),
                    const SizedBox(height: AppSpacing.sm),

                    LibraryFilmedFallbackNotice(
                      sort: ref.watch(librarySortProvider),
                      segment: segment,
                    ),
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
                        child: Center(child: AppLoader()),
                      ),
                      error: (final e, _) => SliverFillRemaining(
                        child: Center(child: Text('Error: $e')),
                      ),
                      data: (final filtered) {
                        if (filtered.isEmpty) {
                          return SliverFillRemaining(
                            child: _EmptyState(
                              hasSearch: searchQuery.isNotEmpty,
                              isCombo: false,
                            ),
                          );
                        }

                        final sort = ref.watch(librarySortProvider);
                        return librarySectionedSliver<Move>(
                          items: filtered,
                          sort: sort,
                          viewMode: viewMode,
                          dateOf: (final m) => m.effectiveDate(sort),
                          sliverOf: (final section) => switch (viewMode) {
                            ViewMode.glance => _MoveGridSliver(
                              moves: section,
                              sort: sort,
                            ),
                            ViewMode.scan => _MoveListSliver(
                              moves: section,
                              sort: sort,
                            ),
                            ViewMode.study => _MoveStudySliver(moves: section),
                          },
                        );
                      },
                    )
                  : combosAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(child: AppLoader()),
                      ),
                      error: (final e, _) => SliverFillRemaining(
                        child: Center(child: Text('Error: $e')),
                      ),
                      data: (final rows) {
                        if (rows.isEmpty) {
                          return SliverFillRemaining(
                            child: _EmptyState(
                              hasSearch: searchQuery.isNotEmpty,
                              isCombo: true,
                            ),
                          );
                        }

                        final sort = ref.watch(librarySortProvider);
                        return librarySectionedSliver<LibraryRow>(
                          items: rows,
                          sort: sort,
                          viewMode: viewMode,
                          dateOf: (final r) => r.effectiveDate(sort),
                          sliverOf: (final section) {
                            // `LibraryRow` maps back to a `(combo, count,
                            // date)` triple at the sliver boundary. The date
                            // rides along because a combo's practiced date is
                            // `lastEntryAt`, which lives on the row and not on
                            // the combo — the sort alone cannot recover it
                            // downstream the way a move's can.
                            final combos = section
                                .map(
                                  (final r) => (
                                    r.combo,
                                    r.moveCount,
                                    r.effectiveDate(sort),
                                  ),
                                )
                                .toList();
                            return switch (viewMode) {
                              ViewMode.glance => _ComboGridSliver(
                                combos: combos,
                              ),
                              ViewMode.scan => _CombosContentSliver(
                                combos: combos,
                              ),
                              ViewMode.study => _ComboStudySliver(
                                combos: combos,
                              ),
                            };
                          },
                        );
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
                    child: const AppIconView(AppIcon.add, color: Colors.white),
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
    } on Object catch (error) {
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
  _captureVideoAttachment(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
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
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasRecovery
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconView(
                hasRecovery ? AppIcon.check : AppIcon.sync,
                color: hasRecovery
                    ? Theme.of(context).colorScheme.primary
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
                icon: AppIconView(
                  AppIcon.close,
                  color: colorScheme.onSurfaceVariant,
                ),
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
                icon: const AppIconView(AppIcon.video),
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
        ViewMode.glance => AppIcon.grid.resolve(context),
        ViewMode.scan => AppIcon.list.resolve(context),
        ViewMode.study => AppIcon.glance.resolve(context),
      },
      labelOf: (final m) => viewNames[m.name] ?? _defaultViewModeLabel(m),
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
      text: viewNames[mode.name] ?? _defaultViewModeLabel(mode),
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

// -- Library Sort Toggle -----------------------------------------------------

/// The library's ordering control. One row for both tabs — the sort is global
/// (design O2), so switching segments never silently re-orders the list.
///
/// Public (unlike the other two toggles) so it can be pumped on its own; the
/// screen it lives in reads live Drift streams, which flake widget tests.
class LibrarySortToggle extends ConsumerWidget {
  const LibrarySortToggle({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _PillToggleRow<LibrarySort>(
      items: LibrarySort.values,
      selected: ref.watch(librarySortProvider),
      iconOf: (final s) => switch (s) {
        LibrarySort.recentlyAdded => AppIcon.schedule.resolve(context),
        LibrarySort.recentlyFilmed => AppIcon.video.resolve(context),
        LibrarySort.recentlyPracticed => AppIcon.replay.resolve(context),
        LibrarySort.alphabetical => AppIcon.sort.resolve(context),
      },
      labelOf: (final s) => switch (s) {
        LibrarySort.recentlyAdded => l10n.librarySortAdded,
        LibrarySort.recentlyFilmed => l10n.librarySortFilmed,
        LibrarySort.recentlyPracticed => l10n.librarySortPracticed,
        LibrarySort.alphabetical => l10n.librarySortAlphabetical,
      },
      onSelected: (final s) {
        HapticFeedback.selectionClick();
        unawaited(ref.read(librarySortProvider.notifier).set(s));
      },
    );
  }
}

/// Discloses that a filmed-date sort is a fallback on the combo tab.
///
/// A combo has no capture date, so [ComboLibrarySort.effectiveDate] resolves
/// `recentlyFilmed` to `createdAt` (design D2). The sort is global (O2), so the
/// user can arrive here without having chosen it for this tab — silently
/// showing an added-date order under a "Filmed" pill would be a lie of
/// omission. Renders nothing for every other sort/segment pair.
class LibraryFilmedFallbackNotice extends ConsumerWidget {
  const LibraryFilmedFallbackNotice({
    required this.sort,
    required this.segment,
    super.key,
  });

  final LibrarySort sort;
  final ArsenalSegment segment;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (sort != LibrarySort.recentlyFilmed ||
        segment != ArsenalSegment.combos) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppIconView(
            AppIcon.info,
            size: AppSpacing.md,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppLocalizations.of(context).libraryFilmedFallbackForCombos(
                ref.watch(entityNamesProvider).comboPlural,
              ),
              style: AppTypography.caption.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A month divider in the library feed.
///
/// The near past reads relatively ("This month"), everything else absolutely
/// ("June 2026") — design D3. Uppercasing matches the section-header idiom the
/// combos screen already uses; the ARB strings stay sentence case so a
/// translator is never handed a shouted phrase to translate.
class LibraryMonthHeader extends StatelessWidget {
  const LibraryMonthHeader({
    required this.year,
    required this.month,
    this.now,
    super.key,
  });

  final int year;
  final int month;

  /// Injectable so a test can pin the relative/absolute boundary instead of
  /// racing the wall clock.
  final DateTime? now;

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (libraryMonthLabel(
      year: year,
      month: month,
      now: now ?? DateTime.now(),
    )) {
      LibraryMonthLabel.thisMonth => l10n.libraryMonthThis,
      LibraryMonthLabel.lastMonth => l10n.libraryMonthLast,
      LibraryMonthLabel.absolute => DateFormat.yMMMM(
        Localizations.localeOf(context).toString(),
      ).format(DateTime(year, month)),
    };

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.md,
          AppSpacing.screenEdge,
          AppSpacing.xs,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.sectionHeader.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

/// Wraps a feed sliver in month sections when the active sort and view mode
/// call for them (design D3), and returns it untouched when they don't.
///
/// Grouping is a projection of a date ordering, so A–Z never groups; `study`
/// never groups either, because one card fills the viewport and a header
/// between cards is a scroll interruption with no scanning benefit. [sliverOf]
/// is the caller's existing per-mode builder, applied per section, so grid
/// headers fall out as full-width rows without a second grid layout.
Widget librarySectionedSliver<T>({
  required final List<T> items,
  required final LibrarySort sort,
  required final ViewMode viewMode,
  required final DateTime Function(T item) dateOf,
  required final Widget Function(List<T> section) sliverOf,
  final DateTime? now,
}) {
  if (!libraryGroupsByMonth(sort) || viewMode == ViewMode.study) {
    return sliverOf(items);
  }

  final sections = libraryMonthSections(items, dateOf);
  return SliverMainAxisGroup(
    slivers: [
      for (final section in sections) ...[
        LibraryMonthHeader(year: section.year, month: section.month, now: now),
        sliverOf(section.items),
      ],
    ],
  );
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
        ArsenalSegment.moves => AppIcon.move.resolve(context),
        ArsenalSegment.combos => AppIcon.combo.resolve(context),
      },
      labelOf: (final s) => switch (s) {
        ArsenalSegment.moves => ref.watch(entityNamesProvider).movePlural,
        ArsenalSegment.combos => ref.watch(entityNamesProvider).comboPlural,
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
                          // Flexible: four pills (the sort row) do not fit a
                          // narrow screen at full label width; two and three
                          // still lay out unchanged.
                          Flexible(
                            child: Text(
                              labelOf(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: selected == item
                                    ? Colors.white
                                    : colorScheme.onSurface,
                                fontWeight: selected == item
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
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
            isCombo
                ? AppIcon.combo.resolve(context)
                : AppIcon.move.resolve(context),
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
  const _MoveListSliver({required this.moves, required this.sort});

  final List<Move> moves;

  /// A move's date line follows the active sort, and a move can resolve it
  /// from the sort alone — unlike a combo, whose practiced date lives on the
  /// `LibraryRow` the sliver boundary already dropped.
  final LibrarySort sort;

  @override
  Widget build(final BuildContext context) {
    return _sliverStaggeredList(
      itemCount: moves.length,
      builder: (final index) => _MoveRow(
        move: moves[index],
        date: moves[index].effectiveDate(sort),
        index: index,
      ),
    );
  }
}

// -- Grid View ---------------------------------------------------------------

class _MoveGridSliver extends StatelessWidget {
  const _MoveGridSliver({required this.moves, required this.sort});

  final List<Move> moves;

  final LibrarySort sort;

  @override
  Widget build(final BuildContext context) {
    return _sliverArsenalGrid(
      itemCount: moves.length,
      builder: (final index) => _MoveGridCell(
        move: moves[index],
        date: moves[index].effectiveDate(sort),
      ),
    );
  }
}
