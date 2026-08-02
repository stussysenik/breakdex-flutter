# Archive note — 2026-08-02 · `unify-text-first-frame-and-icon-vocabulary`

Archived **implementation-complete**: 36/36 tasks ticked, `openspec validate --strict`
clean, gate green at the last task (analyzer 0 errors / 0 warnings, 1451 pass / 3 skip /
0 fail). No task was dropped, deferred, or reassigned.

## What it locked

- **One frame, four bands.** Every roster screen builds `AppScreen`; the frame — not the
  screen — owns the header band, the nav band, the scroll insets, and the back control.
  `BackLeading` and `SettingsScreen.isTab` were deleted rather than adapted: the route
  already knows whether a back exists (`Navigator.canPop`) and whether a nav band exists
  (`NavBandScope`), so no screen may claim otherwise.
- **One sheet.** `showAppSheet` owns `navBandHeight + padding.bottom` in one place; all 24
  `showModalBottomSheet` call sites migrated onto it.
- **One text vocabulary.** `AppRow`/`AppSection`/`AppBreadcrumb`/`AppChoiceList` replaced
  the per-screen hand-rolls; the owner's canonical 8 categories replaced the ad-hoc lists.
- **One icon vocabulary.** Cupertino pack as default under the existing `AppIcon`/`IconPack`
  seam.
- **Morph as default.** `AppMorph` seam with a raw-`Hero` ban.
- **The basis became a control.** `DevBasisScope` + `basisFields` make the grid itself
  draggable in the dev gallery, so a layout ruling can be looked at before it is written.
- **Residency and lineage.** A clip says where it lives and which way it is moving (8.1/8.2);
  a parent introduces itself with its children's faces (`ChildPreviewStrip`, 8.3) — fed by
  a `GROUP_CONCAT` on the walk `watchLibraryRows` already did, so no second query and no
  stream per row.

Spec deltas were applied to `openspec/specs/`: `icon-vocabulary` (created),
`move-categories` (created), `layout-system` (updated).

## NOT PROVEN at archive — owner-gated, not lost

None of this was ever verified as a *look*. Specifically outstanding, and now carried by
`enforce-face-law-conformance` (the successor) and `owner-verification-passes`:

- How the preview strip reads at 40×28 in a real row — preview or clutter — and no strip
  has been watched decoding real footage on a device.
- The residency line and the Morph transition on a real screen.
- Whether a hostile basis (the dev sliders reach values no screen was designed for) stays
  legible.

## The gap it leaves, deliberately

Consistency is proven *by construction* on the migrated screens and by nothing at all on
the rest: raw `Scaffold` under `lib/` went 26 → 11, but no gate holds that number down.
That gate is `enforce-face-law-conformance` 2.1, which is why that change is the successor
on the D8 backlog rather than a parallel track.
