import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('learning state labels provider', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    Future<void> createContainer([
      Map<String, Object> initialValues = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('loads saved learning state labels from shared preferences', () async {
      await createContainer(const {
        'learning_state_labels':
            '{"NEW":"Fresh","LEARNING":"In Rotation","MASTERY":"Locked"}',
      });

      final labels = container.read(learningStateLabelsProvider);

      expect(labels[LearningState.newState], 'Fresh');
      expect(labels[LearningState.learning], 'In Rotation');
      expect(labels[LearningState.mastery], 'Locked');
    });

    test('persists renamed labels and reset restores defaults', () async {
      await createContainer();

      final notifier = container.read(learningStateLabelsProvider.notifier);

      await notifier.rename(LearningState.learning, 'In Rotation');

      var labels = container.read(learningStateLabelsProvider);
      expect(labels[LearningState.learning], 'In Rotation');
      expect(
        prefs.getString('learning_state_labels'),
        contains('"LEARNING":"In Rotation"'),
      );

      await notifier.reset();

      labels = container.read(learningStateLabelsProvider);
      expect(labels[LearningState.learning], 'Practicing');
      expect(prefs.getString('learning_state_labels'), isNull);
    });
  });
}
