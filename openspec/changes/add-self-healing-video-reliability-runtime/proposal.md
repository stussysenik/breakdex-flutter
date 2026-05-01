# Add Self-Healing Video Reliability Runtime

## Summary

Define the next runtime layer that continuously verifies video availability, prioritizes recovery actions, and turns provenance signals into deterministic self-healing behavior. This captures the product goal that future video loading should feel reliable and explainable, not best-effort and opaque.

## Motivation

Breakdex now has:

- historical Photos recovery
- DB backup/restore
- cloud video retrieval
- provenance journaling

But these flows are still activated mostly by isolated triggers. The system does not yet have a unified reliability runtime that can decide:

- what should be verified first
- what should be retried automatically
- what should be surfaced as a real developer/user problem
- what should be deferred to backend policy later

We need a runtime contract that makes video reliability an intentional subsystem.

## Scope

### In scope

- local verification and retry policy for video availability
- priority model for startup and foreground sweeps
- relationship between provenance events and self-healing actions
- user/developer-visible state transitions for reliability flows

### Out of scope

- guaranteed OS background execution on every platform
- full Phoenix implementation of reliability policy
- replacing the existing local-first retrieval/recovery flows immediately

## Capabilities

1. `reliability-sweep-policy` — deterministic verification order for assets and moves
2. `self-healing-action-loop` — automatic retries and recovery attempts with bounded budgets
3. `explainable-video-state` — clear distinction between missing, recoverable, blocked, and failed states

## Dependencies

- current video retrieval controller
- current managed Photos recovery flow
- current provenance journal and diagnostics
