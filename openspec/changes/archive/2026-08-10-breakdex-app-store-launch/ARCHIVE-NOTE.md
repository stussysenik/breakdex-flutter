# Archive note — 2026-08-10 — breakdex-app-store-launch

**Verdict: SUPERSEDED.** Not abandoned — its substance is already owned by two other
changes, and the launch itself is downstream of a locked ruling.

## Why it is archived

The change parked a 2026-07-30 `.triage` ruling:

> *"iOS/Android store launch is downstream of the locked 'web-first, iOS after web soak'
> ruling; its data-integrity and UX halves are already owned by `add-media-manager` and
> `add-web-first-release-and-monetization`. Repair the template when web soak closes and
> this becomes active, never in bulk."*

That ruling is still live: web soak has not closed, and the two halves are still owned
elsewhere. Writing a standalone launch spec now would duplicate work and re-open a
settled decision. The supersession is recorded here so the board stops re-asking.

## Where the work survives

| Half | Owned by | Status |
| --- | --- | --- |
| Data integrity / media / hashing / dedup / export | `add-media-manager` | QUEUED 0/36 |
| Release, pricing, monetization, web-first launch | `add-web-first-release-and-monetization` | WIP 28/39 |
| Store-specific submission (screenshots, provisioning, IAP) | **unowned** | falls out when the two above land + web soak closes |

The store-submission specifics (screenshots, provisioning profiles, App Store Connect
config, IAP setup) are **not** duplicated in either surviving change today. They become
a spec in their own right only after web soak closes — at point the parked ruling lifts
and a fresh change can be written on current facts rather than on this 2026-07-30 draft.

## What to do when web soak closes

Do not un-archive this draft. Its pricing ($10 one-time) and platform assumptions are
13+ days old and predate the locked monetization rulings. Write a new change grounded
in the then-current state, scoped to store submission only, once the two owner changes
are shipped.
