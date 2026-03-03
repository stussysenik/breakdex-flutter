import 'learning_state.dart';

LearningState compositeState(List<LearningState> moveStates) {
  if (moveStates.isEmpty) return LearningState.newState;
  if (moveStates.every((s) => s == LearningState.mastery)) {
    return LearningState.mastery;
  }
  if (moveStates.any((s) => s == LearningState.newState)) {
    return LearningState.newState;
  }
  return LearningState.learning;
}
