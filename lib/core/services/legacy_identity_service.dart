/// Legacy identity claim (design D3) — task 3.4.
///
/// Existing Firestore records are keyed by **Firebase uid**; the new canonical
/// identity is the **Appwrite `userId`**. Appwrite Account (Google OAuth2)
/// already resolves the *same* Google account to *one* stable `appwriteUserId`
/// across installs — so cross-install identity is guaranteed by Appwrite itself.
/// This service's job is the *link*: on first Appwrite login it records a
/// `legacyIdentities` row mapping the device's old `firebaseUid → appwriteUserId`
/// (with the verified email), so backfill (4.1) and pulls resolve legacy rows to
/// the Appwrite id and nothing is orphaned. Additive + idempotent + auditable:
/// it never overwrites an existing mapping and never hard-fails the caller.
///
/// This is the *pure* half (no `appwrite` SDK import), mirroring the auth/
/// transport seams: the SDK is touched only by the concrete gateway in
/// `legacy_identity_gateway.dart`, so the claim logic is unit-testable offline.
library;

import 'appwrite_auth_service.dart' show AuthUser;

/// An immutable legacy→Appwrite identity link (generic data, DOP).
class LegacyIdentity {
  const LegacyIdentity({
    required this.firebaseUid,
    required this.appwriteUserId,
    required this.email,
  });

  final String firebaseUid;
  final String appwriteUserId;
  final String email;

  @override
  bool operator ==(final Object other) =>
      other is LegacyIdentity &&
      other.firebaseUid == firebaseUid &&
      other.appwriteUserId == appwriteUserId &&
      other.email == email;

  @override
  int get hashCode => Object.hash(firebaseUid, appwriteUserId, email);

  @override
  String toString() =>
      'LegacyIdentity($firebaseUid → $appwriteUserId, $email)';
}

/// The single seam between [LegacyIdentityClaimService] and the `legacyIdentities`
/// Appwrite table. Two doors:
///   * [resolveByFirebaseUid] — the `appwriteUserId` already mapped to this
///     Firebase uid, or `null` when unclaimed.
///   * [put] — persist a new mapping row (owner-only perms). Only called by the
///     service when no mapping exists, so it never needs upsert semantics.
abstract interface class LegacyIdentityGateway {
  Future<String?> resolveByFirebaseUid(final String firebaseUid);

  Future<void> put(final LegacyIdentity identity);
}

/// Outcome of a claim attempt — explicit states beat a bare bool/null (DOP:
/// callers and tests reason about *why* nothing was written).
enum LegacyClaimOutcome {
  /// No Firebase uid on this device (a fresh Appwrite-native install) — nothing
  /// to map. The common case for new users.
  noLegacyIdentity,

  /// A new `firebaseUid → appwriteUserId` row was written.
  claimed,

  /// The Firebase uid was already mapped to *this same* Appwrite id — idempotent
  /// no-op (a re-login).
  alreadyClaimed,

  /// The Firebase uid was already mapped to a *different* Appwrite id — an
  /// anomaly. Left untouched (never clobbered) and surfaced for audit.
  conflict,

  /// The gateway threw (offline / permissions not yet provisioned). Logged, not
  /// fatal — the caller keeps working; the claim retries on the next login.
  failed,
}

class LegacyIdentityClaimService {
  const LegacyIdentityClaimService(this._gateway);

  final LegacyIdentityGateway _gateway;

  /// Claim on first Appwrite login. Idempotent and non-throwing.
  ///
  /// [firebaseUid] is the device's legacy Firebase uid (empty on fresh installs).
  /// Writes a mapping only when the uid is present and unclaimed; a re-login or a
  /// conflicting/failed attempt never writes and never throws.
  Future<LegacyClaimOutcome> claimOnLogin({
    required final AuthUser appwriteUser,
    required final String firebaseUid,
  }) async {
    if (firebaseUid.isEmpty) return LegacyClaimOutcome.noLegacyIdentity;
    try {
      final existing = await _gateway.resolveByFirebaseUid(firebaseUid);
      if (existing != null) {
        return existing == appwriteUser.id
            ? LegacyClaimOutcome.alreadyClaimed
            : LegacyClaimOutcome.conflict;
      }
      await _gateway.put(
        LegacyIdentity(
          firebaseUid: firebaseUid,
          appwriteUserId: appwriteUser.id,
          email: appwriteUser.email,
        ),
      );
      return LegacyClaimOutcome.claimed;
    } on Object catch (_) {
      return LegacyClaimOutcome.failed;
    }
  }
}
