import 'package:breakdex/core/design/colors.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('theme providers', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('accent color persists arbitrary ARGB values', () async {
      const color = Color(0xCC123456);

      await container.read(accentColorProvider.notifier).set(color);

      expect(container.read(accentColorProvider), color);
      expect(prefs.getInt('accent_color'), color.toARGB32());
    });

    test('rating colors persist arbitrary ARGB values per slot', () async {
      const hardColor = Color(0xAA0F8CDA);

      await container
          .read(ratingColorsProvider.notifier)
          .setColor('hard', hardColor);

      final colors = container.read(ratingColorsProvider);
      expect(colors.hard, hardColor);
      expect(colors.again, AppColors.actionAgain);
      expect(colors.good, AppColors.actionGood);
      expect(colors.easy, AppColors.actionEasy);
      expect(prefs.getInt('rating_color_hard'), hardColor.toARGB32());
    });

    test(
      'learning state colors persist arbitrary ARGB values per state',
      () async {
        const masteryColor = Color(0xCC39A96B);

        await container
            .read(learningStateColorsProvider.notifier)
            .setColor(LearningState.mastery, masteryColor);

        final colors = container.read(learningStateColorsProvider);
        expect(colors.mastery, masteryColor);
        expect(colors.newState, AppColors.stateNew);
        expect(colors.learning, AppColors.stateLearning);
        expect(
          prefs.getInt('learning_state_color_mastery'),
          masteryColor.toARGB32(),
        );
      },
    );

    test('learning state color reset restores defaults', () async {
      await container
          .read(learningStateColorsProvider.notifier)
          .setColor(LearningState.learning, const Color(0xFF123456));

      await container.read(learningStateColorsProvider.notifier).resetAll();

      final colors = container.read(learningStateColorsProvider);
      expect(colors.newState, AppColors.stateNew);
      expect(colors.learning, AppColors.stateLearning);
      expect(colors.mastery, AppColors.stateMastery);
      expect(prefs.getInt('learning_state_color_learning'), isNull);
    });
  });
}
