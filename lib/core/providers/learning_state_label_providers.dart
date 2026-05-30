part of '../providers.dart';

const defaultLearningStateLabels = <LearningState, String>{
  LearningState.newState: 'New',
  LearningState.learning: 'Practicing',
  LearningState.mastery: 'Strong',
};

String resolveLearningStateLabel(
  Map<LearningState, String> labels,
  LearningState state,
) {
  return labels[state] ??
      defaultLearningStateLabels[state] ??
      state.displayText;
}

/// Whether to use default mode (3 built-in states) or custom mode
/// (built-in + user-defined states).
enum LearningMode { defaultMode, custom }

final learningModeProvider =
    NotifierProvider<LearningModeNotifier, LearningMode>(
      LearningModeNotifier.new,
    );

class LearningModeNotifier extends Notifier<LearningMode> {
  static const _key = 'learning_mode';

  @override
  LearningMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString(_key) ?? 'defaultMode';
    return LearningMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LearningMode.defaultMode,
    );
  }

  Future<void> set(LearningMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}

/// User-defined learning states stored in SharedPreferences.
final customLearningStatesProvider =
    NotifierProvider<CustomLearningStatesNotifier, List<CustomLearningState>>(
      CustomLearningStatesNotifier.new,
    );

class CustomLearningStatesNotifier extends Notifier<List<CustomLearningState>> {
  static const _key = 'custom_learning_states';

  @override
  List<CustomLearningState> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CustomLearningState.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(CustomLearningState custom) async {
    final updated = [...state, custom];
    state = updated;
    await _persist(updated);
  }

  Future<void> remove(String id) async {
    final updated = state.where((s) => s.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> update(String id, CustomLearningState updated) async {
    final list = state.toList();
    final idx = list.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    list[idx] = updated;
    state = list;
    await _persist(list);
  }

  Future<void> _persist(List<CustomLearningState> states) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = jsonEncode(states.map((s) => s.toJson()).toList());
    await prefs.setString(_key, json);
  }
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
