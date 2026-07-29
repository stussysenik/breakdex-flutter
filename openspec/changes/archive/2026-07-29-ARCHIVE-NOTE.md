# Archive note — 2026-07-29 queue reconciliation

Owner-directed triage. Seven changes left the active queue. None of this work was
"abandoned"; it was written under architecture rulings the repo has since replaced,
and it kept re-surfacing in every triage because the supersession existed only in
conversation, never in a record. That is the defect this note closes.

## Superseded by the locked Appwrite ruling

`CLAUDE.md` → Canonical stack locks **Appwrite** as the backend, and the Non-goals
block explicitly rejects durable-workflow engines and CRDTs. The following changes
each propose a **Phoenix + Postgres + Gleam** backend spine, a protobuf machine wire
format, or "selective CRDT usage" — all in direct conflict.

| Change | Ticks at archive | Why |
|---|---|---|
| `add-beam-web-architecture-foundation` | 6/13 | Proposes Phoenix+Postgres+S3 as the system spine and selective CRDTs. Both rejected. |
| `add-phoenix-provenance-ingestion-and-recovery-analysis` | 0/12 | Phoenix-owned provenance ingestion. Appwrite Functions own this now. |
| `add-protobuf-event-envelope-and-upload-spool` | 4/12 | Protobuf transport to a Phoenix ingester. Appwrite is the transport. The *upload spool* concept survives — Non-goals already cite it as covering durability. |
| `add-provenance-ledger-and-beam-ingestion-contract` | 6/13 | Local ledger half **shipped** (`lib/core/utils/diagnostics.dart`, retention + redaction + real System Status feed, 2026-07-28). The BEAM ingestion-contract half is superseded. |

## Completed once the BEAM speculation was retired

| Change | Ticks | Why |
|---|---|---|
| `add-historical-photos-bootstrap` | 7/9 | Both remaining tasks were BEAM speculation — 3.2 "consider typed wire formats for machine sync", 3.3 "evaluate future Phoenix/Gleam sync ownership". Neither survives the Appwrite lock, so the change is done. |

## Never planned into executable work

| Change | Why |
|---|---|
| `harden-photo-permission-and-export-cleanup` | No `tasks.md` in 63 days. Carries pre-Appwrite assumptions. |
| `unified-continuity-and-combo-editing` | Only a `spec.md` — openspec never recognised it as a change at all. |

## Explicitly NOT archived

`add-self-healing-video-reliability-runtime` stays active. Despite sitting in the same
89-day cluster, it is **on-device product work** (video availability verification,
recovery prioritisation) with no BEAM dependency. Its motivation survives the ruling intact.

## The rule this establishes

An architecture ruling that supersedes queued work MUST retire that work in the same
commit that locks the ruling. A locked stack table and a queue that contradicts it is
drift, and drift costs a full triage session to rediscover. See `CLAUDE.md` →
"Supersession rule".
