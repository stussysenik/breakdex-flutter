import 'package:breakdex/core/models/fsrs_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FsrsSettings.defaults', () {
    test('equals the prior hardcoded scheduler constants', () {
      const d = FsrsSettings.defaults;
      expect(d.desiredRetention, 0.85);
      expect(d.learningSteps, const [Duration(minutes: 10)]);
      expect(d.relearningSteps, const [Duration(minutes: 10)]);
      expect(d.maximumInterval, 36500);
      expect(d.enableFuzzing, true);
    });
  });

  group('prefs round-trip', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('encode → decode preserves every parameter', () async {
      const settings = FsrsSettings(
        desiredRetention: 0.91,
        learningSteps: [Duration(minutes: 1), Duration(minutes: 10)],
        relearningSteps: [Duration(minutes: 10), Duration(days: 1)],
        maximumInterval: 365,
        enableFuzzing: false,
      );

      await settings.writeTo(prefs);
      final restored = FsrsSettings.fromPrefs(prefs);

      expect(restored, settings);
      // Steps persisted as whole minutes.
      expect(prefs.getStringList('fsrs.learningSteps'), ['1', '10']);
      expect(prefs.getStringList('fsrs.relearningSteps'), ['10', '1440']);
    });

    test('an empty steps list survives the round-trip (distinct from missing)',
        () async {
      const settings = FsrsSettings(
        desiredRetention: 0.85,
        learningSteps: [],
        relearningSteps: [Duration(minutes: 10)],
        maximumInterval: 36500,
        enableFuzzing: true,
      );

      await settings.writeTo(prefs);
      final restored = FsrsSettings.fromPrefs(prefs);

      expect(restored.learningSteps, isEmpty);
    });
  });

  group('defaults / corrupt fallback', () {
    test('all-missing prefs decode to defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(FsrsSettings.fromPrefs(prefs), FsrsSettings.defaults);
    });

    test('out-of-range retention falls back to default', () async {
      SharedPreferences.setMockInitialValues({
        'fsrs.desiredRetention': 0.40, // below the 0.70 floor
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        FsrsSettings.fromPrefs(prefs).desiredRetention,
        FsrsSettings.defaults.desiredRetention,
      );
    });

    test('maximum interval below 1 falls back to default', () async {
      SharedPreferences.setMockInitialValues({'fsrs.maximumInterval': 0});
      final prefs = await SharedPreferences.getInstance();

      expect(
        FsrsSettings.fromPrefs(prefs).maximumInterval,
        FsrsSettings.defaults.maximumInterval,
      );
    });

    test('corrupt step entry falls back that whole list to default', () async {
      SharedPreferences.setMockInitialValues({
        'fsrs.learningSteps': ['not-a-number'],
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        FsrsSettings.fromPrefs(prefs).learningSteps,
        FsrsSettings.defaults.learningSteps,
      );
    });
  });

  group('clamping', () {
    test('retention clamps into [0.70, 0.97]', () {
      expect(FsrsSettings.clampRetention(0.50), 0.70);
      expect(FsrsSettings.clampRetention(0.99), 0.97);
      expect(FsrsSettings.clampRetention(0.88), 0.88);
    });

    test('maximum interval floors at 1', () {
      expect(FsrsSettings.clampMaximumInterval(-5), 1);
      expect(FsrsSettings.clampMaximumInterval(0), 1);
      expect(FsrsSettings.clampMaximumInterval(500), 500);
    });

    test('sanitizeSteps drops negative durations', () {
      expect(
        FsrsSettings.sanitizeSteps(
          const [Duration(minutes: -1), Duration(minutes: 10)],
        ),
        const [Duration(minutes: 10)],
      );
    });
  });
}
