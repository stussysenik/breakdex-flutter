import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every file under `lib/` that builds screen chrome is named in exactly one of
/// the three tables below. There is no fourth state and no unlisted file: the
/// closure test at the bottom re-derives the left-hand side from disk and fails
/// on anything it has not been told about.
///
/// Read the tables as one card per file — path, verdict, and the reason for the
/// verdict, in that order, every time. A file moves between tables in the same
/// commit that changes how it builds; it is never in two, and never in none.
///
/// | table            | means                                                |
/// |------------------|------------------------------------------------------|
/// | [_onFrame]       | builds through `AppScreen`; **no** chrome of its own  |
/// | [_frameless]     | has **no** bands at all, on purpose, for a stated why |
/// | [_awaitingRuling]| still bespoke; the remaining §4.4 work, one line each |
/// | [_framework]     | the two files allowed to build bands, being the frame |
///
/// [_awaitingRuling] is the only table that shrinks. When it is empty, task 4.5
/// is done by deletion: the guard is already a denylist — it fails on a *new*
/// bespoke `Scaffold` today, because a new one is a file in no table at all.

/// Screens on the frame. Chrome-free by assertion, not by review.
///
/// All five tabs joined 2026-07-29, which is why `docs/design/TOKENS.md` no
/// longer carries a migration ledger — this table replaced it.
const _onFrame = <String, String>{
  'lib/features/add/add_screen.dart': 'tab root',
  'lib/features/breakdex/breakdex_screen.dart': 'tab root',
  'lib/features/stats/stats_screen.dart': 'tab root',
  'lib/features/lab/lab_screen.dart': 'tab root',
  'lib/features/flow/flow_screen.dart': 'tab root',
  'lib/features/move_list/move_list_screen.dart': 'tab root',
  'lib/features/combos/combos_screen.dart': 'tab root',

  // Detail routes joined 2026-08-01 (§4.2). The ruling they were waiting on:
  // they are pushed *inside* the shell branch, so band 4 is still there and the
  // only missing fact was a way back — which the frame now reads from the route
  // (`Navigator.canPop`) rather than taking as a per-screen flag. A tab root
  // cannot pop, so it cannot show a back control that does nothing; a pushed
  // screen cannot forget one.
  'lib/features/move_detail/move_detail_screen.dart': 'pushed in shell',
  'lib/features/combo_detail/combo_detail_screen.dart': 'pushed in shell',
  'lib/features/lab/lab_detail_screen.dart': 'pushed in shell',
  'lib/features/move_category/move_category_screen.dart': 'pushed in shell',

  // Settings joined 2026-08-01 (§4.3). The first screens pushed on the **root**
  // navigator, outside the shell — so the frame stopped assuming band 4 exists
  // and started reading `NavBandScope`. `SettingsScreen.isTab` went with the
  // assumption: one widget serves `/settings` (a tab root, cannot pop, no back)
  // and `/settings-panel` (pushed, pops, has back), and the route already knows.
  'lib/features/settings/settings_screen.dart': 'root-pushed panel',
  'lib/features/settings/system_status_screen.dart': 'root-pushed panel',
  'lib/features/settings/sync_status_screen.dart': 'root-pushed panel',
  'lib/features/settings/sync_providers_screen.dart': 'root-pushed panel',
  'lib/features/settings/free_space_screen.dart': 'root-pushed panel',
  'lib/features/settings/recently_deleted_screen.dart': 'root-pushed panel',
  'lib/features/settings/canonical_trash_screen.dart': 'root-pushed panel',
  'lib/features/settings/help/asset_sync_help_screen.dart': 'root-pushed panel',
  'lib/features/settings/widgets/color_packs_section.dart': 'root-pushed panel',

  // Joined 2026-08-01 (§4.4). Each had grown its own header; each now states
  // which of the three forms it needs and why, in one comment above the call.
  'lib/features/auth/auth_screen.dart': 'default form — one short sign-in form',
  'lib/features/party/party_screen.dart':
      'fill form — loading/error/data branches share one frame',
  'lib/features/move_analysis/move_analysis_screen.dart':
      'fill form — two panes plus a pinned toolbar, never one scroll',
  'lib/features/create_combo/create_combo_screen.dart':
      'default form under a saving veil; rename moved title → action',
  'lib/features/dev/sync_cutover_panel.dart':
      'default form — a dev surface is still a screen',
};

/// Surfaces with **no** bands at all, on purpose. Frameless is not an exemption
/// from the constitution; it is a different decision, and it costs a reason.
///
/// The bound is the same for every one of them: a frameless surface may own a
/// `Scaffold` (it needs the Material surface) and may **never** own an `AppBar`.
/// A header is the band that drifted five times; it is the band nobody gets to
/// re-declare, framed or not.
const _frameless = <String, String>{
  'lib/features/flashcard_review/flashcard_review_screen.dart':
      'the drill session takes the whole viewport by design; its prescreen is '
      'on the frame (AppScreen.fill) and the session is the exemption. It '
      'joins _onFrame when the session moves to its own file — task 4.4.',
  'lib/features/auth/appwrite_login_screen.dart':
      'the door, not a room: pre-auth, outside the shell, with no crumb address '
      'to show and nowhere to go back to.',
};

