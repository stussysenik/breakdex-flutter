# Breakdex — Agent Contract

Canonical, load-bearing rulings for any agent working in this repo. Read this first; it names
the decided stack so you don't re-derive ground truth every session. Global craft mandate
(`~/.claude/CLAUDE.md`, `~/CLAUDE.md`) still applies and takes precedence where it conflicts.

## Canonical stack — LOCKED

| Concern | Ruling | Notes |
| --- | --- | --- |
| Canonical backend | **Appwrite** (open-source, self-hostable) | Decided 2026-07-05 after grilling. Supersedes Convex and Firebase/Firestore. Spec: `openspec/changes/migrate-canonical-backend-to-appwrite`. Phase H done (`phase-h-hardening`); Phase 0 provisioning is NEXT, owner-gated. |
| Local source of truth | **Drift / SQLite** stays canonical on-device | The backend is a shadow copy until each entity's reconcile is verified. Video bytes stay on **Google Drive** (pointers only in the backend). |
| Sync model | **Record-level LWW + tombstones**, plus a **dirty-guard** | While a record's editing machine is dirty, inbound realtime updates are held and applied only on save/discard — keystrokes are never clobbered mid-edit (align-cross-client-foundations D6). |
| User model | **Private per-user sync** | Any Google sign-in gets an isolated space on their own Drive quota; local-only users keep working untouched; owner (senik456) is just user #1. No cross-user sharing. |
| Flutter state architecture | **`Machine<S,E>`** (zero-dep sealed-class framework) | `lib/core/state_machines/machine.dart`, wired into production screens. It IS this codebase's TCA-equivalent. Do not replace it. |
| Web client | **Next.js 15** (React) + **XState v5** | In-repo `web-mirror/`. Each web machine mirrors its Flutter counterpart 1:1 (same states/events/guards, different runtime). |
| Design tokens | **`docs/design/TOKENS.md`** is the single source | `lib/core/design/*.dart` and web `tokens.css` both conform. Conformance is a review-checklist item; codegen deferred until a third consumer. Grid: 8pt base / 4pt half-step. Type: Inter. |
| Roadmap | **root `ROADMAP.md`** is the ONE roadmap | `docs/ROADMAP.MD` + `docs/PROGRESS.MD` were folded in and removed (2026-07-06). |

## Non-goals — do NOT build these

- **E2EE** — server-derived FSRS (Dart Appwrite Function) and web-studio rendering need
  server-readable plaintext. Posture is transport + secrets hygiene + per-user document
  permissions, not end-to-end encryption.
- **Temporal / any durable-workflow engine** — idempotent LWW ops, cursors with rollback
  (Phase H), the upload spool, and Appwrite Functions already cover durability.
- **CRDTs** — single-user private spaces; LWW is sufficient (re-affirmed rejected).
- **Shared/collaborative state** (crews, coaches, cross-user sharing) — deferred entirely.

## Security posture (transport + secrets hygiene)

- TLS everywhere; Appwrite at-rest encryption accepted as-is.
- Mobile: OAuth/session tokens in platform secure storage (`flutter_secure_storage` / Keychain),
  never `SharedPreferences`.
- Web: Appwrite session via **httpOnly cookies**; no tokens in `localStorage`.
- Google Drive scope minimized to file-level (`drive.file`) already in use; no broad `drive` scope.
- `.env` conventions carry cloud + self-host keys; keys are never committed.

## Ledger rule (same-commit ticking)

A change's `tasks.md` checkboxes MUST be ticked in the **same commit** that lands the
corresponding work. A pending change whose tasks materially contradict shipped code is a
review violation to reconcile before new work builds on it. (This rule was introduced by
`align-cross-client-foundations`; the 0/51-vs-shipped drift in `state-machine-crud` is the
canonical example it fixed.)

## Where to look

- **Backlog / sequencing:** root `ROADMAP.md` → "Backlog — OpenSpec change order (D8)".
- **Design tokens:** `docs/design/TOKENS.md`.
- **OpenSpec conventions:** `openspec/AGENTS.md`. Drive non-trivial work through `openspec/`.
- **Brownfield constraint:** late-stage production with real users + data — additive over
  invasive, never delete/orphan user state, migrations one-way and tested, verify on a real
  build before claiming done.
