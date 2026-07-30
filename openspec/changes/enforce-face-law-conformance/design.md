# Design — Enforce Face Law Conformance

## Gate-first vs migrate-first

Two orders were possible: migrate all 26 screens then add the gate, or land the gate first
with a seeded allowlist and shrink it per batch. Gate-first wins — it is the proven shape of
`color_conformance_test.dart` (an allowlist that admits only what is justified, with a
second assertion deleting stale exemptions), it makes every migration commit provable alone
(atomicity, loss-function term 2), and it stops the count from growing while the pass runs.
Migrate-first leaves a window where a 27th raw Scaffold lands unnoticed.

## Why the essentialist rules are claims, not adjectives

"Minimalist" is not checkable; "one primary action per content band" is. Each Face Law rule
is written so a reviewer (or a grep) returns yes/no:

| Rule | Check |
|---|---|
| One frame | `layout_conformance_test.dart` (machine) |
| One primary action per content band | review checklist, countable on the diff |
| Monochrome carries; color marks state | already machine-gated (`color_conformance_test.dart`) |
| A control shows the value it holds | review checklist item, per control |
| A new chrome control displaces one | diff states the displaced control or the reason |
| Density tokens only | `AppLayout` / TOKENS.md scale; raw dimension literals in chrome are violations |

The subtraction rule is the Light Phone mechanism made procedural: chrome control count per
screen can only grow when the diff argues for it, which biases every future change toward
subtraction without requiring taste from the executor.

## Platform adaptation by defaults, not forks

The tension: "as native as we can per platform" vs "one codebase, one frame" (portability,
loss-function term 1). Resolution: nativeness comes from what the platform already provides
— scroll physics (`ScrollConfiguration` platform defaults), back gesture (predictive
back / edge swipe as Flutter surfaces them), safe areas (already band 1 of `AppScreen`),
system text scaling. These cost zero per-screen code and cannot drift. Anything beyond
defaults (haptics richness, native context menus) is either a token-level adaptation applied
once in the frame, or a named visible gap. A second layout per platform is rejected outright
— it regresses term 1 to improve nothing higher.

Mobile-first means composed and reviewed at 390pt logical width first; the 720pt reading
clamp (`AppLayout`, already tokened) is the only wide-viewport behavior. This is why the web
release transfers to iOS by default: the phone layout IS the layout.

## Sittings on the derived board

Valoric's D69 split (`next` = agent-workable, `parked` = owner, filed by sitting) maps onto
Breakdex's existing `owner-verification-passes` change: its tasks each get a sitting tag
(`DEVICE` / `REVIEW` / `DECIDE`), and `status.sh` groups by tag at read time. Derived, never
stored — no new state file, consistent with the board's read-only contract. The registry of
sittings is closed; adding one is an owner decision.

## What stops distillation here

The allowlist cannot start empty (26 screens exist), so the gate ships with debt on its
face — the shrink-only assertion is what makes that honest. Stopping short of deleting the
allowlist entirely in this change is deliberate: batches are owner-review-gated, and the
final zero is a fact the ledger reaches, not one this spec can promise.
