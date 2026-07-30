import 'package:breakdex/core/design/color_roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColorRole', () {
    test('the vocabulary is closed and every role is classified', () {
      // A role's kind decides which axis owns it (pack vs accessibility
      // overlay). Adding a role without deciding that is the drift this enum
      // removes, so the count is pinned: a new role must be a deliberate edit
      // here, not an accident in colors.dart.
      expect(AppColorRole.values.length, 17);
      expect(
        AppColorRole.surfaces.length + AppColorRole.signals.length,
        lessThan(AppColorRole.values.length),
        reason: 'ink roles are neither surfaces nor signals',
      );
    });

    test('the overlay-owned set is exactly the meaning-by-color roles', () {
      // Asserted by name rather than by count: reclassifying a signal as ink
      // would silently exempt it from the accessibility overlay, which is the
      // regression D3 exists to prevent.
      expect(AppColorRole.signals.toSet(), {
        AppColorRole.error,
        AppColorRole.stateNew,
        AppColorRole.stateLearning,
        AppColorRole.stateMastery,
        AppColorRole.actionAgain,
        AppColorRole.actionHard,
        AppColorRole.actionGood,
        AppColorRole.actionEasy,
      });
    });

    test('the pack-owned surface set is exactly the chrome roles', () {
      expect(AppColorRole.surfaces.toSet(), {
        AppColorRole.background,
        AppColorRole.card,
        AppColorRole.fill,
        AppColorRole.separator,
      });
    });

    test('every kind is used — no dead classification', () {
      for (final kind in AppColorRoleKind.values) {
        expect(
          AppColorRole.values.any((final role) => role.kind == kind),
          isTrue,
          reason: '$kind classifies no role',
        );
      }
    });
  });
}
