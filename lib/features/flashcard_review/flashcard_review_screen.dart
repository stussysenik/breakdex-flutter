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
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/models/reviewable_item.dart';
import '../../core/providers.dart';
import 'providers/deck_providers.dart';
import 'providers/review_providers.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/mastery_prescreen.dart';
import 'widgets/review_card.dart';
import 'widgets/review_dashboard.dart';
import 'widgets/schedule_review_screen.dart';
import 'widgets/state_picker_sheet.dart';
import '../../shared/widgets/video_picker_sheet.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen> {
  int _currentIndex = 0;
  bool _completed = false;
  List<Move> _moves = [];
  bool _initialized = false;
  PageController? _pageController;

  // Card exit animation state — scale + fade before page transition
  double _cardScale = 1.0;
  double _cardOpacity = 1.0;
  bool _animatingExit = false;

  // Flashcard reveal state: true = see move/video/buttons, false = hidden
  bool _isRevealed = false;

  // Shake-to-skip: accelerometer subscription + debounce
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShakeTime = DateTime(2000);
  static const _shakeThreshold = 17.0;
  static const _shakeCooldown = Duration(milliseconds: 800);

  @override
  void dispose() {
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
    _moves = [];
    _initialized = false;
    _isRevealed = false;
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
    if (mode == ReviewMode.schedule) {
      _endSession();
      return;
    }

    setState(_resetSessionState);
    ref.read(reviewSessionActiveProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewMode = ref.watch(reviewModeProvider);
    final sessionActive = ref.watch(reviewSessionActiveProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Title + Battle button (always visible)
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
                  if (reviewMode == ReviewMode.session && sessionActive)
                    TextButton(
                      onPressed: _endSession,
                      child: const Text('End'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
              ),
              child: SegmentedButton<ReviewMode>(
                segments: const [
                  ButtonSegment<ReviewMode>(
                    value: ReviewMode.session,
                    icon: Icon(Icons.style_outlined, size: 18),
                    label: Text('Session'),
                  ),
                  ButtonSegment<ReviewMode>(
                    value: ReviewMode.schedule,
                    icon: Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text('Schedule'),
                  ),
                ],
                selected: {reviewMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    _setReviewMode(selection.first),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Expanded(
              child: switch (reviewMode) {
                ReviewMode.schedule => const ScheduleReviewScreen(),
                ReviewMode.session when sessionActive =>
                  _buildFlashcardSession(),
                ReviewMode.session => const MasteryPrescreen(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardSession() {
    final movesAsync = ref.watch(filteredReviewMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Reset session when filters change (provider re-fetches)
    ref.listen(filteredReviewMovesProvider, (prev, next) {
      if (next is AsyncData<List<Move>> && prev != next) {
        setState(() {
          _moves = List.from(next.value);
          _currentIndex = 0;
          _completed = false;
          _initialized = true;
          _initPageController();
        });
      }
    });

    return movesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (moves) {
        // First load — also start shake listener for the active session
        if (!_initialized) {
          _moves = List.from(moves);
          _initialized = true;
          _isRevealed = false;
          _initPageController();
          _startShakeListener();
        }

        return Column(
          children: [
            // Dashboard: filter chips + progress
            ReviewDashboard(
              currentIndex: _currentIndex,
              totalInSession: _moves.length,
            ),
            const SizedBox(height: AppSpacing.md),

            // Main content
            Expanded(
              child: _moves.isEmpty
                  ? _buildEmpty(colorScheme)
                  : _completed
                  ? _buildCompleted(colorScheme)
                  : _buildReviewContent(),
            ),
          ],
        );
      },
    );
  }

  /// PageView-based review content with true 60/30/10 viewport split.
  Widget _buildReviewContent() {
    final move = _moves[_currentIndex];
    final intervalsAsync = ref.watch(intervalPreviewProvider(move.id));
    final intervals = intervalsAsync.valueOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        // 65% for video, remaining for context band + buttons
        final videoHeight = (available * 0.65).clamp(180.0, 420.0);

        return Column(
          children: [
            // PageView for swipe navigation between moves.
            // Wrapped in animated scale/opacity for smooth card exit on rating.
            Expanded(
              child: AnimatedScale(
                scale: _cardScale,
                duration: AppMotion.moderate01,
                curve: AppMotion.productive,
                child: AnimatedOpacity(
                  opacity: _cardOpacity,
                  duration: AppMotion.moderate01,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _animatingExit
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: _moves.length,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentIndex = index;
                        _isRevealed = false;
                      });
                    },
                    itemBuilder: (context, index) {
                      final pageMove = _moves[index];
                      return GestureDetector(
                        onTap: () {
                          if (!_isRevealed && index == _currentIndex) {
                            HapticFeedback.mediumImpact();
                            setState(() => _isRevealed = true);
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! < -300) {
                            _showStatePicker(pageMove);
                          }
                        },
                        child: ReviewCard(
                          move: pageMove,
                          isRevealed: index == _currentIndex
                              ? _isRevealed
                              : false,
                          onStatePillTap: () => _showStatePicker(pageMove),
                          videoHeight: videoHeight,
                          onRepick: () => _repickVideo(pageMove, index),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Swipe hint
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRevealed ? Icons.swipe : Icons.touch_app,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isRevealed ? 'swipe to navigate' : 'tap to reveal',
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Rating buttons — natural height, no clamped SizedBox
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdge,
                vertical: AppSpacing.sm,
              ),
              child: _isRevealed
                  ? RatingButtonRow(
                      onRate: (rating) => _rate(move, rating),
                      intervalPreviews: intervals,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    final stateFilter = ref.watch(reviewStateFilterProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);
    final targetMoveIds = ref.watch(reviewSessionTargetMoveIdsProvider);
    final reviewSource = ref.watch(reviewSessionSourceProvider);
    final totalMoves = ref.watch(totalMoveCountProvider).valueOrNull ?? 0;

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

    if (totalMoves == 0) {
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
                backgroundColor: AppColors.accent,
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
        'No ${stateFilter.displayText.toLowerCase()} cards available',
      _ => 'No cards available for this session',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 80, color: AppColors.actionGood),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Great work!',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All ${_moves.length} moves reviewed',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resetSessionState();
              });
              refreshReviewSession(ref);
              _startShakeListener();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review Again'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _endSession,
            child: const Text('Back to Review'),
          ),
        ],
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

    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            videoPath: Value(result.localPath),
            originalVideoName: Value(result.originalFileName),
          ),
        );
    await videoService.replaceVideo(move.videoPath);

    setState(() {
      _moves[index] = Move(
        id: move.id,
        name: move.name,
        learningState: move.learningState,
        category: move.category,
        videoPath: result.localPath,
        originalVideoName: result.originalFileName,
        createdAt: move.createdAt,
      );
    });
  }

  Future<void> _showStatePicker(Move move) async {
    final currentState = LearningState.fromString(move.learningState);
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
          ),
        );

    setState(() {
      _moves[_currentIndex] = Move(
        id: move.id,
        name: move.name,
        learningState: newState.dbValue,
        category: move.category,
        videoPath: move.videoPath,
        originalVideoName: move.originalVideoName,
        createdAt: move.createdAt,
      );
    });
  }

  Future<void> _rate(Move move, ReviewRating rating) async {
    HapticFeedback.mediumImpact();

    // Legacy state transition
    final currentState = LearningState.fromString(move.learningState);
    final newState = currentState.applyRating(rating);

    await ref
        .read(moveRepositoryProvider)
        .update(
          MovesCompanion(
            id: Value(move.id),
            learningState: Value(newState.dbValue),
          ),
        );

    // FSRS scheduling — pass entityType for polymorphic support
    final fsrsResult = await ref
        .read(fsrsServiceProvider)
        .processReview(move.id, rating, entityType: 'move');

    await ref
        .read(reviewRepositoryProvider)
        .insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: rating.dbValue,
            reviewType: ReviewType.move.dbValue,
            moveId: Value(move.id),
            fsrsPreState: Value(fsrsResult.preState),
            fsrsPostState: Value(fsrsResult.postState),
          ),
        );

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
    if (_currentIndex < _moves.length - 1) {
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
}
