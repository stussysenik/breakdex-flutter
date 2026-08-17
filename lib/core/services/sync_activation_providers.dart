/// Riverpod wiring for first-login production provisioning (sync activation).
///
/// [firstLoginProvisioningTrigger] runs a one-shot provisioning pass the first
/// time an Appwrite session appears for a given `userId` — watched at the shell
/// root alongside [hydrateOnLoginTriggerProvider] and
/// `legacyIdentityClaimTriggerProvider`. It mirrors that trigger's shape
/// (watch `currentAppwriteUserProvider`, defer via microtask, swallow all
/// throws so it never blocks app entry) but differs in *why* and *what*:
///
/// - **Why:** hydrate seeds an *empty* local Drift from the backend (inbound);
///   provisioning shadows a *populated* local library TO the backend (outbound)
///   and flips every dual-write/dual-read kill-switch ON, so the two surfaces
///   agree from here on. Both fire on first login; they are independent and
///   idempotent.
/// - **Guard:** a *persisted* per-user one-shot flag
///   (`sync.provisioned.$userId` in SharedPreferences), not an in-memory
///   `_lastHydratedUserId`. The flag must survive app restarts — an in-memory
///   guard would re-provision every launch. Distinct userIds get independent
///   flags, so a second user on the same device provisions under its own key.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/providers.dart' show syncServiceProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart' show currentAppwriteUserProvider;
import 'package:breakdex/core/utils/diagnostics.dart';

/// Per-user one-shot flag key. Persisted in SharedPreferences under
/// `sync.provisioned.$userId` so it survives app restarts and is scoped per
/// user, not per app session. Absent key reads as `false`.
String provisionedFlagKey(final String userId) => 'sync.provisioned.$userId';

/// The last Appwrite userId provisioned *this session* — an in-memory fast
/// guard so the (heavy) provisioning fires once per sign-in even before the
/// persisted flag is read, and never on every shell rebuild or stream
/// re-emission of the same user.
final _lastProvisionedUserId = StateProvider<String?>((final ref) => null);

final firstLoginProvisioningTrigger = Provider<void>((final ref) {
  final user = ref.watch(currentAppwriteUserProvider).valueOrNull;
  if (user == null) return;
  if (ref.read(_lastProvisionedUserId) == user.id) return;

  final syncService = ref.read(syncServiceProvider);
  final prefs = syncService.prefs;
  if (prefs.getBool(provisionedFlagKey(user.id)) ?? false) {
    // Already provisioned in a prior session — remember in-memory so we never
    // re-read the flag for the rest of this session.
    ref.read(_lastProvisionedUserId.notifier).state = user.id;
    return;
  }

  // Deferred past the build: Riverpod forbids writing another provider while
  // this one is initializing. The persisted flag is re-checked inside because
  // two builds can race ahead of the first microtask.
  unawaited(
    Future<void>.microtask(() {
      if (ref.read(_lastProvisionedUserId) == user.id) return;
      ref.read(_lastProvisionedUserId.notifier).state = user.id;
      unawaited(_provision(ref, user.id));
    }),
  );
});

Future<void> _provision(final Ref ref, final String userId) async {
  final syncService = ref.read(syncServiceProvider);
  try {
    await syncService.activateSync();
    await syncService.prefs.setBool(provisionedFlagKey(userId), true);
    DiagnosticsLog.info(
      'Provision',
      'First-login provisioning complete for user=$userId',
    );
  } on Object catch (e) {
    // Never fatal — leave the one-shot flag unset so the next launch retries;
    // the user still has local-only mode until it succeeds.
    DiagnosticsLog.error(
      'Provision',
      'First-login provisioning failed for user=$userId: $e',
    );
  }
}
