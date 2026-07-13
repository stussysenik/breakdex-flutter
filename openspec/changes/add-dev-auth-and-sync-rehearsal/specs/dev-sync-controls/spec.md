# dev-sync-controls

## ADDED Requirements

### Requirement: Runtime panel over the per-entity cutover prefs

The system SHALL provide a dev-only panel, gated behind a compile-time flag
(`kDevSyncPanelEnabled`, default OFF), that displays and flips every per-entity dual-write and
dual-read cutover preference at runtime. The panel SHALL source its pref keys from
`SyncService`'s constants (no duplicated key strings) and SHALL display the signed-in user's
identity so the operator knows whose space is being mutated. With the flag OFF the panel and
its entry point SHALL be absent and release behaviour byte-identical.

#### Scenario: Flag OFF removes the panel
- **WHEN** the app is built without `--dart-define=DEV_SYNC_PANEL=true`
- **THEN** no cutover panel or settings entry exists anywhere in the UI

#### Scenario: A toggle flips exactly its pref
- **WHEN** the operator toggles an entity's dual-write switch
- **THEN** exactly that entity's persisted pref changes, the next sync operation honours it, and no other entity's behaviour changes

#### Scenario: Flipping back OFF restores the guard
- **WHEN** an entity's cutover pref is flipped back OFF after being ON
- **THEN** the entity returns to local-only behaviour with no data loss, the same guarantee the kill-switch design promises
