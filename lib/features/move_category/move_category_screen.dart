import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';
import '../../core/services/categories_service.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/state_pill.dart';
import '../../core/models/learning_state.dart';

class MoveCategoryScreen extends ConsumerWidget {
  const MoveCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final movesAsync = ref.watch(_allMovesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final moves = movesAsync.valueOrNull ?? const <Move>[];

    final categoryNames = categories.map((c) => c.name).toSet();
    final categoryCounts = <String, int>{};
    int uncategorizedCount = 0;

    for (final move in moves) {
      if (categoryNames.contains(move.category)) {
        categoryCounts[move.category] = (categoryCounts[move.category] ?? 0) + 1;
      } else {
        uncategorizedCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'moves-back',
          label: 'Back',
          button: true,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: colorScheme.secondary, size: 20),
                  Text(
                    'Back',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Moves'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        children: [
          Semantics(header: true, child: Text('Categories', style: AppTypography.titleLarge.copyWith(color: colorScheme.onSurface))),
          const SizedBox(height: AppSpacing.lg),
          for (final cat in categories)
            _CategoryTile(
              category: cat,
              count: categoryCounts[cat.name] ?? 0,
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
            count: uncategorizedCount,
            onTap: () => context.push('/breakdex/moves/uncategorized'),
          ),
        ],
      ),
    );
  }
}

final _allMovesProvider = StreamProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).watchAll();
});

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.count, required this.onTap});

  final Category category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(category.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
              ),
              Text(
                '$count',
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
      (m) => m.name == value,
      orElse: () => CategoryNavMode.scrollIndex,
    );
  }

  Future<void> set(CategoryNavMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

class MoveCategoryDetailScreen extends ConsumerWidget {
  const MoveCategoryDetailScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movesAsync = ref.watch(_allMovesProvider);
    final navMode = ref.watch(_categoryNavModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final allMoves = movesAsync.valueOrNull ?? const <Move>[];
    final categories = ref.watch(categoriesProvider);
    final categoryNames = categories.map((c) => c.name).toSet();

    final filtered = categoryName == 'uncategorized'
        ? allMoves
            .where(
              (m) => !categoryNames.contains(m.category),
            )
            .toList()
        : allMoves.where((m) => m.category == categoryName).toList();

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'category-back',
          label: 'Back',
          button: true,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                  Text(
                    'Back',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                        onTap: (move) =>
                            context.push('/breakdex/move/${move.id}'),
                      ),
                    CategoryNavMode.search => _SearchBarView(
                        moves: filtered,
                        categoryName: categoryName,
                        onTap: (move) =>
                            context.push('/breakdex/move/${move.id}'),
                      ),
                    CategoryNavMode.filterChips => _FilterChipsView(
                        moves: filtered,
                        onTap: (move) =>
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                          const SizedBox(width: 6),
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
          ],
        ],
      ),
    );
  }
}

// -- Solution 1: Alphabetical scroll index ------------------------------------

class _ScrollIndexView extends StatefulWidget {
  const _ScrollIndexView({required this.moves, required this.onTap});

  final List<Move> moves;
  final void Function(Move) onTap;

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
    _letters = _grouped.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    for (final letter in _letters) {
      _letterHeaderKeys[letter] = GlobalKey();
    }
  }

  Map<String, List<Move>> _groupByLetter(List<Move> moves) {
    final map = <String, List<Move>>{};
    for (final move in moves) {
      final first = move.name.isNotEmpty ? move.name[0].toUpperCase() : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
      map.putIfAbsent(letter, () => []).add(move);
    }
    return map;
  }

  void _scrollToLetter(String letter) {
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
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.xs,
            32,
            AppSpacing.screenEdge,
          ),
          itemCount: flatItems.length,
          itemBuilder: (context, index) {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final letterHeight = constraints.maxHeight / letters.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) =>
              _resolveLetter(d.localPosition.dy, letterHeight),
          onVerticalDragUpdate: (d) =>
              _resolveLetter(d.localPosition.dy, letterHeight),
          onVerticalDragEnd: (_) => onDragEnd(),
          child: SizedBox(
            width: 24,
            child: Column(
              children: letters.map((l) {
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

  void _resolveLetter(double localY, double letterHeight) {
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
  });

  final List<Move> moves;
  final String categoryName;
  final void Function(Move) onTap;

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

  void _onChanged(String value) {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _query.isEmpty
        ? widget.moves
        : widget.moves
            .where(
              (m) => m.name.toLowerCase().contains(_query.toLowerCase()),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
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
  const _FilterChipsView({required this.moves, required this.onTap});

  final List<Move> moves;
  final void Function(Move) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStates = ref.watch(_filterLearningStatesProvider);
    final sortAscending = ref.watch(_filterSortOrderProvider);
    final colorScheme = Theme.of(context).colorScheme;

    var filtered = activeStates.isEmpty
        ? moves
        : moves
            .where((m) => activeStates.contains(m.learningState))
            .toList();

    filtered.sort(
      (a, b) => sortAscending
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenEdge,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
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

  void _toggleState(WidgetRef ref, String state) {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              const Padding(
                padding: EdgeInsets.only(right: 6),
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

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move, required this.state, required this.onTap});

  final Move move;
  final LearningState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(move.name, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    if (move.originalVideoName != null) ...[
                      const SizedBox(height: 2),
                      Text(move.originalVideoName!, style: AppTypography.caption.copyWith(color: colorScheme.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
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
