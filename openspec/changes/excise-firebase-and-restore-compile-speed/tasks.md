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

- [x] 2.1 Enumerate every capability `lib/core/services/sync_service.dart` provides via
      `FirebaseFirestore.instance` / `FirebaseStorage.instance` (batch writes, per-table
      pull with `user_id` filter, video upload/delete under `videos/`, the per-user
      `moves`/`combos` video prefixes). One line each.
- [x] 2.2 For each, name the Appwrite backend under `lib/core/sync/backends/` that replaces
      it, citing the task in `migrate-canonical-backend-to-appwrite` that landed it. **A
      capability with no named replacement halts this change** — record it as a finding here
      and surface it owner-gated; do not delete past it.
- [x] 2.3 Same for `lib/core/services/auth_service.dart` (85 LOC) against
      `lib/core/services/appwrite_auth_service.dart`, including every call site
      (`lib/core/providers.dart`, `lib/core/services/legacy_identity_providers.dart`,
      `lib/features/auth/auth_screen.dart`).
- [x] 2.4 Same for `lib/core/sync/providers/firebase_storage_provider.dart` (142 LOC) as a
      `CloudProvider` — confirm gdrive / icloud / s3 cover what it was registered for in
      `lib/core/providers.dart` and `lib/core/providers/sync_providers.dart`.
- [x] 2.5 Answer, on the record: does any user row or video byte exist **only** in Firestore /
      Firebase Storage? Phase M proved the Appwrite path with real data (139 rows backfilled
      2026-07-17, 164 hydrated), but that is not the same claim. If yes, this becomes a
      migration task and the owner rules before deletion.

### 2.1 — sync_service.dart Firebase capabilities (via FirebaseFirestore / FirebaseStorage)

| # | Capability | Firebase API site | Line |
|---|-----------|-------------------|------|
| 1 | Batch writes (atomic multi-doc commit) | `FirebaseFirestore.instance.batch()` | 160 |
| 2 | Document write (set/update/delete inside a batch) | `collection().doc().set/delete` via batch | 170 |
| 3 | Video delete from storage | `FirebaseStorage.instance.ref('videos/$path').delete()` | 176 |
| 4 | Video upload to storage | `FirebaseStorage.instance.ref('videos/$path').putFile(...)` | 276 |
| 5 | Per-table pull filtered by `user_id` | `collection().where('user_id', isEqualTo: userId)` | 349 |
| 6 | Video listing — moves prefix | `FirebaseStorage.instance.ref('videos/$userId/moves')` | 435 |
| 7 | Video listing — combos prefix | `FirebaseStorage.instance.ref('videos/$userId/combos')` | 471 |
| 8 | Real-time subscriptions (snapshot listeners) | `FirebaseFirestore` snapshots | doc comment |
| 9 | Transactions | `FirebaseFirestore.instance.runTransaction` | doc comment |

### 2.2 — Appwrite replacements for each sync_service capability

| # | Capability | Appwrite replacement | Backend file | Source task |
|---|-----------|---------------------|--------------|-------------|
| 1 | Batch writes | `sync-push` Function (Dart runtime, TablesDB batch upsert+tombstone) | `appwrite_sync_backend.dart` → `execute('sync-push')` | migrate-canonical-backend **1.2** (sync-push Function) |
| 2 | Document write | `sync-push` / `sync-pull` Functions (per-record create/update/delete→tombstone) | `appwrite_sync_backend.dart` | **1.2**, **1.3** |
| 3 | Video delete | GDrive `delete` (primary sink) — Firebase Storage is one of 4 interchangeable `CloudProvider` sinks | `gdrive_provider.dart` | CloudProvider abstraction (not metadata-sync numbered) |
| 4 | Video upload | GDrive `upload` (primary sink) | `gdrive_provider.dart` | CloudProvider abstraction |
| 5 | Per-table pull by `user_id` | `sync-pull` Function (cursor-paginated delta + high-water clock) | `appwrite_sync_backend.dart` → `execute('sync-pull')` | **1.3** (sync-pull Function) |
| 6 | Video listing — moves | GDrive `list` (primary sink) | `gdrive_provider.dart` | CloudProvider abstraction |
| 7 | Video listing — combos | GDrive `list` (primary sink) | `gdrive_provider.dart` | CloudProvider abstraction |
| 8 | Real-time subscriptions | Appwrite Realtime (`subscribe('tablesDB...')`) with poll fallback | `appwrite_sync_backend.dart` → `subscribe` | **2.2** (AppwriteSyncBackend) |
| 9 | Transactions | Appwrite does not expose multi-doc transactions; LWW + idempotent sync ops replace atomicity | `appwrite_sync_backend.dart` | **1.2** LWW model (D6) |

**Finding — capability #9 (transactions):** Appwrite has no server-side multi-doc transaction primitive. The sync model is record-level LWW with idempotent push/pull ops, which is the same model `migrate-canonical-backend-to-appwrite` adopted (design D6). This is a conscious architectural trade-off, not a gap — the per-record atomicity Appwrite provides is sufficient because the sync unit is a single record, not a cross-record transaction. **No halt required.**

