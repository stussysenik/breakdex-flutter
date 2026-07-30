import 'package:breakdex/core/design/color_packs.dart';
import 'package:breakdex/core/design/color_roles.dart';
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

  group('color pack + per-role overrides', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    Future<void> boot([final Map<String, Object> seed = const {}]) async {
      SharedPreferences.setMockInitialValues(seed);
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
    }

    test('unset resolves to classic', () async {
      await boot();
      expect(container.read(colorPackProvider), ColorPackId.classic);
    });

    test('an unknown stored key resolves to classic without throwing', () async {
      // The contract that keeps a removed pack from bricking the app.
      await boot({'color_pack': 'seasonal-2027'});
      expect(container.read(colorPackProvider), ColorPackId.classic);
    });

    test('a selection survives a restart', () async {
      await boot();
      await container.read(colorPackProvider.notifier).set(ColorPackId.mono);
      expect(prefs.getString('color_pack'), 'mono');

      // A fresh container over the same prefs is the restart.
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(colorPackProvider), ColorPackId.mono);
    });

    test('unset roles are absent from the override map, not defaulted', () async {
      // The distinction the whole mechanism rests on: "absent" means *use the
      // pack*. A map that returned the classic colours for unset roles would
      // override every pack on every build.
      await boot();
      expect(container.read(colorRoleOverridesProvider), isEmpty);
    });

    test('an override persists and round-trips through a restart', () async {
      await boot();
      const teal = Color(0xFF0D9F9A);
      await container
          .read(colorRoleOverridesProvider.notifier)
          .set(AppColorRole.card, teal);

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);
      expect(
        restarted.read(colorRoleOverridesProvider),
        {AppColorRole.card: teal},
      );
    });

    test('clearing a role returns it to the pack', () async {
      await boot();
      final notifier = container.read(colorRoleOverridesProvider.notifier);
      await notifier.set(AppColorRole.accent, const Color(0xFF112233));
      expect(container.read(colorRoleOverridesProvider), isNotEmpty);

      await notifier.clear(AppColorRole.accent);
      expect(container.read(colorRoleOverridesProvider), isEmpty);
      expect(prefs.getInt('accent_color'), isNull);
    });

    test('pre-pack preferences are adopted, not orphaned', () async {
      // The eight roles that were adjustable before packs keep their original
      // keys, so a brownfield install carries its colours across with no
      // migration. Renaming any of these keys silently resets a real user.
      await boot({
        'accent_color': 0xFF112233,
        'learning_state_color_mastery': 0xFF445566,
        'rating_color_easy': 0xFF778899,
      });
      expect(container.read(colorRoleOverridesProvider), {
        AppColorRole.accent: const Color(0xFF112233),
        AppColorRole.stateMastery: const Color(0xFF445566),
        AppColorRole.actionEasy: const Color(0xFF778899),
      });
    });

    test('every role has a unique preference key', () async {
      final keys = AppColorRole.values
          .map(ColorRoleOverridesNotifier.keyFor)
          .toList();
      expect(keys.toSet().length, keys.length);
    });

    test('a write through a pre-pack provider is visible here', () async {
      // Same stored key, two readers — so the value cannot diverge, but a stale
      // in-memory cache can. The notifiers invalidate each other for that.
      await boot();
      await container
          .read(accentColorProvider.notifier)
          .set(const Color(0xFFAABBCC));
      expect(
        container.read(colorRoleOverridesProvider)[AppColorRole.accent],
        const Color(0xFFAABBCC),
      );
    });

    test('and the reverse — a role write is visible to the old provider', () async {
      await boot();
      await container
          .read(colorRoleOverridesProvider.notifier)
          .set(AppColorRole.accent, const Color(0xFFAABBCC));
      expect(container.read(accentColorProvider), const Color(0xFFAABBCC));
    });

    test('adding a pack does not disturb a stored selection', () async {
      // `fromKey` matches by key, never by ordinal, so a new enum value inserted
      // anywhere leaves existing selections alone.
      await boot({'color_pack': 'mono'});
      expect(container.read(colorPackProvider), ColorPackId.mono);
      expect(ColorPackId.fromKey('mono'), ColorPackId.mono);
    });
  });
}
