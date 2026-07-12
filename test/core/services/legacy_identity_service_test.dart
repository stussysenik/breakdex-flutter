/// Wave task 3.4 — legacy-identity claim (D3) logic gates.
///
/// Proves the pure claim semantics via a fake gateway (no live backend): the
/// map is additive, idempotent on re-login, never clobbers a conflicting
/// mapping, and no-ops for fresh Appwrite-native installs. The live
/// two-install proof ("same Google account → one dataset") is Phase M.
library;

import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/legacy_identity_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory gateway keyed by firebaseUid; counts writes to catch double-claims.
class _FakeGateway implements LegacyIdentityGateway {
  _FakeGateway({this.throwOnPut = false});

  final bool throwOnPut;
  final Map<String, LegacyIdentity> byFirebaseUid = {};
  int puts = 0;

  @override
  Future<String?> resolveByFirebaseUid(final String firebaseUid) async =>
      byFirebaseUid[firebaseUid]?.appwriteUserId;

  @override
  Future<void> put(final LegacyIdentity identity) async {
    if (throwOnPut) throw StateError('write not provisioned');
    puts++;
    byFirebaseUid[identity.firebaseUid] = identity;
  }
}

const _user = AuthUser(id: 'aw-1', email: 'breaker@example.com');

void main() {
  test('fresh install (no Firebase uid) ⇒ no-op, nothing written', () async {
    final gw = _FakeGateway();
    final outcome = await LegacyIdentityClaimService(gw)
        .claimOnLogin(appwriteUser: _user, firebaseUid: '');
    expect(outcome, LegacyClaimOutcome.noLegacyIdentity);
    expect(gw.puts, 0);
  });

  test('first login with a legacy uid ⇒ writes exactly one mapping', () async {
    final gw = _FakeGateway();
    final outcome = await LegacyIdentityClaimService(gw)
        .claimOnLogin(appwriteUser: _user, firebaseUid: 'fb-legacy');
    expect(outcome, LegacyClaimOutcome.claimed);
    expect(gw.puts, 1);
    expect(gw.byFirebaseUid['fb-legacy']?.appwriteUserId, 'aw-1');
    expect(gw.byFirebaseUid['fb-legacy']?.email, 'breaker@example.com');
  });

  test('re-login is idempotent ⇒ no second write', () async {
    final gw = _FakeGateway();
    final service = LegacyIdentityClaimService(gw);
    await service.claimOnLogin(appwriteUser: _user, firebaseUid: 'fb-legacy');
    final second = await service.claimOnLogin(
      appwriteUser: _user,
      firebaseUid: 'fb-legacy',
    );
    expect(second, LegacyClaimOutcome.alreadyClaimed);
    expect(gw.puts, 1);
  });

  test('uid already mapped to a different Appwrite id ⇒ conflict, untouched',
      () async {
    final gw = _FakeGateway()
      ..byFirebaseUid['fb-legacy'] = const LegacyIdentity(
        firebaseUid: 'fb-legacy',
        appwriteUserId: 'aw-OTHER',
        email: 'someone@else.com',
      );
    final outcome = await LegacyIdentityClaimService(gw)
        .claimOnLogin(appwriteUser: _user, firebaseUid: 'fb-legacy');
    expect(outcome, LegacyClaimOutcome.conflict);
    expect(gw.puts, 0);
    expect(gw.byFirebaseUid['fb-legacy']?.appwriteUserId, 'aw-OTHER');
  });

  test('gateway write failure ⇒ failed outcome, never throws', () async {
    final gw = _FakeGateway(throwOnPut: true);
    final outcome = await LegacyIdentityClaimService(gw)
        .claimOnLogin(appwriteUser: _user, firebaseUid: 'fb-legacy');
    expect(outcome, LegacyClaimOutcome.failed);
  });
}
