import 'package:invites_redeem/redeem.dart';
import 'package:test/test.dart';

/// In-memory [RedeemStore] double — mirrors the TablesDB store's key lookups
/// (`(userId, code)` for entitlements, `code` for invites) with no live backend.
class FakeRedeemStore implements RedeemStore {
  FakeRedeemStore(final List<Invite> invites) {
    for (final invite in invites) {
      _invites[invite.code] = invite;
    }
  }

  final Map<String, Invite> _invites = <String, Invite>{};
  final List<Entitlement> entitlements = <Entitlement>[];

  @override
  Future<Entitlement?> findEntitlement(
    final String userId,
    final String code,
  ) async {
    for (final e in entitlements) {
      if (e.userId == userId && e.code == code) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<Invite?> findInvite(final String code) async => _invites[code];

  @override
  Future<void> writeEntitlement(final Entitlement entitlement) async {
    entitlements.add(entitlement);
  }

  @override
  Future<void> setInviteUses(
    final String inviteRowId,
    final int newUses,
  ) async {
    final code =
        _invites.values.firstWhere((final i) => i.rowId == inviteRowId).code;
    final old = _invites[code]!;
    _invites[code] = Invite(
      rowId: old.rowId,
      code: old.code,
      cohort: old.cohort,
      entitlementTier: old.entitlementTier,
      maxUses: old.maxUses,
      uses: newUses,
      expiresAt: old.expiresAt,
    );
  }

  Invite invite(final String code) => _invites[code]!;
}

Invite _invite({
  final String code = 'CREW-1',
  final String cohort = 'crew',
  final String tier = 'crew',
  final int maxUses = 10,
  final int uses = 0,
  final int? expiresAt,
}) =>
    Invite(
      rowId: 'row-$code',
      code: code,
      cohort: cohort,
      entitlementTier: tier,
      maxUses: maxUses,
      uses: uses,
      expiresAt: expiresAt,
    );

const int _now = 1_700_000_000_000;

void main() {
  group('redeemInvite — grant', () {
    test('a valid code grants the entitlement and consumes one use', () async {
      final store = FakeRedeemStore([_invite()]);
      final result = await redeemInvite(
        store,
        'user-1',
        const RedeemRequest(code: 'CREW-1'),
        now: _now,
      );

      expect(result.status, RedeemStatus.granted);
      expect(result.entitlement?.tier, 'crew');
      expect(result.entitlement?.cohort, 'crew');
      expect(result.entitlement?.source, 'invite');
      expect(store.entitlements, hasLength(1));
      expect(store.invite('CREW-1').uses, 1); // exactly one consumed
    });
  });

  group('redeemInvite — idempotency (double-submit = one use)', () {
    test('a replay by the same user re-grants without re-counting', () async {
      final store = FakeRedeemStore([_invite()]);
      const req = RedeemRequest(code: 'CREW-1');

      final first = await redeemInvite(store, 'user-1', req, now: _now);
      final replay = await redeemInvite(store, 'user-1', req, now: _now + 5000);

      expect(first.status, RedeemStatus.granted);
      expect(replay.status, RedeemStatus.alreadyEntitled);
      expect(replay.isGrant, isTrue);
      expect(store.entitlements, hasLength(1)); // no duplicate grant
      expect(store.invite('CREW-1').uses, 1); // still one use, not two
    });

    test('a different user consumes a distinct use of the same code', () async {
      final store = FakeRedeemStore([_invite(maxUses: 2)]);
      const req = RedeemRequest(code: 'CREW-1');

      await redeemInvite(store, 'user-1', req, now: _now);
      final second = await redeemInvite(store, 'user-2', req, now: _now);

      expect(second.status, RedeemStatus.granted);
      expect(store.entitlements, hasLength(2));
      expect(store.invite('CREW-1').uses, 2);
    });
  });

  group('redeemInvite — typed rejections', () {
    test('an unknown code is invalidCode and grants nothing', () async {
      final store = FakeRedeemStore([_invite()]);
      final result = await redeemInvite(
        store,
        'user-1',
        const RedeemRequest(code: 'NOPE'),
        now: _now,
      );

      expect(result.status, RedeemStatus.invalidCode);
      expect(result.isGrant, isFalse);
      expect(store.entitlements, isEmpty);
    });

    test('a past expiresAt is rejected as expired', () async {
      final store = FakeRedeemStore([_invite(expiresAt: _now - 1)]);
      final result = await redeemInvite(
        store,
        'user-1',
        const RedeemRequest(code: 'CREW-1'),
        now: _now,
      );

      expect(result.status, RedeemStatus.expired);
      expect(store.entitlements, isEmpty);
      expect(store.invite('CREW-1').uses, 0); // no use consumed on rejection
    });

    test('a code at maxUses is rejected as exhausted', () async {
      final store = FakeRedeemStore([_invite(maxUses: 3, uses: 3)]);
      final result = await redeemInvite(
        store,
        'user-1',
        const RedeemRequest(code: 'CREW-1'),
        now: _now,
      );

      expect(result.status, RedeemStatus.exhausted);
      expect(store.entitlements, isEmpty);
      expect(store.invite('CREW-1').uses, 3); // unchanged
    });

    test('an unexpired future expiresAt still grants', () async {
      final store = FakeRedeemStore([_invite(expiresAt: _now + 86_400_000)]);
      final result = await redeemInvite(
        store,
        'user-1',
        const RedeemRequest(code: 'CREW-1'),
        now: _now,
      );

      expect(result.status, RedeemStatus.granted);
    });
  });

  group('RedeemRequest.fromJson — wire parsing', () {
    test('a missing code is a RedeemRejection (→ 400)', () {
      expect(
        () => RedeemRequest.fromJson(<String, dynamic>{}),
        throwsA(isA<RedeemRejection>()),
      );
    });

    test('a blank code is a RedeemRejection', () {
      expect(
        () => RedeemRequest.fromJson(<String, dynamic>{'code': '   '}),
        throwsA(isA<RedeemRejection>()),
      );
    });

    test('a valid code is trimmed', () {
      final req = RedeemRequest.fromJson(<String, dynamic>{'code': ' CREW-1 '});
      expect(req.code, 'CREW-1');
    });
  });
}
