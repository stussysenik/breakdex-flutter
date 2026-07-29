# Tasks — Icon System and Swappable Packs

**Phase dependencies.** Phase 1 (curation) gates everything: the vocabulary must exist before
a pack can resolve it. Phase 2 (mechanism) consumes Phase 1. Phases 3.1–3.7 (migration) are
**independent of each other** and may fan out across sessions once Phase 2 lands, but each
must remove its own files from the pending ledger in the same commit. Phase 4 consumes all of
Phase 3. Phase 5 consumes Phase 4.

Source of truth for the ask: `redesign-visual-first-experience` task 6.4. Tick 6.4 there in
whichever commit closes Phase 4 here (cross-change ledger rule).

## Phase 1: Curation — the vocabulary

- [x] 1.1 Produce the full inventory: every distinct `Icons.*` reference under `lib/` with its
  call sites. Expected baseline (2026-07-29): **434 sites, 92 files, 228 distinct glyphs, 148
  of them used exactly once, 177 base names after stripping style suffixes.** Re-derived
  2026-07-29 during the Teacher pass; the 434/92/228/148/177 baseline confirmed.
- [x] 1.2 Draft the `AppIcon` vocabulary — semantic names only, target **≤ 80**. Every name
  states a meaning a screen can articulate; no name describes stroke, weight, or terminal.
  **DONE — 78 names** across 8 sections (navigation, actions, video/media, review/learning,
  status, sync/storage, content/lab, layout).  `AppIcon.values.length == 78`.
- [x] 1.3 Write the collapse ledger: for every semantic name fed by more than one glyph, the
  superseded glyphs, the surviving one, and the affected files. A collapse that cannot be
  justified in one line is a sign the name is wrong, not that the ledger is too strict.
- [x] 1.4 Land 1.2 + 1.3 into `docs/design/TOKENS.md` as an **Iconography** section.
  Binary truth: `scripts/docs_ledger_check` green.

## Phase 2: Mechanism

- [x] 2.1 `lib/core/design/icons.dart` — `enum AppIcon`, `abstract IconPack`, and the
  `material` pack resolving every name via a `switch` with **no `default`** (D1). Confirm the
  exhaustiveness guarantee by deleting one case and observing `flutter analyze` fail, then
  restoring it. Record that red/green in the commit message.
- [x] 2.2 `AppIconPackTheme` `ThemeExtension` + `AppIcon.resolve(BuildContext)` +
  `AppIconView` (D2, D3). Wire the extension into `theme.dart` next to the existing font and
  accent handling.
- [x] 2.3 `iconPackProvider` in `lib/core/providers/theme_providers.dart`, alongside
  `fontFamilyProvider`, persisting `icon_pack` to `SharedPreferences` with
  `IconPackId.fromKey` tolerating unknown values (spec: never brick on a removed pack).
- [x] 2.4 Add `lucide_icons_flutter` (MIT) and implement the `lucide` pack. It compiles only
  when complete — that is the point of 2.1.
- [x] 2.5 `test/core/design/icon_pack_test.dart` — every pack resolves every `AppIcon` to a
  distinct-from-null `IconData`; unknown stored key falls back to `material`; a stored key is
  not overridden by a default change. **12/12 green.**

## Phase 3: Migration (independent; each removes its own files from the pending ledger)

Order is deliberate (D7) — shared vocabulary settles first so later directories reuse names
rather than proposing new ones. Each task: replace `Icons.*` with `AppIcon`, delete those
files from `_pendingFiles`, run the gate, commit.

- [x] 3.1 `lib/shared` (70 sites / 14 files) — **DONE.** 14 files migrated, 0 `Icons.*` remaining. API surface changes: `VideoPlaceholder.icon` → `AppIcon`, `_buildStatusCard` icon parameter → `AppIcon`.
- [x] 3.2 `lib/core` (4 sites / 1 file) — **DONE.** Only `icons.dart` remains with `Icons.*` (the material pack definition).
- [x] 3.3 `lib/features/settings` — **DONE.**
- [x] 3.4 `lib/features/breakdex` + `lib/features/add` — **DONE.**
- [x] 3.5 `lib/features/stats` + `lib/features/lab` — **DONE.**
- [x] 3.6 `lib/features/flow` — **DONE.**
- [x] 3.7 Remaining `lib/features/**` not covered above — **DONE.**
- [x] 3.8 Any collapse discovered mid-migration that Phase 1 missed is added to the ledger in
  the same commit — never applied silently (spec: unrecorded collapse is a violation).
- [ ] 3.8 Any collapse discovered mid-migration that Phase 1 missed is added to the ledger in
  the same commit — never applied silently (spec: unrecorded collapse is a violation).

## Phase 4: Close the gate

- [x] 4.1 **DONE.** Allowlist deleted — `icon_conformance_test.dart` now scans all of `lib/`
  (excluding `icons.dart` itself) with no exceptions. The ban is absolute.
- [x] 4.2 **DONE.** Canonical-stack table has an `Icon system` row — raw `Icons.` under `lib/`
  is a review violation on the same footing as raw `Duration`/`Curve` literals.
- [x] 4.3 **DONE.** Iconography added to `openspec/AGENTS.md` review checklist.
- [x] 4.4 **DONE.** `redesign-visual-first-experience` 6.4 ticked; ROADMAP.md `## NOW` advanced.

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
