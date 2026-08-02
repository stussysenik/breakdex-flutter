# Tasks — Excise Firebase and Restore Compile Speed

Phase dependencies: Phase 1 first and alone — the baseline is worthless once anything is
deleted. Phase 2 consumes Phase 1. Phase 3 consumes Phase 2. Phase 4 consumes Phase 3.
Phase 5 is the record and closes the change.

**Lane note (2026-08-02):** every phase below except Phase 1 is Student work, and Student is
owner-invoked (`CLAUDE.md` → Session types). A Teacher session may sharpen this list; it may
not start ticking it.

## Phase 1 — Baseline, before anything is deleted

- [ ] 1.1 Wipe `~/Library/Developer/Xcode/DerivedData` and `build/ios/`, then time one
      `flutter run --release -d senik` end to end. Record the Xcode-build seconds, the total,
      the Xcode version, and the machine. Five stale `Runner-*` DerivedData directories were
      present on 2026-08-02 — note whether wiping changes the number, since that tells us
      whether the 990.3s reading was already cold.
- [ ] 1.2 Time `flutter run --debug -d senik` from the same cold state, for the ratio that
      justifies "debug is the device dev loop".
- [ ] 1.3 Create `docs/ios-build-budget.md` with both numbers, the date, the machine, and the
      exact procedure. Register it in the docs ledger so freshness is checked.
- [ ] 1.4 Record the pod-tree count as measured: 55 root pods in `ios/Podfile.lock`, 26 of
      them Firebase/Firestore. State the counting command so the number is reproducible.

## Phase 2 — Prove the replacement exists, per capability

- [ ] 2.1 Enumerate every capability `lib/core/services/sync_service.dart` provides via
      `FirebaseFirestore.instance` / `FirebaseStorage.instance` (batch writes, per-table
      pull with `user_id` filter, video upload/delete under `videos/`, the per-user
      `moves`/`combos` video prefixes). One line each.
- [ ] 2.2 For each, name the Appwrite backend under `lib/core/sync/backends/` that replaces
      it, citing the task in `migrate-canonical-backend-to-appwrite` that landed it. **A
      capability with no named replacement halts this change** — record it as a finding here
      and surface it owner-gated; do not delete past it.
- [ ] 2.3 Same for `lib/core/services/auth_service.dart` (85 LOC) against
      `lib/core/services/appwrite_auth_service.dart`, including every call site
      (`lib/core/providers.dart`, `lib/core/services/legacy_identity_providers.dart`,
      `lib/features/auth/auth_screen.dart`).
- [ ] 2.4 Same for `lib/core/sync/providers/firebase_storage_provider.dart` (142 LOC) as a
      `CloudProvider` — confirm gdrive / icloud / s3 cover what it was registered for in
      `lib/core/providers.dart` and `lib/core/providers/sync_providers.dart`.
- [ ] 2.5 Answer, on the record: does any user row or video byte exist **only** in Firestore /
      Firebase Storage? Phase M proved the Appwrite path with real data (139 rows backfilled
      2026-07-17, 164 hydrated), but that is not the same claim. If yes, this becomes a
      migration task and the owner rules before deletion.

## Phase 3 — The gate, before the deletion

- [ ] 3.1 Write the conformance test (shape of `test/design/icon_conformance_test.dart`):
      no file under `lib/` imports `package:firebase_core`, `package:firebase_auth`,
      `package:firebase_storage`, or `package:cloud_firestore`; `pubspec.yaml` declares none.
      Prove it **red first** against today's 8 importing files, with the failure message
      naming the pod tree the dependency drags in.

## Phase 4 — Delete

- [ ] 4.1 Remove the Firebase boot path from `lib/main.dart`
      (`_initializeFirebaseIfConfigured`, the `BootGate.firebase` gate, the imports). Decide
      and state whether `BootGate.firebase` is removed from the enum or retired as a
      no-op — a boot gate nothing completes is worse than none.
- [ ] 4.2 Delete `lib/firebase_options.dart`, `lib/core/services/auth_service.dart`,
      `lib/core/sync/providers/firebase_storage_provider.dart`, and their registry entries.
- [ ] 4.3 Delete or de-Firestore `lib/core/services/sync_service.dart` (1576 LOC) per the
      Phase 2 mapping. Prefer deletion; a surviving remnant must name what still needs it.
- [ ] 4.4 Resolve `lib/core/platform/native_file_transfer{,_native,_web}.dart` — they import
      firebase for the upload seam; keep the seam, drop the dependency, or delete the seam
      if the Appwrite/Drive path owns transfers now.
- [ ] 4.5 Remove the four firebase deps from `pubspec.yaml`; `flutter pub get`;
      `cd ios && pod install`. Confirm `ios/Podfile.lock` root-pod count fell from 55 to ~29
      and that `abseil`, `gRPC-C++`, `gRPC-Core`, `BoringSSL-GRPC`, `leveldb-library`, and
      `nanopb` are gone.
- [ ] 4.6 Delete the `SWIFT_ENABLE_EXPLICIT_MODULES = 'NO'` line and its comment from
      `ios/Podfile` post_install — its stated beneficiary (FirebaseFirestore's XCFramework
      module resolution) no longer exists. Prove with one clean build, not by reasoning.
- [ ] 4.7 `./verify.sh` full, exit 0. Expect test deletions where suites covered the removed
      code — name each deleted test and what covered it instead, per the ledger rule.
- [ ] 4.8 Green the Phase 3 gate.

## Phase 5 — Re-measure and record

- [ ] 5.1 Re-run 1.1's procedure exactly, from the same wiped state. Record the new number
      beside the old one in `docs/ios-build-budget.md` with the delta.
- [ ] 5.2 State plainly what the delta did **not** prove — if Firebase removal accounts for
      less than the bulk of the 990s, name what actually dominates (Dart AOT snapshot, dSYM
      generation, remaining pods) and stop there. Do not open a build-tuning change on the
      strength of a hunch; that is a separate proposal with its own baseline.
- [ ] 5.3 Archive note per the supersession rule: this change retires the Firebase half that
      the 2026-07-05 Appwrite lock killed and never wrote down. State that explicitly — the
      nine-month gap is the lesson, not a footnote.
- [ ] 5.4 `flutter build web --release` green, and one owner device run to confirm boot,
      sign-in, and sync on the Appwrite path. **Owner-gated** — route to
      `owner-verification-passes`, do not self-grade.