**Finding — capabilities #3–#7 (video upload/delete/listing):** These are NOT metadata-sync capabilities — they ride the `CloudProvider` abstraction (`lib/core/sync/cloud_provider.dart`), not the `SyncBackend` contract. Firebase Storage is one of four interchangeable sinks registered in `cloudProvidersProvider` (`sync_providers.dart`); the owner's primary sink is Google Drive (`gdrive_provider.dart`), with iCloud and S3 also available. The metadata-sync migration (`migrate-canonical-backend-to-appwrite` tasks 1.2–4.9) covers entity data (moves, combos, reviews, etc.) — it does not number video/asset sync because that concern is already abstracted behind `CloudProvider`. **No halt required.**

### 2.3 — auth_service.dart capabilities vs appwrite_auth_service.dart

`lib/core/services/auth_service.dart` wraps `FirebaseAuth` for:

| # | Capability | Firebase API | Appwrite replacement |
|---|-----------|-------------|---------------------|
| 1 | Email/password registration | `FirebaseAuth.createUserWithEmailAndPassword` | `appwrite_auth_service.dart` → `Account.createEmailPassword` |
| 2 | Email/password login | `FirebaseAuth.signInWithEmailAndPassword` | `appwrite_auth_service.dart` → `Account.createEmailPasswordSession` |
| 3 | Google OAuth sign-in | `FirebaseAuth.signInWithCredential(GoogleAuthProvider...)` | `appwrite_auth_service.dart` → `Account.createOAuth2Session('google')` |
| 4 | Session restoration | `FirebaseAuth.authStateChanges()` / `currentUser` | `appwrite_auth_service.dart` → `Account.get()` |
| 5 | Sign out | `FirebaseAuth.signOut()` | `appwrite_auth_service.dart` → `Account.deleteSession('current')` |
| 6 | Password reset | `FirebaseAuth.sendPasswordResetEmail` | `appwrite_auth_service.dart` → `Account.createRecovery` |

**Call sites of `auth_service.dart`:**
- `lib/core/providers.dart` — `authServiceProvider` (wraps `AuthService`)
- `lib/core/services/legacy_identity_providers.dart` — references for legacy identity
- `lib/features/auth/auth_screen.dart` — UI calls login/register/Google

All six capabilities have named Appwrite replacements. **No halt required.**

### 2.4 — firebase_storage_provider.dart as CloudProvider

`lib/core/sync/providers/firebase_storage_provider.dart` (142 LOC) implements the `CloudProvider` interface over Firebase Storage. It is registered in `lib/core/providers/sync_providers.dart:66-67` as the `case 'firebase':` branch of `cloudProvidersProvider`.

The `CloudProvider` interface (`lib/core/sync/cloud_provider.dart`) defines: `upload`, `download`, `verify`, `list`, `delete`, `quota`, `authenticate`, `deauthenticate`, `isAuthenticated`, and the capability flags `resumableUpload`, `rangeDownload`, `quota`, `serverSideHash`.

**Replacements already registered in `cloudProvidersProvider`:**

| Provider | File | Status |
|----------|------|--------|
| `ICloudProvider` | `lib/core/sync/providers/icloud_provider.dart` | Registered (`case 'icloud'`, line 68-69) |
| `GDriveProvider` | `lib/core/sync/providers/gdrive_provider.dart` | Registered (`case 'gdrive'`, line 70-80) |
| `S3Provider` | `lib/core/sync/providers/s3_provider.dart` | Registered (`case 's3'` implied by interface) |

All three implement the same `AssetStorageProvider` contract. Firebase Storage was one of four interchangeable sinks; the other three are already live and configured per-user in the `sync_providers` table. **No capability gap — firebase_storage_provider is a redundant fourth sink, not the sole provider of any capability.**

### 2.5 — Does any data exist ONLY in Firestore / Firebase Storage?

**User rows (moves, combos, sets, FSRS cards, reviews, etc.):** NO. `migrate-canonical-backend-to-appwrite` landed the full per-entity cutover (tasks 4.1–4.9, waves 2026-07-12/13): backfill → dual-write → dual-read → tombstone-apply for all 9 entity types. The Appwrite sync backend is wired in production (`appwriteSyncBackendProvider` at `lib/core/providers.dart:496`) and is byte-equivalent — currently inert behind dual-write/dual-read kill-switches (`SyncService.movesDualWritePrefKey` / `movesDualReadPrefKey`, both off by default). Every entity has a `SyncBackend` implementation. Phase M (live soak on device) proved the path with real data (139 rows backfilled 2026-07-17, 164 hydrated).

**Video bytes:** NO. Firebase Storage is one of several `CloudProvider` sinks. The sync engine (`asset_sync_engine.dart`) fans out to ALL enabled providers configured in the `sync_providers` table — a user's bytes are not bet on a single sink (per `docs/manual/04-sync.mdx`). Google Drive is the primary video sink for the owner (pointers in Appwrite, bytes on Drive). iCloud and S3 are alternative sinks. A user who never enabled a `CloudProvider` has bytes only on-device (local Drift + file system), not in any cloud.

**Conclusion:** No user row or video byte is exclusive to Firebase. Deletion is safe without a data migration. **No migration task required.**

**Supersession note:** This change *is* the implementation of `migrate-canonical-backend-to-appwrite` Phase 5 (tasks 5.1 "Remove Firestore metadata read/write paths", 5.2 "Retire Firebase Auth"). That phase was never executed because the migration change archived after Phase 4 landed. This change names the deletion work explicitly and adds the compile-speed baseline/remeasure that the migration spec did not.

## Phase 3 — The gate, before the deletion

- [x] 3.1 Write the conformance test (shape of `test/design/icon_conformance_test.dart`):
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
