/// Entitlement model + the pure gate decision for Breakdex's private release.
///
/// An [Entitlement] is what a redeemed invite (or, later, a purchase) grants a
/// user: a `tier` and a `cohort` (the cohort binds a remote-config profile —
/// see `RemoteConfig.flag(cohort:)`). The gate that decides whether a released
/// build must show the invite-code entry is [EntitlementGate], evaluated as a
/// **pure function** of a handful of booleans so it is exhaustively `switch`ed by
/// the widget and unit-tested with no backend — mirroring `UpdateGate`.
library;

/// A per-user entitlement (one row in the `entitlements` table). Mirrors the
/// `invites-redeem` Function's grant shape.
class Entitlement {
  const Entitlement({
    required this.tier,
    required this.cohort,
    required this.source,
    this.code,
  });

  /// Parse the `entitlements` row data (or a redeem-Function response) into an
  /// [Entitlement], or return null if the required fields are absent/malformed —
  /// an absent entitlement must read as "not entitled", never throw into the gate.
  ///
  /// A `status: revoked` row (a refunded/charged-back purchase) also reads as
  /// null: the user is locked out until they re-purchase, but their row and all
  /// their data persist untouched ("lockout not loss").
  static Entitlement? tryFrom(final Map<String, Object?> data) {
    if (data['status'] == 'revoked') {
      return null;
    }
    final tier = data['tier'];
    final cohort = data['cohort'];
    if (tier is! String || tier.isEmpty || cohort is! String || cohort.isEmpty) {
      return null;
    }
    final source = data['source'];
    final code = data['code'];
    return Entitlement(
      tier: tier,
      cohort: cohort,
      source: source is String && source.isNotEmpty ? source : 'invite',
      code: code is String && code.isNotEmpty ? code : null,
    );
  }

  final String tier;
  final String cohort;
  final String source; // 'invite' | 'purchase'
  final String? code;
}

/// The gate decision for a released build. A sealed pair so the prompt widget
/// `switch`es exhaustively; [EntitlementGranted] passes the app through
/// untouched (the inert default), [EntitlementRequired] shows the invite entry.
sealed class EntitlementGate {
  const EntitlementGate();

  /// Decide whether to gate. The app is **let through** whenever ANY exemption
  /// holds, so the gate can only ever block a released, gate-enabled build for a
  /// signed-in-or-anonymous non-owner who is not a grandfathered existing user
  /// and holds no entitlement. Fail-open by construction: every "unknown" caller
  /// should pass one of the exemptions in, defaulting to granted.
  factory EntitlementGate.evaluate({
    required final bool gateEnabled,
    required final bool isReleaseBuild,
    required final bool isOwner,
    required final bool isGrandfathered,
    required final Entitlement? entitlement,
  }) {
    if (!gateEnabled ||
        !isReleaseBuild ||
        isOwner ||
        isGrandfathered ||
        entitlement != null) {
      return const EntitlementGranted();
    }
    return const EntitlementRequired();
  }
}

/// The app passes through untouched (default, and every exempt case).
final class EntitlementGranted extends EntitlementGate {
  const EntitlementGranted();
}

/// A released, gate-enabled build with no entitlement and no exemption — the
/// invite-code entry is shown over the app.
final class EntitlementRequired extends EntitlementGate {
  const EntitlementRequired();
}
