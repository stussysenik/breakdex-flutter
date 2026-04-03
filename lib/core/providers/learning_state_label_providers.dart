part of '../providers.dart';

const defaultLearningStateLabels = <LearningState, String>{
  LearningState.newState: 'New',
  LearningState.learning: 'Learning',
  LearningState.mastery: 'Mastery',
};

String resolveLearningStateLabel(
  Map<LearningState, String> labels,
  LearningState state,
) {
  return labels[state] ??
      defaultLearningStateLabels[state] ??
      state.displayText;
}

final learningStateLabelsProvider =
    NotifierProvider<LearningStateLabelsNotifier, Map<LearningState, String>>(
      LearningStateLabelsNotifier.new,
    );

class LearningStateLabelsNotifier extends Notifier<Map<LearningState, String>> {
  static const _key = 'learning_state_labels';

  @override
  Map<LearningState, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) {
      return Map<LearningState, String>.from(defaultLearningStateLabels);
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final labels = Map<LearningState, String>.from(
        defaultLearningStateLabels,
      );
      for (final state in LearningState.values) {
        final value = decoded[state.dbValue];
        if (value is String && value.trim().isNotEmpty) {
          labels[state] = value.trim();
        }
      }
      return labels;
    } catch (_) {
      return Map<LearningState, String>.from(defaultLearningStateLabels);
    }
  }

  Future<void> rename(LearningState stateKey, String newLabel) async {
    final trimmed = newLabel.trim();
    if (trimmed.isEmpty) return;

    final updated = Map<LearningState, String>.from(state);
    updated[stateKey] = trimmed;
    state = updated;
    await _persist(updated);
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = Map<LearningState, String>.from(defaultLearningStateLabels);
  }

  Future<void> _persist(Map<LearningState, String> labels) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final payload = <String, String>{
      for (final entry in labels.entries) entry.key.dbValue: entry.value,
    };
    await prefs.setString(_key, jsonEncode(payload));
  }
}
