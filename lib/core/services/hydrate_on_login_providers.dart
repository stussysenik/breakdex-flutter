/// Riverpod wiring for auto-hydration on Google sign-in.
///
/// [hydrateOnLoginTriggerProvider] fires a full inbound pull
/// ([SyncService.hydrateAllFromBackend]) the first time an Appwrite session
/// appears — watched at the shell root alongside `syncTriggerProvider` and the
/// legacy-identity claim. Its reason to exist is the fresh device: a
/// just-signed-in web client (or a reinstall) whose local Drift is empty must
/// see the user's library immediately, without first flipping cutover flags.
/// Runs exactly once per signed-in user (guarded by [_lastHydratedUserId]),
/// idempotent (LWW-safe re-merge), and never throws — an unreachable backend can
/// never block app entry.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart' show syncServiceProvider;
import '../utils/diagnostics.dart';
import 'appwrite_auth_providers.dart' show currentAppwriteUserProvider;

/// The last Appwrite userId auto-hydrated in this app session, so the (heavy)
/// full pull fires once per sign-in — not on every shell rebuild or stream
/// re-emission of the same user.
final _lastHydratedUserId = StateProvider<String?>((final ref) => null);

final hydrateOnLoginTriggerProvider = Provider<void>((final ref) {
  final user = ref.watch(currentAppwriteUserProvider).valueOrNull;
  if (user == null) return;
  if (ref.read(_lastHydratedUserId) == user.id) return;
  ref.read(_lastHydratedUserId.notifier).state = user.id;

  unawaited(_hydrate(ref, user.id));
});

Future<void> _hydrate(final Ref ref, final String userId) async {
  try {
    final reports = await ref.read(syncServiceProvider).hydrateAllFromBackend();
    final total = reports.fold<int>(0, (final s, final r) => s + r.applied);
    DiagnosticsLog.info(
      'Hydrate',
      'Auto-hydrate on login user=$userId: $total rows applied — '
          '${reports.map((final r) => '${r.label}:${r.applied}').join(' ')}',
    );
  } on Object catch (e) {
    // Never fatal — the user still has local-only mode; a later manual
    // "Pull from backend now" (dev panel) or the next login retries.
    DiagnosticsLog.error('Hydrate', 'Auto-hydrate failed for user=$userId: $e');
  }
}
