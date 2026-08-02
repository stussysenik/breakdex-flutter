# Excise Firebase and Restore Compile Speed

## Why

Measured 2026-08-02 on this checkout: `flutter run --release -d senik` spent **990.3s in
Xcode build** before the app launched — 24× the web loop (`flutter build web --release`:
41s, measured 2026-07-30). Compile speed is loss-function term 3, paid once per iteration
for the life of the project, and at 990s the device loop is not a loop.

The cost is not Flutter and not the app's own Dart. It is CocoaPods. Counted from
`ios/Podfile.lock`: **26 of 55 root pods are the Firebase/Firestore tree** —

```
FirebaseFirestore → FirebaseFirestoreInternal → abseil (≈1500 subspecs)
                                              → gRPC-C++ / gRPC-Core
                                              → BoringSSL-GRPC
                                              → leveldb-library
                                              → nanopb
plus FirebaseCore / CoreInternal / CoreExtension / SharedSwift,
     FirebaseAuth / AuthInterop, FirebaseStorage, FirebaseAppCheckInterop,
     AppCheckCore, GoogleUtilities, GTMSessionFetcher, PromisesObjC
```

That is a C++ source tree, not a precompiled XCFramework: it recompiles from source per
architecture on any cold DerivedData, and `~/Library/Developer/Xcode/DerivedData` currently
holds **five distinct `Runner-*` directories**, so cold is the normal case here.

It is being paid for a backend the codebase already declares dead. `lib/main.dart:78`:

> `/// Firebase is legacy here — Appwrite is the canonical backend`

`CLAUDE.md` → Canonical stack locked Appwrite on 2026-07-05 and the supersession rule says a
ruling must retire the work it kills **in the same commit**. It did not. Nine months of
device builds have carried gRPC and abseil to run an `initializeApp` inside a try/catch that
is allowed to fail.

Firestore also forces a second cost: `ios/Podfile` sets
`SWIFT_ENABLE_EXPLICIT_MODULES = 'NO'` on **every pod target**, with a comment naming
Firestore's precompiled-XCFramework module resolution as the reason. That opt-out disables
Xcode 16+/26 explicit module builds project-wide — a build-parallelism feature — for one
pod's benefit. Removing Firebase removes the workaround.

## What Changes

- **Firebase deleted from `pubspec.yaml`**: `firebase_core`, `cloud_firestore`,
  `firebase_storage`, `firebase_auth`. Four direct deps; ~26 pods.
- **The legacy Firestore sync path retired**, not ported. `lib/core/services/sync_service.dart`
  (1576 LOC) writes to `FirebaseFirestore.instance` and `FirebaseStorage.instance`; the
  Appwrite backends under `lib/core/sync/backends/` are the shipped replacement (master spec
  `migrate-canonical-backend-to-appwrite`, Phases 4.1–4.9 landed 2026-07-13). This change
  deletes the superseded half and states in the archive note what it did.
- **`firebase_storage_provider.dart` removed from the CloudProvider registry** — one of four
  providers beside gdrive / icloud / s3; removal is a registry entry plus a file.
- **Legacy `AuthService` retired** in favour of `appwrite_auth_service.dart`, which already
  exists beside it and is what `auth_screen.dart` should reach.
- **`SWIFT_ENABLE_EXPLICIT_MODULES` opt-out deleted** from `ios/Podfile` post_install once
  Firestore is gone, restoring Xcode's default explicit-module build.
- **Compile budget becomes a recorded number, not a feeling**: a short
  `docs/ios-build-budget.md` records the before/after wall-clock for a cold release device
  build, so the next regression is visible instead of absorbed.
- **`--release` on device stated as a distribution act** in `CLAUDE.md` → Loss function
  (landed alongside this proposal, 2026-08-02) — the dev loop is web, then debug-on-device.

## Capabilities

### New

- `ios-compile-budget`: cold iOS release build wall-clock recorded as a number with a
  measurement procedure; a grep-strength gate holding Firebase out of `lib/` and
  `pubspec.yaml`; and the rule that a retired transport must name its replacement.

`sync` and `auth` have no capability spec under `openspec/specs/` today, so this change
does not claim to modify one. The behavioural effect is subtractive and is stated in the
footprint table: the Firestore/Firebase-Storage transport goes, Appwrite plus the
gdrive/icloud/s3 CloudProviders are the whole remaining set, and Appwrite is the only
identity path on every surface.

## Footprint estimate

| Surface | Current | Target |
|---|---|---|
| `pubspec.yaml` firebase deps | 4 | 0 |
| `ios/Podfile.lock` root pods | 55 | ~29 |
| Dart files importing `package:firebase*` | 8 | 0 |
| `lib/core/services/sync_service.dart` | 1576 LOC | deleted or Firestore-free |
| `lib/core/services/auth_service.dart` | 85 LOC | deleted |
| `lib/core/sync/providers/firebase_storage_provider.dart` | 142 LOC | deleted |
| `lib/firebase_options.dart` | present | deleted |
| `ios/Podfile` post_install | explicit-modules opt-out | opt-out removed |
| Cold `flutter run --release -d senik` | 990.3s (measured 2026-08-02) | measured, recorded |

Net expected diff: **strongly negative LOC**. This change removes a subsystem; it adds one
markdown file and one deletion-conformance test.

## Non-goals

- **No change to what syncs or how LWW resolves.** Record-level LWW + tombstones +
  dirty-guard stay exactly as locked. This removes a dead transport, not a sync model.
- **No migration of Firestore data.** Phase M proved the Appwrite path with real rows
  (139 backfilled 2026-07-17, 164 hydrated); Firestore holds no authority. If any user row
  exists only in Firestore, that is a finding to record before deletion, not a reason to
  keep gRPC compiled forever.
- **No pod-tree audit beyond Firebase.** `DKImagePickerController`, `SDWebImage`, and
  friends are not in scope; they are Objective-C and cheap by comparison.
- **No build-system tuning as a substitute.** ccache, DerivedData pinning, and
  `ONLY_ACTIVE_ARCH` games treat the symptom. Delete the tree first, then measure, and only
  then decide whether anything else is worth doing.
- **No claim that this is the whole 990s.** The measurement task exists precisely because
  the split between pods, Dart AOT, and dSYM generation is not yet known.
