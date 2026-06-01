import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/colors.dart';

/// User-defined learning state for custom review modes.
///
/// Each custom state has a unique [id], a user-facing [label],
/// a [dbValue] used in the moves table, and a [color].
class CustomLearningState {
  const CustomLearningState({
    required this.id,
    required this.label,
    required this.dbValue,
    required this.color,
  });

  final String id;
  final String label;
  final String dbValue;
  final Color color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'dbValue': dbValue,
        'color': color.value.toRadixString(16).padLeft(8, '0'),
      };

  factory CustomLearningState.fromJson(final Map<String, dynamic> json) {
    final colorHex = json['color'] as String? ?? 'FFC46F6F';
    final colorInt = int.tryParse(colorHex, radix: 16) ?? 0xFFC46F6F;
    return CustomLearningState(
      id: json['id'] as String,
      label: json['label'] as String,
      dbValue: json['dbValue'] as String,
      color: Color(colorInt),
    );
  }
}

enum LearningState {
  newState('NEW', 'New', AppColors.stateNew),
  learning('LEARNING', 'Practicing', AppColors.stateLearning),
  mastery('MASTERY', 'Strong', AppColors.stateMastery);

  const LearningState(this.dbValue, this.displayText, this.color);

  final String dbValue;
  final String displayText;
  final Color color;

  static LearningState fromString(final String value) => switch (value.toUpperCase()) {
        'NEW' => LearningState.newState,
        'LEARNING' => LearningState.learning,
        'MASTERY' => LearningState.mastery,
        _ => LearningState.newState,
      };

  static LearningState fromName(final String value) => fromString(value);

  LearningState applyRating(final ReviewRating rating) => switch (rating) {
        ReviewRating.again => LearningState.newState,
        ReviewRating.hard => LearningState.learning,
        ReviewRating.good => switch (this) {
            LearningState.newState => LearningState.learning,
            LearningState.learning => LearningState.mastery,
            LearningState.mastery => LearningState.mastery,
          },
        ReviewRating.easy => LearningState.mastery,
      };
}

enum ReviewRating {
  again('AGAIN', 'AGAIN', AppColors.actionAgain),
  hard('HARD', 'HARD', AppColors.actionHard),
  good('GOOD', 'GOOD', AppColors.actionGood),
  easy('EASY', 'EASY', AppColors.actionEasy);

  const ReviewRating(this.dbValue, this.displayText, this.color);

  final String dbValue;
  final String displayText;
  final Color color;

  static ReviewRating fromString(final String value) => switch (value) {
        'AGAIN' => ReviewRating.again,
        'HARD' => ReviewRating.hard,
        'GOOD' => ReviewRating.good,
        'EASY' => ReviewRating.easy,
        _ => ReviewRating.again,
      };
}

enum ReviewType {
  move('MOVE'),
  combo('COMBO'),
  manual('MANUAL');

  const ReviewType(this.dbValue);
  final String dbValue;

  static ReviewType fromString(final String value) => switch (value) {
        'MOVE' => ReviewType.move,
        'COMBO' => ReviewType.combo,
        'MANUAL' => ReviewType.manual,
        _ => ReviewType.move,
      };
}
