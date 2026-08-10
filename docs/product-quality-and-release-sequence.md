# Product Quality & Release Sequence

> Captured 2026-08-10. This is the **goal + sequence** so future sessions don't
> re-litigate priorities. The board (`ROADMAP.md` ## NOW) is the queue; this doc is
> the *why* and the *order*. Work one slice to done, commit, then advance.

## The goal

Breakdex ships as a **consistent, tested, 3-platform product** (Web #1, iOS #2,
Android #3) with a **decoupled, scalable architecture**:

- **One design ideology.** Every screen is `AppScreen`; every token resolves from
  `TOKENS.md`; color/typography/spacing/radius/depth/motion have zero raw literals
  in `lib/`. Face Law is a conformance gate, not a vibe. (Mechanism, not prose.)
- **Same user, same data, managed storage.** Per-user isolation is proven (not
  assumed); the user's data + media are reachable across surfaces; storage locations
  are managed, not scattered.
- **Frontend decoupled from backend.** Sync/storage behind swappable providers; adding
  a provider or a hosting surface is a new impl, not a rewrite. Separation of
  concerns at every layer (UI → intent → state → repo → sync → backend).
- **Photo picker + loading actually work.** The class of defect that ships is the one
  you don't see on the author's device — fix it where it hides (slow device, bad
  network, permission edge cases).
- **Apple HIG / platform sense** where it doesn't cost portability (the #1 loss term).

## The honest constraint

This is a **program of weeks**, not a session. The 200k-token ceiling and the atomic
change rule exist *because* "do everything" asks churn and ship nothing. So this doc
is a **sequence of bounded slices** — each one lands, gates, and reverts by itself.
We work the first slice to done *now*; the rest wait their turn. No slice starts
until the prior one is green.

## The sequence (ordered by leverage — what unblocks the most downstream work)

| # | Slice | Why this order | Status |
|---|-------|----------------|--------|
| 1 | **`add-design-system-showcase`** — one-page dense composite of all TOKENS.md rules, live token render, brightness×palette matrix, web-first | Proves the design system is *real and consistent* in one shot; the page that showcases itself incorrectly is the defect it exists to prevent. Unblocks every future "is this consistent?" question. | FRESH spec — safe to build |
| 2 | **Consistency audit + photo-picker/loading fix pass** — conformance-test every feature screen against Face Law; fix the photo picker and loading defects the showcase's "least eye travel" layout will expose | The showcase (slice 1) is the instrument that *reveals* inconsistency; this slice fixes what it reveals. | NOT YET SPECCED — derive scope from slice 1's findings |
| 3 | **`distribution-web`** — offering config resolve ladder, invite-mint Function, release-handoff doc + rollback | Web is the #1 product surface and the released consumer app. Money + deploy = needs the consistency + reliability of slices 1–2 first. | FRESH spec — safe to build |
| 4 | **`multi-user-sync`** — private-per-user isolation proof + honest NOT PROVEN ledger | Proves the locked per-user model; the others build on that assumption. Mostly doc + loopback tests (cheap, high-signal). | FRESH spec — safe to build |
| 5 | **3-platform release gate** — web build green, iOS build green, Android build green; platform-specific guards named, gaps visible | Distribution act, not a dev loop. Owner-gated where signing/credentials are external. | NOT YET SPECCED — run `scripts/distribute.sh` as the spec |

## What was removed from this sequence (and why)

- `reverse-album-delete-archive` — **archived 2026-08-10** as stale: implementation
  already exists in code (`ManagedAlbumReconciliationService`, `recently_deleted_screen`,
  archive columns), spec task list was fiction. The code is the source of truth; if the
  remaining gaps (30-day purge, sync-state) need work, re-derive from the code.
- `add-self-healing-video-reliability-runtime` — **archived 2026-08-10** as stale:
  `VideoReliabilityRuntime` is fully implemented and wired; spec task framing diverged
  from it. Code is source of truth.

## How a session uses this doc

1. Read the board (`./status.sh`) → `## NOW` names the active change.
2. If `## NOW` points at a slice above, build exactly that slice's next unticked task.
3. If a slice is "NOT YET SPECCED," the session is Teacher lane — write the spec, don't
   implement. (Spec-only is the default lane.)
4. Done = the slice's gate is green, ticked in the same commit, `## NOW` advanced,
   `session.log` appended. Then stop — don't grab the next slice in the same session.

## Standing bars (never trade these away)

1. Portability (#1 loss term) — one codebase, three surfaces; degrade visibly, not invisibly.
2. Atomicity — each slice lands, gates, reverts alone.
3. Compile speed — web is the default dev loop; device is for questions web can't answer.
4. Binary truth — no tick without terminal-verified evidence; NOT PROVEN is always named.
