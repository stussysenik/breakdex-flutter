/// Pure, provider-neutral core for the `invites-redeem` Appwrite Function.
/// Imports nothing from `dart_appwrite`, so the redeem semantics — idempotent
/// per `(userId, code)`, typed rejection for invalid/expired/exhausted codes —
/// are unit-testable against an in-memory [RedeemStore] with no live backend,
/// mirroring `reviews-append`/`sync-push`/`sync-pull`.
///
/// **Idempotency & the "one use" guarantee.** A redeem first looks up an
/// existing entitlement for `(userId, code)`. If present it returns
/// [RedeemStatus.alreadyEntitled] WITHOUT touching the invite's `uses` counter —
/// so a double-submit by the same user consumes exactly one use. This is the
/// atomicity the spec asks for; it does not need a multi-row transaction because
/// the guard is keyed on the same `(userId, code)` a replay carries. (A genuine
/// cross-user race on the very last use can overshoot `maxUses` by the number of
/// concurrent redeemers — `maxUses` is a soft cohort cap, not a hard ledger, so
/// this is accepted rather than engineered away with locks the backend lacks.)
///
/// `userId` is always the trusted `x-appwrite-user-id` the Function stamps, not a
/// client-supplied field — every store read/write is scoped to it.
library;

/// A redeem request. Wire shape: `{ "code": "CREW-XXXX" }`.
class RedeemRequest {
  const RedeemRequest({required this.code});

  /// Parse and structurally validate the body. Throws [RedeemRejection]
  /// (→ HTTP 400) on a malformed envelope — a bad payload is the caller's error,
  /// distinct from a well-formed request for a code that is invalid/expired/
  /// exhausted (those are typed [RedeemStatus] outcomes, not exceptions).
  factory RedeemRequest.fromJson(final Map<String, dynamic> body) {
    final raw = body['code'];
    if (raw is! String || raw.trim().isEmpty) {
      throw const RedeemRejection('missing or invalid "code" string.');
    }
    return RedeemRequest(code: raw.trim());
  }

  final String code;
}

/// An invite row (owner-minted). `rowId` is the backend document id, opaque to
/// the core, needed only so the store can update the `uses` counter.
class Invite {
  const Invite({
    required this.rowId,
    required this.code,
    required this.cohort,
    required this.entitlementTier,
    required this.maxUses,
    required this.uses,
    this.expiresAt,
  });

  final String rowId;
  final String code;
  final String cohort;
  final String entitlementTier;
  final int maxUses;
  final int uses;
  final int? expiresAt; // ms epoch; null = never expires
}

/// An entitlement row — what a redeem grants (and what the client gate reads).
class Entitlement {
  const Entitlement({
    required this.userId,
    required this.tier,
    required this.cohort,
    required this.source,
    required this.grantedAt,
    this.code,
  });

  final String userId;
  final String tier;
  final String cohort;
  final String source; // 'invite' | 'purchase'
  final int grantedAt; // ms epoch
  final String? code; // the redeemed invite code (idempotency key)

  Map<String, dynamic> toData() => <String, dynamic>{
        'userId': userId,
        'tier': tier,
        'cohort': cohort,
        'source': source,
        'grantedAt': grantedAt,
        if (code != null) 'code': code,
      };
}

/// Typed outcome of a well-formed redeem. Each maps to an HTTP status in
/// `main.dart` (granted/alreadyEntitled → 200; the rejections → 409).
enum RedeemStatus { granted, alreadyEntitled, invalidCode, expired, exhausted }

/// Result of [redeemInvite]: a [status] plus the [entitlement] for the two
/// success statuses (granted, alreadyEntitled); `null` for rejections.
class RedeemResult {
  const RedeemResult(this.status, [this.entitlement]);

  final RedeemStatus status;
  final Entitlement? entitlement;

  bool get isGrant =>
      status == RedeemStatus.granted || status == RedeemStatus.alreadyEntitled;
}

/// Raised on a malformed request body. The Function maps it to HTTP 400. An
/// [Exception] (expected control flow), not an `Error`.
class RedeemRejection implements Exception {
  const RedeemRejection(this.message);

  final String message;

  @override
  String toString() => 'RedeemRejection: $message';
}

/// Storage seam the pure core drives. Implemented over Appwrite TablesDB in
/// `main.dart`, and in-memory in tests. All entitlement keys are scoped to the
/// trusted `userId`.
abstract class RedeemStore {
  /// An existing entitlement for this `(userId, code)`, or null — the
  /// idempotency guard (a replay returns the same grant without re-counting).
  Future<Entitlement?> findEntitlement(final String userId, final String code);

  /// The invite row for `code`, or null if no such code exists.
  Future<Invite?> findInvite(final String code);

  /// Create the entitlement row under owner-only permissions.
  Future<void> writeEntitlement(final Entitlement entitlement);

  /// Set the invite's `uses` counter to [newUses] (the increment).
  Future<void> setInviteUses(final String inviteRowId, final int newUses);
}

/// Redeem [request]'s code for [userId] at [now] (ms epoch). Idempotent per
/// `(userId, code)`; rejects invalid/expired/exhausted codes with a typed
/// [RedeemStatus]. See the library doc for the one-use guarantee.
Future<RedeemResult> redeemInvite(
  final RedeemStore store,
  final String userId,
  final RedeemRequest request, {
  required final int now,
}) async {
  // 1. Idempotent replay: already entitled via this code → no re-count.
  final existing = await store.findEntitlement(userId, request.code);
  if (existing != null) {
    return RedeemResult(RedeemStatus.alreadyEntitled, existing);
  }

  // 2. Unknown code.
  final invite = await store.findInvite(request.code);
  if (invite == null) {
    return const RedeemResult(RedeemStatus.invalidCode);
  }

  // 3. Expiry.
  final expiresAt = invite.expiresAt;
  if (expiresAt != null && now > expiresAt) {
    return const RedeemResult(RedeemStatus.expired);
  }

  // 4. Exhaustion.
  if (invite.uses >= invite.maxUses) {
    return const RedeemResult(RedeemStatus.exhausted);
  }

  // 5. Grant: write the entitlement, then consume one use.
  final entitlement = Entitlement(
    userId: userId,
    tier: invite.entitlementTier,
    cohort: invite.cohort,
    source: 'invite',
    code: invite.code,
    grantedAt: now,
  );
  await store.writeEntitlement(entitlement);
  await store.setInviteUses(invite.rowId, invite.uses + 1);
  return RedeemResult(RedeemStatus.granted, entitlement);
}
