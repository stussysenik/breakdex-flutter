import 'learning_state.dart';

LearningState compositeState(final List<LearningState> moveStates) {
  if (moveStates.isEmpty) return LearningState.newState;
  if (moveStates.every((final s) => s == LearningState.mastery)) {
    return LearningState.mastery;
  }
  if (moveStates.any((final s) => s == LearningState.newState)) {
    return LearningState.newState;
  }
  return LearningState.learning;
}
