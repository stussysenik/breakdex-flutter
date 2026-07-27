import 'package:flutter/material.dart';

import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/design/colors.dart';

class LearningStateColors {
  final Color newState;
  final Color learning;
  final Color mastery;

  const LearningStateColors({
    required this.newState,
    required this.learning,
    required this.mastery,
  });

  static const defaults = LearningStateColors(
    newState: AppColors.stateNew,
    learning: AppColors.stateLearning,
    mastery: AppColors.stateMastery,
  );

  Color forState(final LearningState state) => switch (state) {
    LearningState.newState => newState,
    LearningState.learning => learning,
    LearningState.mastery => mastery,
  };

  LearningStateColors copyWith({
    final Color? newState,
    final Color? learning,
    final Color? mastery,
  }) {
    return LearningStateColors(
      newState: newState ?? this.newState,
      learning: learning ?? this.learning,
      mastery: mastery ?? this.mastery,
    );
  }
}
