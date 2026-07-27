import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/providers.dart' show movesDaoProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart' show currentAppwriteUserProvider;
import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/config/entitlement.dart';
import 'package:breakdex/core/config/remote_config_providers.dart' show appwriteClientProvider;

/// Client-side outcome of a redeem — the typed statuses the Function returns,
/// plus a transport [error]. The UI shows a message per case.
enum RedeemOutcome { granted, alreadyEntitled, invalidCode, expired, exhausted, error }

/// Result of [EntitlementService.redeem]: the [outcome] and, on a grant, the
/// [entitlement] it conferred.
class RedeemResponse {
  const RedeemResponse(this.outcome, [this.entitlement]);

  final RedeemOutcome outcome;
  final Entitlement? entitlement;

  bool get isGrant =>
      outcome == RedeemOutcome.granted || outcome == RedeemOutcome.alreadyEntitled;
}

/// Reads the caller's entitlement and redeems invite codes. The Appwrite impl is
/// exercised only when the gate is enabled AND a user is signed in — default
/// builds never touch it.
abstract class EntitlementService {
  /// The signed-in user's entitlement, or null if they hold none.
  Future<Entitlement?> readOwn();

  /// Redeem [code] for the signed-in user via the `invites-redeem` Function.
  Future<RedeemResponse> redeem(final String code);
}

/// [EntitlementService] over the Appwrite client SDK — `TablesDB` for the
/// per-user entitlement read (row security returns only the caller's row) and
/// `Functions` for the atomic redeem.
class AppwriteEntitlementService implements EntitlementService {
  AppwriteEntitlementService(final Client client)
      : _tables = TablesDB(client),
        _functions = Functions(client);

  final TablesDB _tables;
  final Functions _functions;

  @override
  Future<Entitlement?> readOwn() async {
    final rows = await _tables.listRows(
      databaseId: kAppwriteDatabaseId,
      tableId: kEntitlementsTableId,
      queries: [Query.limit(1)],
    );
    if (rows.rows.isEmpty) {
      return null;
    }
    return Entitlement.tryFrom(rows.rows.first.data);
  }

  @override
  Future<RedeemResponse> redeem(final String code) async {
    final execution = await _functions.createExecution(
      functionId: kInvitesRedeemFunctionId,
      body: jsonEncode(<String, Object?>{'code': code}),
      method: enums.ExecutionMethod.pOST,
    );
    final body = _decode(execution.responseBody);
    final status = body['status'];
    final outcome = switch (status) {
      'granted' => RedeemOutcome.granted,
      'alreadyEntitled' => RedeemOutcome.alreadyEntitled,
      'invalidCode' => RedeemOutcome.invalidCode,
      'expired' => RedeemOutcome.expired,
      'exhausted' => RedeemOutcome.exhausted,
      _ => RedeemOutcome.error,
    };
    return RedeemResponse(
      outcome,
      outcome == RedeemOutcome.granted || outcome == RedeemOutcome.alreadyEntitled
          ? Entitlement.tryFrom(body)
          : null,
    );
  }

  Map<String, Object?> _decode(final String raw) {
    if (raw.isEmpty) {
      return const <String, Object?>{};
    }
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.cast<String, Object?>() : const <String, Object?>{};
  }
}

final entitlementServiceProvider = Provider<EntitlementService>((final ref) {
  return AppwriteEntitlementService(ref.watch(appwriteClientProvider));
});

/// The signed-in user's entitlement. **Inert when the gate is off** — returns
/// null without any Appwrite call, so default builds are byte-identical. When
/// enabled and signed in, reads the entitlement row; any error reads as null
/// (no entitlement) so the gate fails open (never a hard error over the app).
final entitlementProvider = FutureProvider<Entitlement?>((final ref) async {
  if (!kEntitlementGateEnabled) {
    return null;
  }
  final user = ref.watch(currentAppwriteUserProvider).valueOrNull;
  if (user == null) {
    return null;
  }
  try {
    return await ref.watch(entitlementServiceProvider).readOwn();
  } on Object catch (_) {
    return null;
  }
});

/// Whether this device holds an existing local library — the "grandfathered
/// existing user" signal. Any non-empty moves library means a returning user who
/// must never be gated (brownfield rule). Errors/loading read as `true`
/// (fail-open: never gate on an unknown local state).
final hasLocalLibraryProvider = StreamProvider<bool>((final ref) {
  return ref
      .watch(movesDaoProvider)
      .watchAll()
      .map((final moves) => moves.isNotEmpty)
      .handleError((final Object _) => true);
});

/// The gate decision for the app root. Composed as a pure
/// [EntitlementGate.evaluate] of the flag, build mode, owner check, the
/// grandfathered signal, and the entitlement. Anything still loading resolves to
/// the fail-open value so the gate never flickers a block during startup.
final entitlementGateProvider = Provider<EntitlementGate>((final ref) {
  if (!kEntitlementGateEnabled) {
    return const EntitlementGranted();
  }
  final email = ref.watch(currentAppwriteUserProvider).valueOrNull?.email;
  final isOwner = kOwnerEmail.isNotEmpty && email == kOwnerEmail;
  final isGrandfathered = ref.watch(hasLocalLibraryProvider).valueOrNull ?? true;
  final entitlement = ref.watch(entitlementProvider).valueOrNull;
  return EntitlementGate.evaluate(
    gateEnabled: kEntitlementGateEnabled,
    isReleaseBuild: kReleaseMode,
    isOwner: isOwner,
    isGrandfathered: isGrandfathered,
    entitlement: entitlement,
  );
});

/// The signed-in user's cohort (from their entitlement), or null. Threaded into
/// `RemoteConfig.flag(cohort:)` so a redeemed cohort's remote-config profile
/// overrides win — this is the "my own versions" binding (task 2.4).
final userCohortProvider = Provider<String?>((final ref) {
  return ref.watch(entitlementProvider).valueOrNull?.cohort;
});
