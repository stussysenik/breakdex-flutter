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
import 'providers/review_providers.dart';
import 'widgets/rating_button_row.dart';
import 'widgets/review_card.dart';
import 'widgets/review_dashboard.dart';
import 'widgets/state_picker_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
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
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: movesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (moves) {
            // First load
            if (!_initialized) {
              _moves = List.from(moves);
              _initialized = true;
            }

            return Column(
              children: [
                const SizedBox(height: AppSpacing.md),

                // Title + Battle button
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
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          icon: const Icon(Icons.bolt_rounded),
                          color: AppColors.accent,
                          tooltip: 'Battle Mode',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push('/battle');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

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
                          : NotificationListener<ScrollStartNotification>(
                              onNotification: (_) {
                                _collapseFilters();
                                return false;
                              },
                              child: _buildReviewContent(),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final move = _moves[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdge),
      child: Column(
        children: [
          // Scrollable card area takes remaining space
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ReviewCard(
                  move: move,
                  onStatePillTap: () => _showStatePicker(move),
                ),
              ),
            ),
          ),
          // Rating buttons pinned at bottom
          RatingButtonRow(
            onRate: (rating) => _rate(move, rating),
            onSkip: _skip,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    final stateFilter = ref.watch(reviewStateFilterProvider);
    final categoryFilter = ref.watch(reviewCategoryFilterProvider);
    final hasFilter = stateFilter != null || categoryFilter != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasFilter ? 'No moves match filters' : 'No moves to review',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasFilter
                ? 'Try a different filter or add more moves'
                : 'Add moves from the Arsenal tab first',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () {
                ref.read(reviewStateFilterProvider.notifier).state = null;
                ref.read(reviewCategoryFilterProvider.notifier).state = null;
              },
              child: const Text('Clear Filters'),
            ),
          ],
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
          TextButton(
            onPressed: () {
              _expandFilters();
              setState(() {
                _currentIndex = 0;
                _completed = false;
                _initialized = false;
              });
              ref.invalidate(filteredReviewMovesProvider);
            },
            child: const Text('Review Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatePicker(Move move) async {
    final currentState = LearningState.fromString(move.learningState);
    final newState = await StatePickerSheet.show(
      context,
      currentState: currentState,
      moveName: move.name,
    );

    if (newState == null || newState == currentState) return;

    // Update move state directly (manual override)
    await ref.read(moveRepositoryProvider).update(
          MovesCompanion(
            id: Value(move.id),
            learningState: Value(newState.dbValue),
          ),
        );

    // Audit trail: create review record with MANUAL type
    await ref.read(reviewRepositoryProvider).insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: newState.dbValue,
            reviewType: ReviewType.manual.dbValue,
            moveId: Value(move.id),
          ),
        );

    // Update local copy so UI reflects immediately
    setState(() {
      _moves[_currentIndex] = Move(
        id: move.id,
        name: move.name,
        learningState: newState.dbValue,
        category: move.category,
        videoPath: move.videoPath,
        createdAt: move.createdAt,
      );
    });
  }

  void _collapseFilters() {
    ref.read(dashboardExpandedProvider.notifier).state = false;
  }

  void _expandFilters() {
    ref.read(dashboardExpandedProvider.notifier).state = true;
  }

  Future<void> _rate(Move move, ReviewRating rating) async {
    HapticFeedback.mediumImpact();
    _collapseFilters();

    final currentState = LearningState.fromString(move.learningState);
    final newState = currentState.applyRating(rating);

    await ref.read(moveRepositoryProvider).update(
          MovesCompanion(
            id: Value(move.id),
            learningState: Value(newState.dbValue),
          ),
        );

    await ref.read(reviewRepositoryProvider).insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: rating.dbValue,
            reviewType: ReviewType.move.dbValue,
            moveId: Value(move.id),
          ),
        );

    _advance();
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _collapseFilters();
    _advance();
  }

  void _advance() {
    setState(() {
      if (_currentIndex < _moves.length - 1) {
        _currentIndex++;
      } else {
        _completed = true;
      }
    });
  }
}
