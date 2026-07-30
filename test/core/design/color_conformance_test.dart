import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The color twin of `icon_conformance_test.dart`.
///
/// A raw `AppColors.*` read outside the definition layer is a pixel the theme
/// cannot reach: it survives a pack substitution unchanged, and — the live
/// defect 2.5 was filed for — it survives the `AccessiblePalette` overlay too,
/// so a deuteranopia guarantee that `AppSemanticTheme` publishes is silently
/// broken wherever such a site renders.
///
/// **The ban is not zero-allowlist, and the difference is load-bearing.** The
/// icon ban could be absolute because `icons.dart` is the only file that may
/// name an `IconData`. Colors have a *definition layer* — a pack must seed its
/// roles from constants, and a preference provider must fall back to one — so an
/// absolute ban would forbid the mechanism from existing. Every entry below is
/// therefore a file that *defines* what a role resolves to, never one that
/// *paints* with it. A widget can never qualify.
const _definitionLayer = <String>{
  // The constants themselves.
  'lib/core/design/colors.dart',
  // Packs seed their roles from the constants — this is the mechanism.
  'lib/core/design/color_packs.dart',
  // Assembles ColorScheme + AppSemanticTheme from a pack; owns the overlay.
  'lib/core/design/theme.dart',
  // Persisted per-role overrides fall back to the shipped value when unset.
  'lib/core/providers/theme_providers.dart',
  // Immutable default snapshots fed to AppTheme as overrides.
  'lib/core/models/learning_state_colors.dart',
  'lib/core/models/rating_colors.dart',
  // A picker palette of *persisted user data*, not rendered theme. A category's
  // color is stored per-category; re-pointing these presets at the theme would
  // make already-saved categories drift when a pack changes.
  'lib/core/services/categories_service.dart',
};

void main() {
  group('color conformance — AppColors.* only in the definition layer', () {
    test('no file under lib/ paints with a raw AppColors constant', () {
      final offending = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (_definitionLayer.contains(entity.path)) continue;
        if (RegExp(r'AppColors\.\w+').hasMatch(entity.readAsStringSync())) {
          offending.add(entity.path);
        }
      }
      expect(
        offending,
        isEmpty,
        reason:
            '${offending.length} file(s) read AppColors.* outside the '
            'definition layer:\n${offending.join('\n')}\n'
            'Read the role through the theme instead — '
            'Theme.of(context).colorScheme.* for surfaces/accent, '
            'AppSemanticTheme.of(context).* (or context.stateColor) for '
            'signals. Adding a file to _definitionLayer is only correct if it '
            'defines what a role resolves to; a widget never does.',
      );
    });

    test('every definition-layer entry exists and still reads AppColors', () {
      for (final path in _definitionLayer) {
        // The declaring file names no `AppColors.` of its own — it *is* the
        // constants — so it is exempt from the still-in-use check, not from the
        // exemption itself.
        if (path == 'lib/core/design/colors.dart') continue;
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path no longer exists');
        expect(
          RegExp(r'AppColors\.\w+').hasMatch(file.readAsStringSync()),
          isTrue,
          reason:
              '$path no longer reads AppColors.* — drop it from '
              '_definitionLayer so the exemption cannot outlive its reason.',
        );
      }
    });
  });
}
