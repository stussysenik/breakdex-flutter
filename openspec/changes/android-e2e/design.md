# Android And Device Testing Design

See umbrella change `engineer-workflow-and-multi-user-foundation/design.md` for context.

## D1 — "Argent" is not an Android device farm; it never was

The umbrella change's Open Questions asked whether "Argent" named "a local script, an
external service, or a to-be-created wrapper." None of the three. It is
**`@swmansion/argent`** (Software Mansion, v0.15.0) — an **MCP agentic toolkit** where the
executing model *is* the test runner, not a YAML suite and not a hosted device farm. It was
ruled in `add-dev-auth-and-sync-rehearsal` (D6) and is scoped in
`docs/sync-rehearsal-runbook.md` §"Smoke driver" to the **iOS simulator + web** rehearsal
ladder only. It has no Android leg in this repo, and no `argent init` config is committed
yet (that is task 3.3 of `add-dev-auth-and-sync-rehearsal`, still unticked).

Consequence: nothing in Phase 6 waits on argent, and no device-farm account, provider, or
wrapper needs to be selected or paid for.

## D2 — Maestro is the Android driver, and the suite already exists

`maestro` 2.1.0 is installed (`~/.maestro/bin/maestro`) and **48 flow files are already
committed under `.maestro/`** — `config.yaml` (appId `com.breakdex.breakdex`, `clearState`
per flow, tag groups `smoke` / `review` / `video` / `stress` / …) plus flows covering
navigation, arsenal CRUD, review sessions, video import/playback/export, settings, and a
16-flow stress tier. Fixture seeding is a real in-app seam:
`lib/core/services/automation_fixture_service.dart` reads the `breakdexFixture` launch
argument that the flows pass via `launchApp: arguments:`.

So 6.3 is **not greenfield authoring** — it is re-validating an existing suite. Caveat on
the record: the newest flow was last touched in `dc93ba6` (2026-06-30), *before* the
visual-first redesign landed. The same staleness class that produced
`docs/stale-tests-post-redesign.md` should be assumed here until a run proves otherwise;
6.2's smoke gate is what produces that proof.

## D3 — Patrol is a declared, unused dependency

`pubspec.yaml` carries `patrol: ^4.6.1` and a `patrol:` config block (app name, Android
package, iOS bundle id), but there is **no `integration_test/` directory** — zero Patrol
tests exist. Patrol stays declared and unused for now: it is the escape hatch for flows
Maestro's black-box driver cannot reach (native permission dialogs, OAuth WebView
handoff), which is exactly the auth-entry leg of 6.3. Do not author Patrol tests
speculatively; add one only when a named flow proves un-drivable by Maestro. If 6.3
finishes without needing it, dropping the dependency is the correct cleanup.

## D4 — The device matrix is local, and Android release artifacts stay owner-gated

Android SDK, `adb`, and `emulator` are present; no emulator is currently booted. The 6.4
matrix is therefore *local emulator + the owner's physical device*, recorded as an
artifact in this change — not a farm run across a rented fleet.

Separately, `android/app/build.gradle.kts` still resolves the `release` build type to
`signingConfigs.getByName("debug")`. A release APK builds and runs, but it is debug-signed
and **not Play-uploadable**. Producing a real keystore is an owner step (`keytool` plus
credentials that must never be committed); Phase 6 can complete its smoke and matrix work
against the debug-signed artifact, and Android *distribution* readiness stays blocked on
that owner step.
