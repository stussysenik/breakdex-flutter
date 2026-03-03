import 'package:flutter/material.dart';
import '../design/colors.dart';

enum LearningState {
  newState('NEW', 'New', AppColors.stateNew),
  learning('LEARNING', 'Learning', AppColors.stateLearning),
  mastery('MASTERY', 'Mastery', AppColors.stateMastery);

  const LearningState(this.dbValue, this.displayText, this.color);

  final String dbValue;
  final String displayText;
  final Color color;

  static LearningState fromString(String value) => switch (value) {
        'NEW' => LearningState.newState,
        'LEARNING' => LearningState.learning,
        'MASTERY' => LearningState.mastery,
        _ => LearningState.newState,
      };

  LearningState applyRating(ReviewRating rating) => switch (rating) {
        ReviewRating.again => LearningState.newState,
        ReviewRating.hard => LearningState.learning,
        ReviewRating.good => switch (this) {
            LearningState.newState => LearningState.learning,
            LearningState.learning => LearningState.mastery,
            LearningState.mastery => LearningState.mastery,
          },
      };
}

enum ReviewRating {
  again('AGAIN', 'AGAIN', AppColors.actionAgain),
  hard('HARD', 'HARD', AppColors.actionHard),
  good('GOOD', 'GOOD', AppColors.actionGood);

  const ReviewRating(this.dbValue, this.displayText, this.color);

  final String dbValue;
  final String displayText;
  final Color color;

  static ReviewRating fromString(String value) => switch (value) {
        'AGAIN' => ReviewRating.again,
        'HARD' => ReviewRating.hard,
        'GOOD' => ReviewRating.good,
        _ => ReviewRating.again,
      };
}

enum ReviewType {
  move('MOVE'),
  combo('COMBO'),
  manual('MANUAL');

  const ReviewType(this.dbValue);
  final String dbValue;

  static ReviewType fromString(String value) => switch (value) {
        'MOVE' => ReviewType.move,
        'COMBO' => ReviewType.combo,
        'MANUAL' => ReviewType.manual,
        _ => ReviewType.move,
      };
}
