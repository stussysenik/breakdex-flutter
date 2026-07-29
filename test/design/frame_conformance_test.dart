import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The conformance roster: every screen that is on the frame. All five tabs
/// are, as of 2026-07-29, which is why `docs/design/TOKENS.md` no longer
/// carries a migration ledger — this list replaced it. Add a screen here in
/// the same commit that migrates it.
///
/// Detail routes pushed on top of a tab are deliberately absent: they are a
/// different placement problem (back affordance, no nav band) and framing them
/// is a separate ruling.
const _migratedScreens = <String>[
  'lib/features/add/add_screen.dart',
  'lib/features/breakdex/breakdex_screen.dart',
  'lib/features/stats/stats_screen.dart',
  'lib/features/lab/lab_screen.dart',
  'lib/features/flow/flow_screen.dart',
];

/// Chrome a screen is no longer allowed to build for itself. The frame renders
/// bands 1, 2 and 4; a screen that re-declares any of them has left the frame.
const _forbidden = <String>['Scaffold(', 'AppBar(', 'SliverAppBar('];

void main() {
  group('stacked-viewport frame conformance', () {
    // The whole reason the constitution exists is that five screens each grew
    // their own header while every one of them passed review. A rule enforced
    // only by review is the rule that already failed, so it is checked here.
    for (final path in _migratedScreens) {
      test('$path builds no chrome of its own', () {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: '$path is in the migration ledger but not on disk',
        );

        final source = file.readAsStringSync();
        for (final chrome in _forbidden) {
          expect(
            source.contains(chrome),
            isFalse,
            reason:
                '$path constructs $chrome — the frame owns that band. Use '
                'AppScreen or AppScreen.slivers.',
          );
        }
      });
    }

    test('the frame itself is the single place chrome is built', () {
      // AppScreen is allowed the Scaffold precisely because it is the one
      // place that gets to make this decision for every screen.
      final frame = File(
        'lib/shared/widgets/app_screen.dart',
      ).readAsStringSync();
      expect(frame.contains('Scaffold('), isTrue);
    });
  });
}
