# Tasks — Owner Verification Passes

**Only the owner ticks these boxes.** Grouped by the sitting required, not by originating
change, because that is how they get executed. Each task names its source so provenance
survives the move. Registry: `DEVICE` / `REVIEW` / `DECIDE` / `SCHOLAR`.

## 1. Device session — iOS/Android build in hand

- [ ] [DEVICE] 1.1 Run the v14→v15 database migration against a **copy of a real user database**;
       confirm no row loss and no orphaned media. (`foundation-data-resilience` 10.3)
- [ ] [DEVICE] 1.2 Photos album discovery end-to-end on a physical iOS device with a real library
       containing Breakdex albums in **mixed case**. (`foundation-data-resilience` 10.4)
- [ ] [DEVICE] 1.3 Pinch-to-zoom feel on device — confirm no oversensitivity.
       (`foundation-data-resilience` 10.5)
- [ ] [DEVICE] 1.4 Video loading under poor network: mobile data, airplane-mode toggle mid-load.
       (`foundation-data-resilience` 10.6)
- [ ] [DEVICE] 1.5 Regression sweep — move list, combo creation, flashcard review, video editor all
       still behave after the resilience work. (`foundation-data-resilience` 10.7)
- [ ] [DEVICE] 1.6 Move creation end-to-end from the Add tab: video picker → metadata → save, with
       count. (`redesign-add-tab` 5.1)
- [ ] [DEVICE] 1.7 Combo creation launches and returns to the Add tab after save. (`redesign-add-tab` 5.2)
- [ ] [DEVICE] 1.8 Duplicate-name checking still works for moves. (`redesign-add-tab` 5.3)
- [ ] [DEVICE] 1.9 Haptics fire on category selection and submission. (`redesign-add-tab` 5.4)
- [ ] [DEVICE] 1.10 Beat grid renders correctly across varying move counts, and its toggle
       hides/shows the overlay. (`redesign-add-tab` 5.5, 5.6)
- [ ] [DEVICE] 1.11 Drive manifest proof: confirm an updated `manifest.json` (with notes/plans) lands
       in the Drive `Breakdex/` folder on a real build with Drive auth.
       (`add-web-mirror-player` 1.4)
- [ ] [DEVICE] 1.12 Open-with proof on real iOS and Android: Files → Breakdex lands on the right move.
       (`add-capture-and-pro-metadata` 5.3 — pending that change shipping)

## 2. Google Cloud console

- [ ] [DECIDE] 2.1 Create a **Web application OAuth client** in the existing project; add Vercel and
       `localhost` to JS origins / redirect URIs. (`add-web-mirror-player` 0.3)

## 3. Vercel console — dev-utility deploy

> Ranked below the product. `web-mirror/` is the owner-only dev utility, not the consumer
> app (CLAUDE.md → Canonical stack). Do this when the harness is wanted, not before.

- [ ] [DECIDE] 3.1 `vercel login` and link the web project. (`add-web-mirror-player` 0.4)
- [ ] [DECIDE] 3.2 Set env vars, deploy a **preview**, validate sign-in and the full mirror against the
       owner's real Drive. (`add-web-mirror-player` 5.1)
- [ ] [DECIDE] 3.3 Confirm non-owner rejection, and that every Drive call is a read
       (network inspection). (`add-web-mirror-player` 5.2)
- [ ] [DECIDE] 3.4 Promote to production and record the URL. Provisioning and deploy steps already
       exist in `web-mirror/README.md`. (`add-web-mirror-player` 5.3)

## 4. Android release signing

- [ ] [DECIDE] 4.1 `keytool` keystore + Gradle signing config so `scripts/distribute.sh android-aab`
       produces a Play-uploadable artifact. Today's release APK builds but is **debug-signed**.
       (Carried from the `android-e2e` NOW block.)

## 5. iOS distribution

- [ ] [DECIDE] 5.1 Signing, provisioning profiles, and App Store credentials for
       `scripts/distribute.sh ios-ipa`. External state by definition — see CLAUDE.md
       "Distribution and update scriptability".

## 6. Design sittings

- [ ] [REVIEW] 6.1 Confirm the frame reads as **one viewport** when switching tabs on a real build:
       the title sits at the same height on all five tabs, content's first pixel is at the same
       `y`, and nothing feels top-anchored that used to be centred (`breakdex`'s hero tiles are
       the one to watch). Web additionally: the 720/1080 clamp should centre the column on a
       wide monitor rather than stretching it. (`add-stacked-viewport-layout` V.4)
- [ ] [REVIEW] 6.2 Patrol journey on a real device, iOS + Android: open library → cycle the 3 view modes
       → pick a device video already in Breakdex → land on the existing move → run one review
       card without scrolling. Needs devices/simulators; cannot run headless. No
       `integration_test/` directory exists yet, so authoring the journey is part of the task.
       (`redesign-visual-first-experience` V.2)
- [ ] [REVIEW] 6.3 **Visual review of the `/add` flow previews**, now that the widget-preview harness runs
       on web again (`add-web-first-release-and-monetization` 1.0.6 fixed the missing wasm VFS).
       Run `flutter widget-preview start -d chrome` and read group `add` in order: `1 · AddScreen`
       → `2 · VideoPickerSheet` (incl. `re-pick`) → `3 · ClipMetadataForm` (incl. `empty name`),
       each in light and dark. The previews are *proven to build* with no exceptions; whether they
       read as one flow and hold the density/labelled-icon bars is the owner's call, which is why
       it lives here rather than in the parent change (`redesign-visual-first-experience` 6.11).
       Two known non-blockers in the same run, tracked as `redesign-visual-first-experience` 6.13:
       the battle/party previews throw (`RenderFlex` overflow in `battle_intro.dart`, a missing
       `PartyBloc` ancestor) and the 3D panel cannot render on web at all.
