import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The conformance roster: every screen that is on the frame. All five tabs
/// are, as of 2026-07-29, which is why `docs/design/TOKENS.md` no longer
/// carries a migration ledger — this list replaced it. Add a screen here in
/// the same commit that migrates it.
///
/// Detail routes joined on 2026-08-01 (§4.2). The ruling they were waiting on:
/// they are pushed *inside* the shell branch, so band 4 is still there and the
/// only missing fact was a way back — which the frame now reads from the route
/// (`Navigator.canPop`) rather than taking as a per-screen flag. A tab root
/// cannot pop, so it cannot show a back control that does nothing; a pushed
/// screen cannot forget one.
const _migratedScreens = <String>[
  'lib/features/add/add_screen.dart',
  'lib/features/breakdex/breakdex_screen.dart',
  'lib/features/stats/stats_screen.dart',
  'lib/features/lab/lab_screen.dart',
  'lib/features/flow/flow_screen.dart',
  'lib/features/move_list/move_list_screen.dart',
  'lib/features/combos/combos_screen.dart',
  'lib/features/move_detail/move_detail_screen.dart',
  'lib/features/combo_detail/combo_detail_screen.dart',
  'lib/features/lab/lab_detail_screen.dart',
  'lib/features/move_category/move_category_screen.dart',
  // Settings joined on 2026-08-01 (§4.3). These are the first screens pushed on
  // the **root** navigator, outside the shell — so the frame stopped assuming
  // band 4 exists and started reading `NavBandScope`. `SettingsScreen.isTab`
  // went with the assumption: the same widget serves `/settings` (a tab root,
  // cannot pop, no back) and `/settings-panel` (pushed, pops, has back), and
  // the route already knows which.
  'lib/features/settings/settings_screen.dart',
  'lib/features/settings/system_status_screen.dart',
  'lib/features/settings/sync_status_screen.dart',
  'lib/features/settings/sync_providers_screen.dart',
  'lib/features/settings/free_space_screen.dart',
  'lib/features/settings/recently_deleted_screen.dart',
  'lib/features/settings/canonical_trash_screen.dart',
  'lib/features/settings/help/asset_sync_help_screen.dart',
  'lib/features/settings/widgets/color_packs_section.dart',
];

/// Surfaces that are deliberately frameless, and why. A frameless surface is
/// not an exemption from the constitution — it is a surface with **no** bands
/// at all, which is a different decision from a screen that builds its own.
///
/// `flashcard_review_screen` holds both: its prescreen is on the frame
/// (`AppScreen.fill`), and an active drill session takes the whole viewport
/// with the header and nav band hidden on purpose. It joins the roster above
/// when that session moves to its own file — tracked as task 4.4.
const _frameless = 'lib/features/flashcard_review/flashcard_review_screen.dart';

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

    test('the frameless drill session stays a single bounded exemption', () {
      // Bounded, not open: one Scaffold is the immersive session. A second one
      // means a screen quietly grew chrome again under cover of the exemption.
      final source = File(_frameless).readAsStringSync();
      expect('Scaffold('.allMatches(source).length, 1);
      expect(source.contains('AppBar('), isFalse);
      expect(source.contains('AppScreen.fill('), isTrue);
    });

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
