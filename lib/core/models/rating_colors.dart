import 'package:flutter/material.dart';

import 'package:breakdex/core/design/colors.dart';

/// Immutable snapshot of the four rating colors.
///
/// Sibling of [LearningStateColors] in `learning_state_colors.dart` — the two
/// carry the two halves of the semantic signal set. It lives here rather than in
/// `providers/theme_providers.dart` (a `part of providers.dart`) so the design
/// layer can name it: `AppTheme` accepts it as a per-role override, and a `part`
/// cannot be imported.
class RatingColors {
  final Color again;
  final Color hard;
  final Color good;
  final Color easy;

  const RatingColors({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });

  static const defaults = RatingColors(
    again: AppColors.actionAgain,
    hard: AppColors.actionHard,
    good: AppColors.actionGood,
    easy: AppColors.actionEasy,
  );

  /// Look up the color for a given rating name (AGAIN, HARD, GOOD, EASY).
  Color forName(final String name) => switch (name) {
    'AGAIN' => again,
    'HARD' => hard,
    'GOOD' => good,
    'EASY' => easy,
    _ => again,
  };

  RatingColors copyWith({
    final Color? again,
    final Color? hard,
    final Color? good,
    final Color? easy,
  }) {
    return RatingColors(
      again: again ?? this.again,
      hard: hard ?? this.hard,
      good: good ?? this.good,
      easy: easy ?? this.easy,
    );
  }
}
