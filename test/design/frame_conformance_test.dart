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
/// [_awaitingRuling] emptied on 2026-08-01, which is what finished §4.4 — and
/// finished 4.5 by deletion, because the guard was already a denylist: a *new*
/// bespoke `Scaffold` fails the closure test today, being a file in no table.
/// The table is kept, empty, so the next ruling has somewhere to be owed.

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

  // Joined 2026-08-01 (§4.4 batch 2), once the frame stopped popping and
  // started asking: the chevron calls `Navigator.maybePop`, so a screen with
  // state to lose declares one `PopGuard` and the same refusal covers the
  // system back gesture. Battle's close was never a layout problem.
  'lib/features/battle/battle_screen.dart':
      'fill form — one screenful, timer above and rating row below; guarded '
      'while a battle is active',
  'lib/core/navigation/app_router.dart':
      'default form — the web degradation for /video-editor is a screen, and '
      'its empty AppBar was only ever a way back; the redirect surface stopped '
      'building a Scaffold, because a frame between two routes is not a screen',

  // Joined 2026-08-01 (§4.4 batch 3). It looked like media chrome, but the
  // category it shows IS an address, and it had a title and a way back — so it
  // is a screen. What is dark is the *content*, not the frame: the media
  // surround and the mode row live inside the content band.
  'lib/features/instax_viewer/instax_viewer_screen.dart':
      'fill form — a dark content band over one category, with the view-mode '
      'row inside that band because it is a control over the media',

  // Joined 2026-08-01 (§4.4, last item). It was the one file carrying two
  // verdicts: a prescreen on the frame and an immersive session that took the
  // whole viewport, chosen by a provider inside `build`. The session moved to
  // `drill_session_screen.dart`, so each file now answers the question once.
  'lib/features/flashcard_review/flashcard_review_screen.dart':
      'fill form — the Drill tab picks what to practise; when a session starts '
      'it renders the frameless session widget instead',
};

/// Surfaces with **no** bands at all, on purpose. Frameless is not an exemption
/// from the constitution; it is a different decision, and it costs a reason.
///
/// The bound is the same for every one of them: a frameless surface may own a
/// `Scaffold` (it needs the Material surface) and may **never** own an `AppBar`.
/// A header is the band that drifted five times; it is the band nobody gets to
/// re-declare, framed or not.
const _frameless = <String, String>{
  'lib/features/flashcard_review/drill_session_screen.dart':
      'the card is the surface: one clip filling the viewport, with no address '
      'to show and no band to tap away from. The way out is the card\'s own '
      'end control, which asks first. Split out of the Drill tab on 2026-08-01 '
      'so that file could take a single verdict.',
  'lib/features/auth/appwrite_login_screen.dart':
      'the door, not a room: pre-auth, outside the shell, with no crumb address '
      'to show and nowhere to go back to.',

  // Ruled 2026-08-01 (§4.4 batch 2). One question settled five of these: is
  // this a *screen* — something with an address, a title, and a way back — or
  // a surface the media itself owns? Playback is the media; the frame's bands
  // would sit on top of the thing being watched.
  'lib/shared/widgets/quick_video_viewer.dart':
      'full-bleed playback: black surround by design, dismissed by tapping the '
      'video it is showing, and it has no address to put in a crumb.',
  'lib/shared/widgets/video_player_widget.dart':
      'the fullscreen playback route the player pushes for itself; same ruling '
      'as the quick viewer, and it lives inside the player it belongs to.',
  'lib/shared/widgets/metadata_video_picker_sheet.dart':
      'a sheet, not a screen — bounded by the §3 measure `showAppSheet` owns. '
      'Its Scaffold is the sheet body, which is why it has no bar.',
  'lib/dev/preview_harness.dart':
      'the harness renders other screens, so its Scaffold is the wall the '
      'picture hangs on. Bands here would be a second frame over the framed.',
  // Ruled 2026-08-01 on merge. The gallery arrived from a parallel session with
  // an AppBar and failed the closure test on the merge commit — which is the
  // test doing its job: it caught a file no table knew about, at the moment it
  // entered `lib/`. Its bar looked like an address, but every card in its list
  // renders a *framed* screen at 420pt, so it is the harness's case exactly:
  // the wall, not a picture. The bar became a title inside the content.
  'lib/dev/dev_preview_gallery.dart':
      'a wall of framed screens; same ruling as the harness it lists. Its title '
      'and brightness switch are content, because a band here frames the frames.',
  'lib/main.dart':
      'the boot-failure surface: it exists precisely when the app did not, so '
      'there is no shell, no router and no frame to build it from.',

  // Ruled 2026-08-01 (§4.4 batch 3). An editor is not a screen: it is a
  // full-bleed surface that owns a video and holds unsaved work, and its bar
  // is a transaction — discard or save — not an address. This is the one
  // Scaffold in the cluster; `simplified_video_editor_screen.dart` used to
  // build a second one inside it and now builds no chrome at all, which is
  // why it is in no table.
  'lib/features/video_editor/video_editor_screen.dart':
      'the editing surface both editors share: no bands, one Material surface, '
      'and a FAB that switches which editor is on it.',
};

/// Empty, as of 2026-08-01 (§4.4 batch 3). Every ruling owed has been made.
///
/// The last three were settled by one question the earlier batches had already
/// asked twice: what is this bar *for*? An address — where you are, and the way
/// back up — makes it a screen, and the frame owns it. A transaction — abandon
/// or keep the work in front of you — makes it a control, and the surface owns
/// it. Instax was an address (a category), so it went on the frame and kept its
/// darkness in the content band. Both editors were a transaction, so they went
/// frameless, and the shell now holds the cluster's single Scaffold instead of
/// wrapping a second one.
///
/// The table stays, empty, as the place the next ruling gets written down.
const _awaitingRuling = <String, String>{};

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
