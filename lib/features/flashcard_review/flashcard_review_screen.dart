import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/theme.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import '../../core/services/video_path_resolver.dart';
import '../../shared/widgets/primary_button.dart';
import 'providers/deck_providers.dart';
import 'providers/review_providers.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/mastery_prescreen.dart';
import 'widgets/review_card.dart';
import 'widgets/state_picker_sheet.dart';
import '../../shared/widgets/video_picker_sheet.dart';
import '../../shared/widgets/app_segmented_control.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _completed = false;
  List<ReviewSessionItem> _items = [];
  bool _initialized = false;
  PageController? _pageController;

  // Card exit animation state — scale + fade before page transition
  double _cardScale = 1.0;
  double _cardOpacity = 1.0;
  bool _animatingExit = false;

  // Breathing animation — subtle 0.6% scale oscillation when idle.
  // Signals "alive" state, draws attention to the card, invites interaction.
  late final AnimationController _breathController;

  // Shake-to-skip: accelerometer subscription + debounce
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShakeTime = DateTime(2000);
  static const _shakeThreshold = 17.0;
  static const _shakeCooldown = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _stopShakeListener();
    _pageController?.dispose();
    super.dispose();
  }

  void _initPageController() {
    _pageController?.dispose();
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _resetSessionState() {
    _stopShakeListener();
    _pageController?.dispose();
    _pageController = null;
    _currentIndex = 0;
    _completed = false;
    _items = [];
    _initialized = false;
    _cardScale = 1.0;
    _cardOpacity = 1.0;
    _animatingExit = false;
  }

  void _endSession({bool clearTarget = true}) {
    setState(_resetSessionState);
    if (clearTarget) {
      ref.read(reviewSessionTargetMoveIdsProvider.notifier).state = null;
    }
    ref.read(reviewSessionActiveProvider.notifier).state = false;
  }

  void _setReviewMode(ReviewMode mode) {
    ref.read(reviewModeProvider.notifier).set(mode);
    setState(_resetSessionState);
    ref.read(reviewSessionActiveProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewMode = ref.watch(reviewModeProvider);
    final sessionActive = ref.watch(reviewSessionActiveProvider);

    // When session is active, the immersive card fills the screen —
    // header and segment control are hidden. End button lives in the
    // card's top overlay instead.
    if (sessionActive) {
      return Scaffold(
        body: SafeArea(child: _buildFlashcardSession()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Title (no End button — it's in the card overlay now)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Review',
                      style: AppTypography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: AppSegmentedControl<ReviewMode>(
                items: const [
                  AppSegmentedControlItem(
                    value: ReviewMode.review,
                    icon: Icons.grid_view_rounded,
                    label: 'Review',
                  ),
                  AppSegmentedControlItem(
                    value: ReviewMode.deck,
                    icon: Icons.layers_rounded,
                    label: 'Deck',
                  ),
                ],
                selectedValue: reviewMode,
                onChanged: _setReviewMode,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Expanded(
              child: MasteryPrescreen(
                source: reviewMode == ReviewMode.deck
                    ? ReviewSessionSource.deck
                    : ReviewSessionSource.stateBased,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardSession() {
    final itemsAsync = ref.watch(filteredReviewSessionItemsProvider);

    // Reset session when filters change (provider re-fetches)
    ref.listen(filteredReviewSessionItemsProvider, (prev, next) {
      if (next is AsyncData<List<ReviewSessionItem>> && prev != next) {
        setState(() {
          _items = List.from(next.value);
          _currentIndex = 0;
          _completed = false;
          _initialized = true;
          _initPageController();
        });
      }
    });

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        // First load — also start shake listener for the active session
        if (!_initialized) {
          _items = List.from(items);
          _initialized = true;
          _initPageController();
          _startShakeListener();
        }

        final colorScheme = Theme.of(context).colorScheme;

        // No dashboard — progress dots are inside the immersive card overlay
        if (_items.isEmpty) return _buildEmpty(colorScheme);
        if (_completed) return _buildCompleted(colorScheme);
        return _buildReviewContent();
      },
    );
  }

  /// Immersive review layout: card fills ~70%, compact rating strip ~30%.
  Widget _buildReviewContent() {
    final item = _items[_currentIndex];
    final intervalsAsync = ref.watch(
      intervalPreviewProvider((
        entityId: item.entityId,
        entityType: item.entityType,
      )),
    );
    final intervals = intervalsAsync.valueOrNull;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Immersive card fills available space
        Expanded(
          // Breathing animation: 0.6% scale oscillation when idle.
          child: AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final reduceMotion =
                  MediaQuery.of(context).disableAnimations;
              final breathScale = reduceMotion
                  ? 1.0
                  : 1.0 +
                      (0.006 *
                          Curves.easeInOut
                              .transform(_breathController.value));
              return Transform.scale(
                scale: breathScale * _cardScale,
                child: child,
              );
            },
            child: AnimatedOpacity(
              opacity: _cardOpacity,
              duration: AppMotion.moderate01,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  physics: _animatingExit
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final pageItem = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Semantics(
                        identifier: 'review-card-${pageItem.entityId}',
                        label: 'Review card: ${pageItem.displayName}',
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null &&
                                details.primaryVelocity! < -300 &&
                                pageItem.isMove &&
                                pageItem.move != null) {
                              _showStatePicker(pageItem.move!, index);
                            }
                          },
                          child: ReviewCard(
                            key: ValueKey(
                              'review-card-${pageItem.entityType}-${pageItem.entityId}',
                            ),
                            title: pageItem.displayName,
                            state: pageItem.state,
                            category: pageItem.category,
                            videoPath: pageItem.videoPath,
                            originalVideoName: pageItem.originalVideoName,
                            canEditState: pageItem.isMove,
                            combo: pageItem.combo,
                            currentIndex: _currentIndex,
                            totalItems: _items.length,
                            onEnd: _endSession,
                            onStatePillTap: () {
                              if (pageItem.isMove &&
                                  pageItem.move != null) {
                                _showStatePicker(pageItem.move!, index);
                              }
                            },
                            onRepick:
                                pageItem.isMove && pageItem.move != null
                                ? () =>
                                      _repickVideo(pageItem.move!, index)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Slim compact rating strip — no panel wrapper
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.sm,
            AppSpacing.screenEdge,
            AppSpacing.sm + bottomPadding,
          ),
          child: RatingButtonRow(
            compact: true,
            onRate: (rating) => _rateItem(item, rating),
            intervalPreviews: intervals,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    final stateFilter = ref.watch(reviewStateFilterProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);
    final targetMoveIds = ref.watch(reviewSessionTargetMoveIdsProvider);
    final reviewSource = ref.watch(reviewSessionSourceProvider);
    final entityKind = ref.watch(reviewEntityKindProvider);
    final totalReviewable =
        ref.watch(totalReviewableCountProvider).valueOrNull ?? 0;

    if (targetMoveIds != null && targetMoveIds.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_circle_outline,
              size: 64,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'That move is no longer available',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: _endSession, child: const Text('Back')),
          ],
        ),
      );
    }

    if (totalReviewable == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_add_outlined,
              size: 64,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your breakdex is empty',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add moves from the Arsenal tab to start reviewing',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.go('/arsenal'),
              icon: const Icon(Icons.add),
              label: const Text('Add a Move'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final message = switch (reviewSource) {
      ReviewSessionSource.deck =>
        selectedDeck == null
            ? 'Pick a deck to start a review session'
            : '"${selectedDeck.name}" has no matching cards',
      ReviewSessionSource.stateBased when stateFilter != null =>
        'No ${stateFilter.displayText.toLowerCase()} ${entityKind == ReviewEntityKind.moves ? 'move cards' : 'combo cards'} available',
      ReviewSessionSource.stateBased =>
        'No ${entityKind == ReviewEntityKind.moves ? 'move cards' : 'combo cards'} available for this session',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _endSession,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: AppSurfaces.panel(
              context,
              raised: true,
              focused: true,
              radius: AppRadius.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.actionGood.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: AppColors.actionGood,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Great work!',
                  style: AppTypography.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'All ${_items.length} cards reviewed',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Review Again',
                  onPressed: () {
                    setState(() {
                      _resetSessionState();
                    });
                    refreshReviewSession(ref);
                    _startShakeListener();
                  },
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _endSession,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                    textStyle: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Back to Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((event) {
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final now = DateTime.now();
          if (magnitude > _shakeThreshold &&
              now.difference(_lastShakeTime) > _shakeCooldown) {
            _lastShakeTime = now;
            HapticFeedback.heavyImpact();
            _skip();
          }
        });
  }

  void _stopShakeListener() {
    _shakeSubscription?.cancel();
    _shakeSubscription = null;
  }

  Future<void> _repickVideo(Move move, int index) async {
    final result = await VideoPickerSheet.show(
      context,
      previousVideoName: move.originalVideoName,
    );
    if (result == null) return;

    final videoService = ref.read(videoServiceProvider);

    final relativePath = VideoPathResolver.toRelative(result.localPath);
    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: Value(relativePath),
            originalVideoName: Value(result.originalFileName),
          ),
        );
    await videoService.replaceVideo(move.resolvedVideoPath);

    setState(() {
      _items[index] = ReviewSessionItem(
        entityId: move.id,
        entityType: 'move',
        displayName: move.name,
        state: _items[index].state,
        category: move.category,
        videoPath: VideoPathResolver.toAbsolute(relativePath),
        originalVideoName: result.originalFileName,
        move: move.copyWith(
          videoPath: Value(relativePath),
          originalVideoName: Value(result.originalFileName),
        ),
      );
    });
  }

  Future<void> _showStatePicker(Move move, int index) async {
    final currentState = _items[index].state;
    final newState = await StatePickerSheet.show(
      context,
      currentState: currentState,
      moveName: move.name,
    );

    if (newState == null || newState == currentState) return;

    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            learningState: Value(newState.dbValue),
          ),
        );

    await ref
        .read(reviewRepositoryProvider)
        .insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: newState.dbValue,
            reviewType: ReviewType.manual.dbValue,
            moveId: Value(move.id),
            entityIdSnapshot: Value(move.id),
            entityType: const Value('move'),
            entityDisplayName: Value(move.name),
            entityCategory: Value(move.category),
          ),
        );

    setState(() {
      _items[index] = ReviewSessionItem(
        entityId: move.id,
        entityType: 'move',
        displayName: move.name,
        state: newState,
        category: move.category,
        videoPath: move.resolvedVideoPath,
        originalVideoName: move.originalVideoName,
        move: move.copyWith(learningState: newState.dbValue),
      );
    });
  }

  Future<void> _rateItem(ReviewSessionItem item, ReviewRating rating) async {
    HapticFeedback.mediumImpact();

    if (item.isMove && item.move != null) {
      final move = item.move!;
      final newState = item.state.applyRating(rating);

      await ref
          .read(moveRepositoryProvider)
          .update(
            MovesCompanion(
              id: Value(move.id),
              learningState: Value(newState.dbValue),
            ),
          );

      final fsrsResult = await ref
          .read(fsrsServiceProvider)
          .processReview(move.id, rating, entityType: 'move');
      await ref
          .read(syncDaoProvider)
          .logChange(entityId: move.id, table: 'fsrs_cards', action: 'update');

      await ref
          .read(reviewRepositoryProvider)
          .insert(
            ReviewsCompanion.insert(
              id: const Uuid().v4(),
              rating: rating.dbValue,
              reviewType: ReviewType.move.dbValue,
              moveId: Value(move.id),
              entityIdSnapshot: Value(move.id),
              entityType: const Value('move'),
              entityDisplayName: Value(move.name),
              entityCategory: Value(move.category),
              fsrsPreState: Value(fsrsResult.preState),
              fsrsPostState: Value(fsrsResult.postState),
            ),
          );

      setState(() {
        _items[_currentIndex] = ReviewSessionItem(
          entityId: move.id,
          entityType: 'move',
          displayName: move.name,
          state: _fsrsStateToLearningState(fsrsResult.postState),
          category: move.category,
          videoPath: move.resolvedVideoPath,
          originalVideoName: move.originalVideoName,
          move: move.copyWith(
            learningState: _fsrsStateToLearningState(
              fsrsResult.postState,
            ).dbValue,
          ),
        );
      });
    } else if (item.isCombo && item.combo != null) {
      final combo = item.combo!;
      final fsrsResult = await ref
          .read(fsrsServiceProvider)
          .processReview(combo.id, rating, entityType: 'combo');
      await ref
          .read(syncDaoProvider)
          .logChange(entityId: combo.id, table: 'fsrs_cards', action: 'update');

      await ref
          .read(reviewRepositoryProvider)
          .insert(
            ReviewsCompanion.insert(
              id: const Uuid().v4(),
              rating: rating.dbValue,
              reviewType: ReviewType.combo.dbValue,
              comboId: Value(combo.id),
              entityIdSnapshot: Value(combo.id),
              entityType: const Value('combo'),
              entityDisplayName: Value(combo.name),
              entityCategory: const Value('combo'),
              fsrsPreState: Value(fsrsResult.preState),
              fsrsPostState: Value(fsrsResult.postState),
            ),
          );

      setState(() {
        _items[_currentIndex] = ReviewSessionItem(
          entityId: combo.id,
          entityType: 'combo',
          displayName: combo.name,
          state: _fsrsStateToLearningState(fsrsResult.postState),
          category: 'combo',
          videoPath: combo.resolvedActiveVideoPath,
          combo: combo,
        );
      });
    }

    _animatedAdvance();
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _advance();
  }

  /// Plays a scale-down + fade exit animation, then advances to the next card.
  /// The easeOutBack overshoot on the page transition gives a fluid "pop" feel.
  void _animatedAdvance() {
    if (_animatingExit) return;
    setState(() {
      _animatingExit = true;
      _cardScale = 0.95;
      _cardOpacity = 0.8;
    });

    Future.delayed(AppMotion.moderate01, () {
      if (!mounted) return;
      _advance();
      setState(() {
        _cardScale = 1.0;
        _cardOpacity = 1.0;
        _animatingExit = false;
      });
    });
  }

  void _advance() {
    if (_currentIndex < _items.length - 1) {
      final nextIndex = _currentIndex + 1;
      _pageController?.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
      );
      setState(() => _currentIndex = nextIndex);
    } else {
      _stopShakeListener();
      setState(() => _completed = true);
    }
  }

  LearningState _fsrsStateToLearningState(int fsrsState) => switch (fsrsState) {
    2 => LearningState.mastery,
    1 || 3 => LearningState.learning,
    _ => LearningState.newState,
  };
}
