import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/models/learning_state.dart';
import '../../core/providers.dart';
import '../../shared/widgets/state_pill.dart';
import '../../shared/widgets/video_player_widget.dart' show RobustVideoPlayer, VideoPlaceholder;

final _reviewMovesProvider = FutureProvider<List<Move>>((ref) {
  return ref.watch(moveRepositoryProvider).getAll();
});

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

  @override
  Widget build(BuildContext context) {
    final movesAsync = ref.watch(_reviewMovesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: movesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (moves) {
            if (_moves.isEmpty && moves.isNotEmpty) {
              _moves = List.from(moves);
            }

            if (_moves.isEmpty) {
              return _buildEmpty(colorScheme);
            }

            if (_completed) {
              return _buildCompleted(colorScheme);
            }

            final move = _moves[_currentIndex];
            final state = LearningState.fromString(move.learningState);

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screenEdge),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(Icons.chevron_left,
                                color: colorScheme.secondary, size: 20),
                            Text(
                              'Review',
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentIndex + 1}/${_moves.length}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Video card
                  if (move.videoPath != null)
                    RobustVideoPlayer(
                      videoPath: move.videoPath!,
                      height: 400,
                    )
                  else
                    const VideoPlaceholder(height: 400),
                  const SizedBox(height: AppSpacing.lg),

                  // Move name
                  Text(
                    move.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatePill(state: state),
                  const Spacer(),

                  // Rating buttons
                  Row(
                    children: [
                      for (final rating in ReviewRating.values) ...[
                        if (rating != ReviewRating.values.first)
                          const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _RatingButton(
                            rating: rating,
                            onPressed: () => _rate(move, rating),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 64, color: colorScheme.secondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No moves to review',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add moves from the Arsenal tab first',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
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
          TextButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _completed = false;
                _moves = [];
              });
              ref.invalidate(_reviewMovesProvider);
            },
            child: const Text('Review Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _rate(Move move, ReviewRating rating) async {
    HapticFeedback.mediumImpact();

    final currentState = LearningState.fromString(move.learningState);
    final newState = currentState.applyRating(rating);

    // Update move state
    await ref.read(moveRepositoryProvider).update(
          MovesCompanion(
            id: Value(move.id),
            learningState: Value(newState.dbValue),
          ),
        );

    // Create review record
    await ref.read(reviewRepositoryProvider).insert(
          ReviewsCompanion.insert(
            id: const Uuid().v4(),
            rating: rating.dbValue,
            reviewType: 'MOVE',
            moveId: Value(move.id),
          ),
        );

    setState(() {
      if (_currentIndex < _moves.length - 1) {
        _currentIndex++;
      } else {
        _completed = true;
      }
    });
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({required this.rating, required this.onPressed});

  final ReviewRating rating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: rating.color,
          foregroundColor:
              rating == ReviewRating.hard ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(rating.displayText),
      ),
    );
  }
}
