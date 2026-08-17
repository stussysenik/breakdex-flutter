# sync-activation

Production first-login provisioning so a real user's library shadows to Appwrite on
first sign-in, plus the owner-provisioned offering config that lets paid web flows ship
without a hardcoded Lemon Squeezy id. Local Drift is the source of truth; Appwrite is the
shadow replica. Identity is the Appwrite `userId`.

This spec is self-contained: it depends only on already-shipped surfaces
(`SyncService` pref keys, `SyncBackfillService` per-entity `backfill*()` methods, the
`hydrateOnLoginTriggerProvider` trigger pattern, `currentAppwriteUserProvider`,
`SharedPreferences`). It does NOT depend on remote-config live-flip (Phase M.5) — that is
a separate follow-up. Safe default: with no Appwrite session the trigger is a no-op and
the app is byte-identical to today; with no offering id the paid flow is disabled.

## ADDED Requirements

### Requirement: First-login provisioning trigger
The system SHALL run a one-shot provisioning pass the first time an Appwrite session
is established for a given `userId`, guarded by a per-user one-shot flag, so that
re-launches and re-logins never re-trigger an automatic backfill. The trigger SHALL
follow the `hydrateOnLoginTriggerProvider` pattern (watch `currentAppwriteUserProvider`,
defer via microtask, swallow all throws so it never blocks app entry).

#### Scenario: First login triggers provisioning
- **WHEN** a user establishes an Appwrite session and `sync.provisioned.$userId` is unset
- **THEN** the system runs the full backfill for all 8 entities, flips dual-write and
  dual-read ON for every entity, and sets the one-shot flag

#### Scenario: Re-login is a no-op
- **WHEN** a user establishes an Appwrite session and `sync.provisioned.$userId` is already set
- **THEN** the system performs no backfill and leaves the (already-on) prefs unchanged

#### Scenario: Distinct users each provision once
- **WHEN** a second Appwrite `userId` signs in on the same device
- **THEN** that user provisions independently under its own one-shot flag, isolated from
  the first user's space

#### Scenario: Trigger never blocks app entry
- **WHEN** the backend is unreachable or the provisioning pass throws
- **THEN** the failure is swallowed (logged, not thrown), dual-read/dual-write prefs stay
  OFF, the one-shot flag stays unset, and the next launch retries cleanly

### Requirement: SyncService.activateSync() — all-or-nothing activation
`SyncService` SHALL expose `activateSync()`: compose the eight `SyncBackfillService`
backfill calls (`backfillMoves`, `backfillCombos`, `backfillComboMoves`,
`backfillReviews`, `backfillDecks`, `backfillDeckMoves`, `backfillMoveNoteEntries`,
`backfillComboNoteEntries`) against the `fullBackfillServiceProvider`; on success flip
every dual-write and dual-read pref ON via the batch setters; if any backfill throws, NO
pref is changed and the exception propagates to the caller's catch.

#### Scenario: Success flips every entity's prefs
- **WHEN** `activateSync()` completes without throwing
- **THEN** dual-write is ON for moves, combos, reviews, decks, noteEntries and dual-read
  is ON for moves, combos, reviews, fsrsCards, decks, noteEntries

#### Scenario: Failure leaves prefs untouched
- **WHEN** `activateSync()` throws during backfill
- **THEN** no dual-write/dual-read pref is changed and the exception propagates

### Requirement: SyncService batch pref setters
`SyncService` SHALL expose `setDualWriteAll(bool)` and `setDualReadAll(bool)` that write
the per-entity pref keys already defined on the class, so a production path can flip every
entity at once without the dev panel. `setDualWriteAll` skips `fsrsCards` (derived
server-side, no write key).

#### Scenario: setDualWriteAll(true) flips every write key
- **WHEN** `setDualWriteAll(true)` is called
- **THEN** `sync.moves.dualWrite.enabled`, `sync.combos.dualWrite.enabled`,
  `sync.reviews.dualWrite.enabled`, `sync.decks.dualWrite.enabled`,
  `sync.noteEntries.dualWrite.enabled` are all `true`

#### Scenario: setDualReadAll(true) flips every read key
- **WHEN** `setDualReadAll(true)` is called
- **THEN** `sync.moves.dualRead.enabled`, `sync.combos.dualRead.enabled`,
  `sync.reviews.dualRead.enabled`, `sync.fsrsCards.dualRead.enabled`,
  `sync.decks.dualRead.enabled`, `sync.noteEntries.dualRead.enabled` are all `true`

### Requirement: Provisioning writes to the signed-in user's isolated space
The system SHALL stamp all backfilled rows with the signed-in `userId`'s per-user
permissions, and all reads SHALL filter to that `userId`, so no user can read or write
another's rows.

#### Scenario: Owner provisions under the Google identity
- **WHEN** the owner signs in with Google and provisioning runs
- **THEN** every backfilled row is owner-only permissioned to that `userId` and is
  invisible to any other user

#### Scenario: Idempotent replay
- **WHEN** provisioning (or a manual backfill) runs a second time for the same user
- **THEN** rows are reconciled by logical `(userId, id)` with last-writer-wins and no
  duplicate rows are created

### Requirement: One-shot flag is durable per userId
The one-shot flag SHALL be persisted in `SharedPreferences` under
`sync.provisioned.$userId` so it survives app restarts and is scoped per user, not per
app session.

#### Scenario: Flag persists across restart
- **WHEN** provisioning completes, the app is killed, and the same user signs in again
- **THEN** the trigger reads the persisted flag, finds it set, and skips provisioning

#### Scenario: Flag is per-user, not per-session
- **WHEN** user A provisions (flag written), then user B signs in on the same device
- **THEN** user B has no flag (`sync.provisioned.<B>` is unset) and provisions independently

### Requirement: Offering ids are owner-provisioned, never hardcoded
The system SHALL read Lemon Squeezy offering ids from owner-supplied build-time config
(`--dart-define=OFFERINGS_JSON`), never from literals in implementation code. When the
config is absent or malformed, paid purchase flows SHALL remain disabled or hidden and no
checkout can start with a placeholder id.

#### Scenario: Offering ids configured and present
- **GIVEN** offering ids are supplied via `--dart-define=OFFERINGS_JSON`
- **WHEN** the purchase flow builds
- **THEN** it resolves the configured offering id per tier and renders the paid path

#### Scenario: Offering ids absent (safe default)
- **GIVEN** no offering id is supplied
- **WHEN** the purchase flow builds
- **THEN** paid flows are disabled or hidden and no checkout can be initiated with a
  placeholder id

#### Scenario: Malformed config degrades safely
- **GIVEN** the env value is malformed JSON or missing a required tier
- **WHEN** the config is resolved
- **THEN** it returns absent for the affected tier (never throws, never substitutes a
  guess) and that tier's paid flow is disabled

## MODIFIED Requirements

### Requirement: SyncService activation API is additive
The system SHALL add `setDualWriteAll`/`setDualReadAll` and `activateSync()` to
`SyncService` as new APIs only. The class currently exposes per-entity dual-write/dual-read
pref *keys* as constants and per-entity read helpers, but NO batch setter or activation
method; this modification adds them without removing or changing the semantics of any
existing pref key.

#### Scenario: Existing per-entity behavior unchanged
- **WHEN** existing code reads `SyncService.movesDualReadPrefKey` or any existing getter
- **THEN** behavior is byte-identical; only new methods are added