/// Still bespoke. The remaining §4.4 roster, one line each saying what has to
/// be decided — not what has to be typed. Every line here is a ruling owed.
const _awaitingRuling = <String, String>{
  'lib/features/battle/battle_screen.dart':
      'close is a forfeit confirm, and the frame\'s back pops unconditionally; '
      'ruling owed on how a screen with unsaved state refuses a pop.',
  'lib/features/instax_viewer/instax_viewer_screen.dart':
      'media chrome (AppMediaChrome, dark on purpose) with a real AppBar — '
      'either frameless without that bar, or on the frame in dark chrome.',
  'lib/features/video_editor/video_editor_screen.dart':
      'editor shell: a switcher plus a FAB over two full-bleed editor views.',
  'lib/features/video_editor/simplified_video_editor_screen.dart':
      'full-bleed editing surface with a transparent bar over the video.',
  'lib/shared/widgets/quick_video_viewer.dart':
      'black full-bleed viewer; almost certainly frameless, needs the reason.',
  'lib/shared/widgets/video_player_widget.dart':
      'fullscreen playback route inside a widget file; likely frameless.',
  'lib/shared/widgets/metadata_video_picker_sheet.dart':
      'a sheet, not a screen — the §3 dialog ruling probably applies verbatim.',
  'lib/dev/preview_harness.dart':
      'the harness renders other screens; its Scaffold may be the harness '
      'itself rather than a screen, which is a different thing again.',
  'lib/core/navigation/app_router.dart':
      'the router\'s own loading and error routes; small, but still screens.',
  'lib/main.dart': 'the boot-failure surface, before any of this exists.',
};

/// The frame itself. Two files, and the whole point is that it is two.
const _framework = <String, String>{
  'lib/shared/widgets/app_screen.dart':
      'renders bands 1 and 2, owns the Scaffold',
  'lib/shared/widgets/bottom_nav_shell.dart': 'renders band 4 over the branch',
};

/// Chrome a screen on the frame is no longer allowed to build for itself.
const _forbidden = <String>['Scaffold(', 'AppBar(', 'SliverAppBar('];

void main() {
  group('stacked-viewport frame conformance', () {
    // The whole reason the constitution exists is that five screens each grew
    // their own header while every one of them passed review. A rule enforced
    // only by review is the rule that already failed, so it is checked here.
    _onFrame.forEach((final path, final why) {
      test('$path builds no chrome of its own ($why)', () {
        final source = _read(path);
        for (final chrome in _forbidden) {
          expect(
            source.contains(chrome),
            isFalse,
            reason:
                '$path constructs $chrome — the frame owns that band. Use '
                'AppScreen, AppScreen.slivers or AppScreen.fill.',
          );
        }
      });
    });

    // Frameless is bounded, not open: no bands at all still means no header.
    _frameless.forEach((final path, final why) {
      test('$path stays frameless without growing a header ($why)', () {
        final source = _read(path);
        expect(source.contains('AppBar('), isFalse);
        expect(source.contains('SliverAppBar('), isFalse);
      });
    });

    test('the frame is the only place bands are built', () {
      for (final path in _framework.keys) {
        expect(_read(path).contains('Scaffold('), isTrue);
      }
    });

    // Closure. This is what makes the three tables a denylist rather than an
    // allowlist: a new file that builds a Scaffold is in no table, so it fails
    // here on the commit that adds it — not at the next design review.
    test('every file that builds chrome is named in exactly one table', () {
      final listed = {
        ..._onFrame.keys,
        ..._frameless.keys,
        ..._awaitingRuling.keys,
        ..._framework.keys,
      };

      final onDisk = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((final f) => f.path.endsWith('.dart'))
          .where(
            (final f) =>
                _forbidden.any((final c) => f.readAsStringSync().contains(c)),
          )
          .map((final f) => f.path)
          .toSet();

      expect(
        onDisk.difference(listed),
        isEmpty,
        reason:
            'These files build chrome and are in no table. Put each in one: '
            '_onFrame (migrated), _frameless (no bands, with a reason), or '
            '_awaitingRuling (bespoke, with the ruling owed).',
      );
      expect(
        listed.difference(onDisk).difference(_onFrame.keys.toSet()),
        isEmpty,
        reason: 'These files are listed but build no chrome — drop the row.',
      );
    });
  });
}

String _read(final String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is listed but not on disk');
  return file.readAsStringSync();
}
