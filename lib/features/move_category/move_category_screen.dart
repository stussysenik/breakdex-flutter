// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/services/entity_names_service.dart';
import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/shared/widgets/back_leading.dart';
import 'package:breakdex/core/design/theme.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/categories_service.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/shared/widgets/pressable.dart';
import 'package:breakdex/shared/widgets/state_pill.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/models/library_category_activity.dart';
import 'package:breakdex/core/models/library_sort.dart';
import 'package:breakdex/l10n/gen/app_localizations.dart';
import 'package:breakdex/features/move_list/move_list_screen.dart' show librarySortProvider;
import 'package:breakdex/features/move_list/widgets/library_date_line_format.dart';

class MoveCategoryScreen extends ConsumerWidget {
  const MoveCategoryScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final movesAsync = ref.watch(_allMovesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final moves = movesAsync.valueOrNull ?? const <Move>[];

    final activities = libraryCategoryActivities(
      moves: moves,
      categoryNames: categories.map((final c) => c.name).toSet(),
    );

    final byName = {for (final c in categories) c.name: c};
    final ordered = [
      for (final name in categoryNamesByRecency(
        orderedNames: [for (final c in categories) c.name],
        byCategory: activities.byCategory,
      ))
        byName[name]!,
    ];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: BackLeading.slotWidth,
        leading: BackLeading(
          identifier: 'moves-back',
          onTap: () => context.pop(),
        ),
        title: Text(ref.watch(entityNamesProvider).movePlural),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          Semantics(header: true, child: Text('Categories', style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface))),
          const SizedBox(height: AppSpacing.lg),
          for (final cat in ordered)
            _CategoryTile(
              category: cat,
              activity: activities.byCategory[cat.name] ?? LibraryCategoryActivity.empty,
              onTap: () => context.push('/breakdex/moves/${Uri.encodeComponent(cat.name)}'),
            ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(header: true, child: Text('Uncategorized', style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700))),
          const SizedBox(height: AppSpacing.sm),
          _CategoryTile(
            category: Category(
              name: 'Uncategorized',
              colorValue: colorScheme.secondary.toARGB32(),
              isDefault: true,
            ),
            activity: activities.uncategorized,
            onTap: () => context.push('/breakdex/moves/uncategorized'),
          ),
        ],
      ),
    );
  }
}

final _allMovesProvider = StreamProvider<List<Move>>((final ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.activity, required this.onTap});

  final Category category;
  final LibraryCategoryActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppSurfaces.panel(context, radius: AppRadius.md),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    // The tile the grid is sorted by discloses the date it is
                    // sorted on; an empty category says so rather than showing
                    // a blank where every sibling has a line.
                    if (activity.lastAddedAt case final lastAddedAt?)
                      LibraryDateLabel(date: lastAddedAt)
                    else
                      Text(
                        AppLocalizations.of(context).libraryCategoryEmpty,
                        style: AppTypography.caption.copyWith(color: colorScheme.secondary),
                      ),
                  ],
                ),
              ),
              Text(
                '${activity.count}',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.chevron_right_rounded, color: colorScheme.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

enum CategoryNavMode { scrollIndex, search, filterChips }

final _categoryNavModeProvider =
    NotifierProvider<_CategoryNavModeNotifier, CategoryNavMode>(
      _CategoryNavModeNotifier.new,
    );

class _CategoryNavModeNotifier extends Notifier<CategoryNavMode> {
  static const _key = 'category_nav_mode';

  @override
  CategoryNavMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key);
    return CategoryNavMode.values.firstWhere(
      (final m) => m.name == value,
      orElse: () => CategoryNavMode.scrollIndex,
    );
  }

  Future<void> set(final CategoryNavMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

class MoveCategoryDetailScreen extends ConsumerWidget {
  const MoveCategoryDetailScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final movesAsync = ref.watch(_allMovesProvider);
    final navMode = ref.watch(_categoryNavModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final allMoves = movesAsync.valueOrNull ?? const <Move>[];
    final categories = ref.watch(categoriesProvider);
    final categoryNames = categories.map((final c) => c.name).toSet();

    final filtered = categoryName == 'uncategorized'
        ? allMoves
            .where(
              (final m) => !categoryNames.contains(m.category),
            )
            .toList()
        : allMoves.where((final m) => m.category == categoryName).toList();

    final bottomPadding = kBottomNavigationBarHeight +
        MediaQuery.of(context).padding.bottom +
        AppSpacing.xxl;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: BackLeading.slotWidth,
        leading: BackLeading(
          identifier: 'category-back',
          onTap: () => context.pop(),
        ),
        title: Text(categoryName == 'uncategorized' ? 'Uncategorized' : categoryName),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                    color: colorScheme.secondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No moves in ${categoryName == 'uncategorized' ? 'Uncategorized' : categoryName}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _NavModeToggle(navMode: navMode),
                Expanded(
                  child: switch (navMode) {
                    CategoryNavMode.scrollIndex => _ScrollIndexView(
                        moves: filtered,
                        bottomPadding: bottomPadding,
                        onTap: (final move) =>
                            context.push('/breakdex/move/${move.id}'),
                      ),
                    CategoryNavMode.search => _SearchBarView(
                        moves: filtered,
                        categoryName: categoryName,
                        bottomPadding: bottomPadding,
                        onTap: (final move) =>
                            context.push('/breakdex/move/${move.id}'),
                      ),
                    CategoryNavMode.filterChips => _FilterChipsView(
                        moves: filtered,
                        bottomPadding: bottomPadding,
                        onTap: (final move) =>
                            context.push('/breakdex/move/${move.id}'),
                      ),
                  },
                ),
              ],
            ),
    );
  }
}

