import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/shared/widgets/app_morph.dart';

/// Morph is the default for shape continuity, and this is what makes "default"
/// mean something: the only way to declare a shared element is `AppMorph`, so a
/// flight cannot be authored that rides the route's linear animation instead of
/// [AppMotion.morph].
///
/// No allowlist beyond the definition file — the same footing as raw `Icons.*`
/// and raw `AppColors.*`.

void main() {
  group('morph conformance — no raw Hero anywhere', () {
    test('no file under lib/ constructs a Hero (outside AppMorph)', () {
      final offending = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path == 'lib/shared/widgets/app_morph.dart') continue;
        if (RegExp(r'\bHero\(').hasMatch(entity.readAsStringSync())) {
          offending.add(entity.path);
        }
      }
      expect(
        offending,
        isEmpty,
        reason:
            '${offending.length} file(s) construct a raw Hero:\n'
            '${offending.join('\n')}\n'
            'A raw Hero interpolates its rect linearly against the route '
            'animation, which is the Fluid feel applied to a Morph problem. '
            'Use AppMorph.',
      );
    });
  });

  group('the flight is timed by AppMotion.morph, not by the route', () {
    const begin = Rect.fromLTWH(0, 0, 100, 100);
    const end = Rect.fromLTWH(0, 0, 300, 300);

    test('halfway through the route is not halfway through the shape', () {
      final morph = AppMorph.morphRectTween(begin, end);
      final linear = RectTween(begin: begin, end: end);

      // The whole point of the ruling: at the midpoint of the route's own
      // animation the spring has already carried the shape most of the way.
      expect(morph.lerp(0.5), isNot(linear.lerp(0.5)));
      expect(morph.lerp(0.5)!.width, greaterThan(linear.lerp(0.5)!.width));
    });

    test('it is exactly the linear tween sampled on the morph curve', () {
      final morph = AppMorph.morphRectTween(begin, end);
      final linear = RectTween(begin: begin, end: end);
      for (final t in const [0.1, 0.25, 0.5, 0.75, 0.9]) {
        expect(morph.lerp(t), linear.lerp(AppMotion.morph.transform(t)));
      }
    });

    test('both ends still land exactly', () {
      final morph = AppMorph.morphRectTween(begin, end);
      expect(morph.lerp(0), begin);
      expect(morph.lerp(1), end);
    });
  });

  group('the spring occupies the duration it is given', () {
    // A spring normalised onto a fixed 3s window reached 1.0 at about t=0.2,
    // so a 240ms transition showed ~40ms of motion and read as a pop. These
    // are the bounds that keep the duration at the call site meaningful.
    test('a twentieth in, the shape has barely left', () {
      // Under the fixed 3s window this read 0.88 — the motion was effectively
      // over before the first three frames of a 240ms transition.
      expect(AppMotion.morph.transform(0.05), lessThan(0.5));
    });

    test('it still arrives exactly', () {
      expect(AppMotion.morph.transform(1), 1);
    });
  });

  group('reduced motion removes the flight rather than shortening it', () {
    testWidgets('AppMorph builds no Hero when animations are disabled', (
      final tester,
    ) async {
      Widget app({required final bool disable}) => MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AppMorph(identifier: 'x', child: SizedBox(width: 10)),
        ),
      );

      await tester.pumpWidget(app(disable: false));
      expect(find.byType(Hero), findsOneWidget);

      await tester.pumpWidget(app(disable: true));
      expect(find.byType(Hero), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
