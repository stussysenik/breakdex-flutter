/// Riverpod wiring for the D3 legacy-identity claim (task 3.4).
///
/// [legacyIdentityClaimTriggerProvider] fires the claim once an Appwrite session
/// exists — watched at the shell root alongside `syncTriggerProvider`. It is a
/// no-op on fresh installs (no Firebase uid), idempotent on re-login, and never
/// throws, so an unprovisioned write path can't break app entry. The live
/// cross-install proof (same Google account on two installs → one dataset) is
/// Phase M (M.2/M.4).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/config/remote_config_providers.dart' show appwriteClientProvider;
import 'package:breakdex/core/providers.dart' show authServiceProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart' show currentAppwriteUserProvider;
import 'package:breakdex/core/services/legacy_identity_gateway.dart';
import 'package:breakdex/core/services/legacy_identity_service.dart';

final legacyIdentityClaimServiceProvider =
    Provider<LegacyIdentityClaimService>((final ref) {
  return LegacyIdentityClaimService(
    AppwriteLegacyIdentityGateway(client: ref.watch(appwriteClientProvider)),
  );
});

/// Side-effecting trigger (mirrors `syncTriggerProvider`): on each Appwrite
/// login, link this device's legacy Firebase uid to the Appwrite id.
final legacyIdentityClaimTriggerProvider = Provider<void>((final ref) {
  final user = ref.watch(currentAppwriteUserProvider).valueOrNull;
  if (user == null) return;

  String firebaseUid;
  try {
    firebaseUid = ref.read(authServiceProvider).userId;
  } on Object catch (_) {
    firebaseUid = '';
  }

  unawaited(
    ref
        .read(legacyIdentityClaimServiceProvider)
        .claimOnLogin(appwriteUser: user, firebaseUid: firebaseUid),
  );
});
