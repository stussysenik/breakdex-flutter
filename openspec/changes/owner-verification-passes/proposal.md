# Owner Verification Passes

## Why

Several changes are 90%+ implemented but **cannot ever close**, because every remaining task
needs a physical device, live credentials, or a hosting console — none of which an agent has.
They therefore sit in the queue forever, indistinguishable from genuinely unfinished work:

| Change | Ticks | What actually remains |
| --- | --- | --- |
| `foundation-data-resilience` | 59/64 | 10.3–10.7: migration on a real user DB, Photos album discovery on device, pinch-feel, video under poor network, whole-app regression sweep |
| `add-web-mirror-player` | 19/26 | 0.3/0.4/1.4/5.1–5.4: Google Cloud web OAuth client, `vercel login`, Drive manifest on a real build, preview deploy + owner Drive validation, promote to prod |
| `redesign-add-tab-with-move-combo-choice` | 19/27 | 5.1–5.6: hands-on verification that move/combo creation, duplicate-name checks, haptics, and the beat grid behave on a real build |

This mislabels the board twice over. It reports work as undone when it is really
*unverified*, and it hides the genuinely undone work behind a wall of tasks no session can
action. The owner's standing rule is that device testing happens in their own dedicated
session — so these tasks are not merely blocked, they are **addressed to a different actor**.

Collecting them in one place makes the queue honest: every other change becomes something a
session can actually finish, and the owner gets a single checklist for one device sitting.

## What Changes

- **A single owner-facing verification change** absorbs every device/credential/console-gated
  task from the changes above, grouped by the sitting required (device session, Google Cloud
  console, Vercel console) rather than by originating change — because that is how the owner
  will actually execute them.
- **The parent changes archive as implementation-complete**, each recording where its
  verification went. Their code shipped; only proof is outstanding.
- **A standing rule** (CLAUDE.md → Queue doctrine): a task an agent structurally cannot close
  belongs here, tagged at the moment it is written, never left to rot in a parent change.

This change is **never "done"** in the normal sense — it is a durable owner checklist that
grows as new gated tasks appear. It is exempt from the staleness verdict for that reason.

## Capabilities

### New

- `owner-verification`: the contract for how agent-unclosable tasks are recorded, routed to
  the owner, and reported against.

## Non-goals

- **Not a place to park hard work.** Only tasks that are *structurally* agent-impossible
  belong here — needing a physical device, owner credentials, or a hosting console. "Difficult",
  "slow", or "needs care" are not qualifications.
- No agent may tick a box in this change. Ticks here are the owner's alone.
