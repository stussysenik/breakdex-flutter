import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/navigation/app_router.dart';
import 'package:breakdex/core/navigation/settings_section_page.dart';

/// Drives [SettingsSectionTransition] at a fixed point of both animations so
/// the motion can be read off the tree without a router.
Widget _harness({
  required final double enter,
  required final double cover,
  final bool reduceMotion = false,
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: SettingsSectionTransition(
      animation: AlwaysStoppedAnimation<double>(enter),
      secondaryAnimation: AlwaysStoppedAnimation<double>(cover),
      child: const SizedBox(key: ValueKey('section'), width: 100, height: 100),
    ),
  ),
);

void main() {
  group('SettingsSectionTransition', () {
    testWidgets('arrives faded and risen, settles flush and opaque', (
      final tester,
    ) async {
      await tester.pumpWidget(_harness(enter: 0, cover: 0));
      final start = tester.getTopLeft(find.byKey(const ValueKey('section')));
      expect(tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value, 0);

      await tester.pumpWidget(_harness(enter: 1, cover: 0));
      final end = tester.getTopLeft(find.byKey(const ValueKey('section')));
      expect(tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value, 1);

      // Fluid: the section rises into place — it starts below where it lands.
      expect(start.dy, greaterThan(end.dy));
    });

    testWidgets('the covered view recedes as one surface (Morph)', (
      final tester,
    ) async {
      double scale() =>
          tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

      await tester.pumpWidget(_harness(enter: 1, cover: 0));
      expect(scale(), 1);

      await tester.pumpWidget(_harness(enter: 1, cover: 1));
      expect(scale(), lessThan(1));
      expect(scale(), closeTo(SettingsSectionTransition.recedeScale, 0.001));
    });

    testWidgets('reduced motion cuts instead of animating', (
      final tester,
    ) async {
      await tester.pumpWidget(_harness(enter: 0, cover: 0, reduceMotion: true));

      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byKey(const ValueKey('section')), findsOneWidget);
    });
  });

  group('settingsSectionPage', () {
    test('rides the sanctioned motion durations', () {
      final page = settingsSectionPage(
        key: const ValueKey('k'),
        child: const SizedBox(),
      );

      expect(page.transitionDuration, AppMotion.moderate02);
      expect(page.reverseTransitionDuration, AppMotion.moderate01);
    });
  });

  test('every settings section route opens with the section transition', () {
    final settingsRoutes = appRouter.configuration.routes
        .whereType<GoRoute>()
        .where((final r) => r.path.startsWith('/settings-panel'))
        .toList();

    expect(settingsRoutes, isNotEmpty);
    for (final route in settingsRoutes) {
      expect(
        route.pageBuilder,
        isNotNull,
        reason: '${route.path} still uses the default push transition',
      );
    }
  });
}
