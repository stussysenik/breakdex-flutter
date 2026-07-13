import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake gateway: canned session state + recorded calls, so this proves the
/// service's stream/session logic with no live Appwrite. Mirrors the
/// `_FakeTransport` idiom in `appwrite_sync_backend_test.dart`.
class _FakeGateway implements AppwriteAccountGateway {
  _FakeGateway({this.user});

  /// The account [currentUser] returns; null = no session.
  AuthUser? user;

  /// When set, [createGoogleSession] throws it (OAuth cancel / provider error).
  AuthException? signInError;

  int createCalls = 0;
  int deleteCalls = 0;
  List<String> lastScopes = const [];
  String? lastSuccessUrl;
  String? lastFailureUrl;

  @override
  Future<void> createGoogleSession({
    final List<String> scopes = const [],
    final String? successUrl,
    final String? failureUrl,
  }) async {
    createCalls++;
    lastScopes = scopes;
    lastSuccessUrl = successUrl;
    lastFailureUrl = failureUrl;
    if (signInError != null) throw signInError!;
    // A successful OAuth flow attaches the session ⇒ a subsequent get() works.
    user = const AuthUser(id: 'u1', email: 'me@example.com', name: 'Me');
  }

  @override
  Future<AuthUser?> currentUser() async => user;

  @override
  Future<void> deleteCurrentSession() async {
    deleteCalls++;
    user = null;
  }
}

void main() {
  group('AppwriteAuthService', () {
    test('refresh() with a live session emits and returns the account', () async {
      final gw = _FakeGateway(
        user: const AuthUser(id: 'u1', email: 'me@example.com'),
      );
      final service = AppwriteAuthService(gw);
      addTearDown(service.dispose);

      final emissions = <AuthUser?>[];
      service.userStream.listen(emissions.add);

      final user = await service.refresh();

      expect(user?.id, 'u1');
      expect(service.currentUser?.id, 'u1');
      expect(service.isSignedIn, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [isA<AuthUser>()]);
    });

    test('refresh() with no session emits and returns null', () async {
      final service = AppwriteAuthService(_FakeGateway());
      addTearDown(service.dispose);

      expect(await service.refresh(), isNull);
      expect(service.isSignedIn, isFalse);
    });

    test('signInWithGoogle() creates a session and emits the account', () async {
      final gw = _FakeGateway();
      final service = AppwriteAuthService(gw);
      addTearDown(service.dispose);

      final emissions = <AuthUser?>[];
      service.userStream.listen(emissions.add);

      final user = await service.signInWithGoogle();

      expect(gw.createCalls, 1);
      expect(user.email, 'me@example.com');
      expect(service.isSignedIn, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [isA<AuthUser>()]);
    });

    test('signInWithGoogle() forwards identity-only (empty) scopes', () async {
      final gw = _FakeGateway();
      final service = AppwriteAuthService(gw);
      addTearDown(service.dispose);

      await service.signInWithGoogle();

      expect(gw.lastScopes, isEmpty);
    });

    test('signInWithGoogle() surfaces a provider error as AuthException', () async {
      final gw = _FakeGateway()..signInError = const AuthException('cancelled');
      final service = AppwriteAuthService(gw);
      addTearDown(service.dispose);

      expect(
        () => service.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('signInWithGoogle() throws when the flow leaves no session', () async {
      // Gateway that "succeeds" the flow but still reports no user.
      final service = AppwriteAuthService(_NoSessionGateway());
      addTearDown(service.dispose);

      expect(
        () => service.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut() deletes the session and emits null', () async {
      final gw = _FakeGateway(
        user: const AuthUser(id: 'u1', email: 'me@example.com'),
      );
      final service = AppwriteAuthService(gw);
      addTearDown(service.dispose);
      await service.refresh();

      final emissions = <AuthUser?>[];
      service.userStream.listen(emissions.add);

      await service.signOut();

      expect(gw.deleteCalls, 1);
      expect(service.isSignedIn, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [null]);
    });

    test('AuthUser value equality', () {
      expect(
        const AuthUser(id: 'u1', email: 'a@b.com'),
        const AuthUser(id: 'u1', email: 'a@b.com'),
      );
      expect(
        const AuthUser(id: 'u1', email: 'a@b.com'),
        isNot(const AuthUser(id: 'u2', email: 'a@b.com')),
      );
    });

    test('web sign-in passes app-origin success/failure redirect URLs (1.5)',
        () async {
      final gw = _FakeGateway();
      final service = AppwriteAuthService(
        gw,
        isWeb: true,
        baseUri: () => Uri.parse('https://app.breakdex.io/library?x=1'),
      );
      addTearDown(service.dispose);

      await service.signInWithGoogle();

      expect(gw.lastSuccessUrl, 'https://app.breakdex.io');
      expect(gw.lastFailureUrl, 'https://app.breakdex.io/auth');
    });

    test('mobile sign-in leaves redirect URLs null (SDK auto-scheme)', () async {
      final gw = _FakeGateway();
      final service = AppwriteAuthService(gw, isWeb: false);
      addTearDown(service.dispose);

      await service.signInWithGoogle();

      expect(gw.lastSuccessUrl, isNull);
      expect(gw.lastFailureUrl, isNull);
    });
  });
}

/// Reports a "successful" OAuth flow that nonetheless yields no session — the
/// degenerate case `signInWithGoogle` must reject.
class _NoSessionGateway implements AppwriteAccountGateway {
  @override
  Future<void> createGoogleSession({
    final List<String> scopes = const [],
    final String? successUrl,
    final String? failureUrl,
  }) async {}

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<void> deleteCurrentSession() async {}
}