class _NavModeToggle extends ConsumerWidget {
  const _NavModeToggle({required this.navMode});

  final CategoryNavMode navMode;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.xs,
        AppSpacing.screenEdge,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final mode in CategoryNavMode.values) ...[
            if (mode != CategoryNavMode.values.first)
              const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                button: true,
                selected: navMode == mode,
                label: switch (mode) {
                  CategoryNavMode.scrollIndex => 'Letter index',
                  CategoryNavMode.search => 'Search',
                  CategoryNavMode.filterChips => 'Filter',
                },
                child: GestureDetector(
                  onTap: () {
                    if (navMode != mode) {
                      HapticFeedback.selectionClick();
                      ref.read(_categoryNavModeProvider.notifier).set(mode);
                    }
                  },
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: navMode == mode
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                switch (mode) {
                                  CategoryNavMode.scrollIndex =>
                                    Icons.sort_by_alpha_rounded,
                                  CategoryNavMode.search => Icons.search_rounded,
                                  CategoryNavMode.filterChips =>
                                    Icons.filter_list_rounded,
                                },
                                size: 16,
                                color: navMode == mode
                                    ? Colors.white
                                    : colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                switch (mode) {
                                  CategoryNavMode.scrollIndex => 'Index',
                                  CategoryNavMode.search => 'Search',
                                  CategoryNavMode.filterChips => 'Filter',
                                },
                                style: AppTypography.caption.copyWith(
                                  color: navMode == mode
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                  fontWeight: navMode == mode
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- Solution 1: Alphabetical scroll index ------------------------------------

class _ScrollIndexView extends StatefulWidget {
  const _ScrollIndexView({
    required this.moves,
    required this.onTap,
    required this.bottomPadding,
  });

  final List<Move> moves;
  final void Function(Move) onTap;
  final double bottomPadding;

  @override
  State<_ScrollIndexView> createState() => _ScrollIndexViewState();
}

class _ScrollIndexViewState extends State<_ScrollIndexView> {
  final _scrollController = ScrollController();
  final _letterHeaderKeys = <String, GlobalKey>{};
  String? _activeLetter;

  late final Map<String, List<Move>> _grouped;
  late final List<String> _letters;

  @override
  void initState() {
    super.initState();
    _grouped = _groupByLetter(widget.moves);
    _letters = _grouped.keys.toList()..sort((final a, final b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    for (final letter in _letters) {
      _letterHeaderKeys[letter] = GlobalKey();
    }
  }

  Map<String, List<Move>> _groupByLetter(final List<Move> moves) {
    final map = <String, List<Move>>{};
    for (final move in moves) {
      final first = move.name.isNotEmpty ? move.name[0].toUpperCase() : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
      map.putIfAbsent(letter, () => []).add(move);
    }
    return map;
  }

  void _scrollToLetter(final String letter) {
    setState(() => _activeLetter = letter);
    final key = _letterHeaderKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  void _clearActiveLetter() {
    if (_activeLetter != null) {
      setState(() => _activeLetter = null);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final flatItems = <dynamic>[];
    for (final letter in _letters) {
      flatItems.add(letter);
      flatItems.addAll(_grouped[letter]!);
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.xs,
            32,
            widget.bottomPadding,
          ),
          itemCount: flatItems.length,
          itemBuilder: (final context, final index) {
            final item = flatItems[index];
            if (item is String) {
              return Padding(
                key: _letterHeaderKeys[item],
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Text(
                  item,
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final move = item as Move;
            return _MoveRow(
              move: move,
              state: move.learningState.toLearningState(),
              onTap: () => widget.onTap(move),
            );
          },
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: _LetterStrip(
            letters: _letters,
            activeLetter: _activeLetter,
            onLetterChanged: _scrollToLetter,
            onDragEnd: _clearActiveLetter,
          ),
        ),
        if (_activeLetter != null)
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _activeLetter!,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LetterStrip extends StatelessWidget {
  const _LetterStrip({
    required this.letters,
    required this.activeLetter,
    required this.onLetterChanged,
    required this.onDragEnd,
  });

  final List<String> letters;
  final String? activeLetter;
  final void Function(String) onLetterChanged;
  final VoidCallback onDragEnd;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final letterHeight = constraints.maxHeight / letters.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (final d) =>
              _resolveLetter(d.localPosition.dy, letterHeight),
          onVerticalDragUpdate: (final d) =>
              _resolveLetter(d.localPosition.dy, letterHeight),
          onVerticalDragEnd: (_) => onDragEnd(),
          child: SizedBox(
            width: 24,
            child: Column(
              children: letters.map((final l) {
                final isActive = l == activeLetter;
                return SizedBox(
                  height: letterHeight,
                  child: Center(
                    child: Text(
                      l,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.secondary.withValues(alpha: 0.6),
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _resolveLetter(final double localY, final double letterHeight) {
    final index = (localY / letterHeight).floor().clamp(0, letters.length - 1);
    onLetterChanged(letters[index]);
  }
}

// -- Solution 2: Search bar ---------------------------------------------------

class _SearchBarView extends StatefulWidget {
  const _SearchBarView({
    required this.moves,
    required this.categoryName,
    required this.onTap,
    required this.bottomPadding,
  });

  final List<Move> moves;
  final String categoryName;
  final void Function(Move) onTap;
  final double bottomPadding;

  @override
  State<_SearchBarView> createState() => _SearchBarViewState();
}

class _SearchBarViewState extends State<_SearchBarView> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(final String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clear() {
    _controller.clear();
    if (mounted) setState(() => _query = '');
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _query.isEmpty
        ? widget.moves
        : widget.moves
            .where(
              (final m) => m.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.xs,
            AppSpacing.screenEdge,
            AppSpacing.sm,
          ),
          child: Semantics(
            label: 'Search ${widget.categoryName}',
            textField: true,
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search ${widget.categoryName}...',
                prefixIcon: Icon(Icons.search, color: colorScheme.secondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: _clear,
                      )
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'Type to search' : 'No results',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    0,
                    AppSpacing.screenEdge,
                    widget.bottomPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (final context, final index) {
                    final move = filtered[index];
                    return _MoveRow(
                      move: move,
                      state: move.learningState.toLearningState(),
                      onTap: () => widget.onTap(move),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// -- Solution 3: Filter chips + sort toggle -----------------------------------

final _filterLearningStatesProvider = StateProvider<Set<String>>(
  (_) => <String>{},
);

final _filterSortOrderProvider = StateProvider<bool>((_) => true);

class _FilterChipsView extends ConsumerWidget {
  const _FilterChipsView({
    required this.moves,
    required this.onTap,
    required this.bottomPadding,
  });

  final List<Move> moves;
  final void Function(Move) onTap;
  final double bottomPadding;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final activeStates = ref.watch(_filterLearningStatesProvider);
    final sortAscending = ref.watch(_filterSortOrderProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final filtered = activeStates.isEmpty
        ? moves
        : moves
            .where((final m) => activeStates.contains(m.learningState))
            .toList();

    filtered.sort(
      (final a, final b) => sortAscending
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'New',
                        active: activeStates.contains('NEW'),
                        activeColor: AppColors.stateNew,
                        onTap: () => _toggleState(ref, 'NEW'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'Learning',
                        active: activeStates.contains('LEARNING'),
                        activeColor: AppColors.stateLearning,
                        onTap: () => _toggleState(ref, 'LEARNING'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'Mastery',
                        active: activeStates.contains('MASTERY'),
                        activeColor: AppColors.stateMastery,
                        onTap: () => _toggleState(ref, 'MASTERY'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: sortAscending ? 'Sort A to Z' : 'Sort Z to A',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(_filterSortOrderProvider.notifier)
                        .state = !sortAscending;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      sortAscending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No moves match',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenEdge,
                    0,
                    AppSpacing.screenEdge,
                    bottomPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (final context, final index) {
                    final move = filtered[index];
                    return _MoveRow(
                      move: move,
                      state: move.learningState.toLearningState(),
                      onTap: () => onTap(move),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _toggleState(final WidgetRef ref, final String state) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(_filterLearningStatesProvider.notifier);
    final current = Set<String>.from(notifier.state);
    if (current.contains(state)) {
      current.remove(state);
    } else {
      current.add(state);
    }
    notifier.state = current;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: active ? Colors.white : colorScheme.onSurface,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends ConsumerWidget {
  const _MoveRow({required this.move, required this.state, required this.onTap});

  final Move move;
  final LearningState state;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sort = ref.watch(librarySortProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppSurfaces.panel(context, radius: AppRadius.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(move.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    // The subtitle used to be `originalVideoName` — a camera
                    // filename or a bare UUID, which tells the user nothing
                    // and violates design D4. It now shows the same date the
                    // active sort ordered by, captioned with the dimension it
                    // actually resolved to (never the requested one).
                    const SizedBox(height: 4),
                    LibraryDateLabel(
                      date: move.effectiveDate(sort),
                      source: move.effectiveDateSource(sort),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StatePill(state: state, showDisclosure: true),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  LearningState toLearningState() => switch (this) {
    'NEW' => LearningState.newState,
    'LEARNING' => LearningState.learning,
    'MASTERY' => LearningState.mastery,
    _ => LearningState.newState,
  };
}
