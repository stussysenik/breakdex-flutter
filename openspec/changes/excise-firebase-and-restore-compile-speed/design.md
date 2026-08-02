# Design — Excise Firebase and Restore Compile Speed

## Measure before deleting, not after

The proposal asserts Firebase dominates the 990s. It does not prove it. Deleting first and
declaring victory would produce a number with nothing to compare it to, and would leave the
next session unable to tell a 400s build from a regression.

So the order is: **baseline → delete → re-measure → record**. The baseline is one cold
release device build with a wiped DerivedData, timed. It costs ~16 minutes of wall clock,
once. That is the cheapest honest evidence available, and without it every later claim about
compile speed in this repo is a vibe.

If the baseline shows Firebase is *not* the dominant term, this change still lands — a dead
backend's dependency tree is debt regardless — but the title and the budget doc change to
say what actually dominates.

## Delete, do not port

`sync_service.dart` is 1576 lines and reaches `FirebaseFirestore.instance` /
`FirebaseStorage.instance` directly (its own doc comment at line 520 admits the statics make
it untestable). The temptation is to abstract the transport and keep the orchestration.

Reject that. The Appwrite backends under `lib/core/sync/backends/` already carry the
orchestration for every entity — moves, combos, reviews, FSRS, decks, tombstones, notes —
landed and gated in the 2026-07-13 wave. A second orchestrator kept alive behind an
interface is the supersession rule's exact failure mode: the contradicted half surviving
because nobody wrote down that it was contradicted.

The task list therefore requires the deletion to state, per removed capability, which
Appwrite path replaces it. A capability with no named replacement is a finding, and it stops
the change until the owner rules on it.

## Why the gate is a deletion test, not a build timer

A build-time assertion in CI would be flaky (runner variance dwarfs the signal) and slow.
The durable gate is cheap and binary: **no source file under `lib/` imports
`package:firebase_*` or `package:cloud_firestore`, and `pubspec.yaml` declares none.** That
is the same shape as `icon_conformance_test.dart` and `color_conformance_test.dart` — a
grep-strength invariant that cannot rot.

The wall-clock number lives in `docs/ios-build-budget.md` as a recorded measurement with its
procedure and its date, held by the docs ledger, not by a timer. A human re-runs it when
they suspect drift. A number with a procedure beside it is reproducible; a number in CI is
noise with a red light attached.

## The Podfile workaround is a consequence, not a separate task

`SWIFT_ENABLE_EXPLICIT_MODULES = 'NO'` is applied to every pod target because
FirebaseFirestore's precompiled XCFramework cannot resolve its module deps under Xcode 16+
explicit-module builds. It is scoped to all targets because the Podfile loops over all of
them.

Once Firestore is gone the workaround has no beneficiary, and leaving it costs build
parallelism on every remaining pod. It is removed in the same phase as the pod removal and
proven by one clean build, not tracked separately — a config line whose stated reason no
longer exists is not a judgment call.

## What this change deliberately does not decide

Whether any other measure — DerivedData stability, `ONLY_ACTIVE_ARCH`, module caching — is
worth taking. Those are decided **after** the re-measurement, by an owner reading two
numbers, or not at all. Speculative build tuning ahead of evidence is the same defect as
speculative abstraction: work that looks like progress and cannot be falsified.
