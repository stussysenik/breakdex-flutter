# Tasks — Icon System and Swappable Packs

**Phase dependencies.** Phase 1 (curation) gates everything: the vocabulary must exist before
a pack can resolve it. Phase 2 (mechanism) consumes Phase 1. Phases 3.1–3.7 (migration) are
**independent of each other** and may fan out across sessions once Phase 2 lands, but each
must remove its own files from the pending ledger in the same commit. Phase 4 consumes all of
Phase 3. Phase 5 consumes Phase 4.

Source of truth for the ask: `redesign-visual-first-experience` task 6.4. Tick 6.4 there in
whichever commit closes Phase 4 here (cross-change ledger rule).

## Phase 1: Curation — the vocabulary

- [ ] 1.1 Produce the full inventory: every distinct `Icons.*` reference under `lib/` with its
  call sites. Expected baseline (2026-07-29): **434 sites, 92 files, 228 distinct glyphs, 148
  of them used exactly once, 177 base names after stripping style suffixes.** Re-derive rather
  than trust these; if they have moved, the drift is itself worth a line in the change.
- [ ] 1.2 Draft the `AppIcon` vocabulary — semantic names only, target **≤ 80**. Every name
  states a meaning a screen can articulate; no name describes stroke, weight, or terminal.
- [ ] 1.3 Write the collapse ledger: for every semantic name fed by more than one glyph, the
  superseded glyphs, the surviving one, and the affected files. A collapse that cannot be
  justified in one line is a sign the name is wrong, not that the ledger is too strict.
- [ ] 1.4 Land 1.2 + 1.3 into `docs/design/TOKENS.md` as an **Iconography** section.
  Binary truth: `scripts/docs_ledger_check` green.

## Phase 2: Mechanism

- [ ] 2.1 `lib/core/design/icons.dart` — `enum AppIcon`, `abstract IconPack`, and the
  `material` pack resolving every name via a `switch` with **no `default`** (D1). Confirm the
  exhaustiveness guarantee by deleting one case and observing `flutter analyze` fail, then
  restoring it. Record that red/green in the commit message.
- [ ] 2.2 `AppIconPackTheme` `ThemeExtension` + `AppIcon.resolve(BuildContext)` +
  `AppIconView` (D2, D3). Wire the extension into `theme.dart` next to the existing font and
  accent handling.
- [ ] 2.3 `iconPackProvider` in `lib/core/providers/theme_providers.dart`, alongside
  `fontFamilyProvider`, persisting `icon_pack` to `SharedPreferences` with
  `IconPackId.fromKey` tolerating unknown values (spec: never brick on a removed pack).
- [ ] 2.4 Add `lucide_icons_flutter` (MIT) and implement the `lucide` pack. It compiles only
  when complete — that is the point of 2.1.
- [ ] 2.5 `test/core/design/icon_pack_test.dart` — every pack resolves every `AppIcon` to a
  distinct-from-null `IconData`; unknown stored key falls back to `material`; a stored key is
  not overridden by a default change.

## Phase 3: Migration (independent; each removes its own files from the pending ledger)

Order is deliberate (D7) — shared vocabulary settles first so later directories reuse names
rather than proposing new ones. Each task: replace `Icons.*` with `AppIcon`, delete those
files from `_pendingFiles`, run the gate, commit.

- [ ] 3.1 `lib/shared` (68 sites / 12 files)
- [ ] 3.2 `lib/core` (4 sites / 1 file)
- [ ] 3.3 `lib/features/settings`
- [ ] 3.4 `lib/features/breakdex` + `lib/features/add`
- [ ] 3.5 `lib/features/stats` + `lib/features/lab`
- [ ] 3.6 `lib/features/flow`
- [ ] 3.7 Remaining `lib/features/**` not covered above
- [ ] 3.8 Any collapse discovered mid-migration that Phase 1 missed is added to the ledger in
  the same commit — never applied silently (spec: unrecorded collapse is a violation).

## Phase 4: Close the gate

- [ ] 4.1 `test/core/design/icon_conformance_test.dart`, modelled on
  `frame_conformance_test.dart`: scan `lib/` for `Icons.`, fail with the offending file and
  line. Land it in Phase 3.1 with the full 92-file `_pendingFiles` allowlist; this task is
  where the allowlist reaches empty and is **deleted**, making the ban absolute.
- [ ] 4.2 Add the icon-doctrine row to the `CLAUDE.md` canonical-stack table — raw `Icons.`
  under `lib/` is a review violation on the same footing as raw `Duration`/`Curve` literals.
- [ ] 4.3 Add the iconography line to `openspec/AGENTS.md` review checklist.
- [ ] 4.4 Tick `redesign-visual-first-experience` 6.4 and advance the `ROADMAP.md` `## NOW`
  block in this commit.

## Phase 5: Settings surface and payload

- [ ] 5.1 Icon-pack Settings section on a `/settings-panel*` route, built with
  `settingsSectionPage` so it inherits the 6.3 Fluid + Morph transition. Live side-by-side
  preview of the same representative icons per pack.
- [ ] 5.2 ARB keys for pack names and section copy in `lib/l10n/`; regenerate and commit
  `lib/l10n/gen/`. Binary truth: `scripts/check_l10n.sh` green.
- [ ] 5.3 Widget test: selecting a pack re-renders surrounding chrome from the new pack
  without navigation, and the choice survives a rebuild from persisted prefs.
- [ ] 5.4 **Measure** the `flutter build web --release` size delta from the second icon font,
  with `--tree-shake-icons` active (D6). Report the number in the change. Do not design a
  deferred-loading fallback unless the measurement calls for one.

## Verification

- [ ] V.1 `./verify.sh` green — ledger, `openspec --strict`, docs ledger, l10n, analyzer 0/0,
  full suite.
- [ ] V.2 `flutter build web --release` green, with the 5.4 size delta recorded.
- [ ] V.3 **NOT PROVEN by the above, state it plainly:** how either pack *looks* on a device
  or in a browser, and whether the curated vocabulary reads as handpicked rather than merely
  consistent. That is the owner's judgement and the entire point of the ask. Route it to
  `owner-verification-passes` as an icon-pack sitting rather than claiming it here.
