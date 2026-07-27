/// Appwrite Account identity — task 3.1.
///
/// This is the *pure* half (no `appwrite` SDK import), mirroring the transport
/// seam (`appwrite_transport.dart`): the SDK is touched only by the concrete
/// [AppwriteAccountGateway] in `appwrite_account_gateway.dart`, so the service's
/// session/stream logic is unit-testable with no live backend.
///
/// Identity model (locked): any Google sign-in creates an isolated Appwrite
/// Account session (design D3 legacy-identity claim lands in 3.4). The Google
/// **Drive** token is a *separate* concern minted by `google_sign_in` (3.3
/// demotes it to Drive-only); this service never mints Drive scopes — its
/// session is identity-only.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:breakdex/core/utils/diagnostics.dart';

/// A provider-neutral, immutable view of the signed-in account. Generic data,
/// not an opaque SDK object (DOP): the rest of the app keys on [id] (the
/// Appwrite `userId`) and displays [email]/[name].
class AuthUser {
  const AuthUser({required this.id, required this.email, this.name = ''});

  /// The Appwrite Account `$id` — the canonical user id every backend row keys
  /// on once identity cuts over (design D3).
  final String id;

  /// The verified Google email (the join key for the 3.4 legacy claim flow).
  final String email;

  /// Display name, when the provider supplied one. May be empty.
  final String name;

  @override
  bool operator ==(final Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, email, name);

  @override
  String toString() => 'AuthUser(id: $id, email: $email)';
}

/// Thrown when an identity operation fails (the OAuth flow was cancelled, the
/// provider rejected the sign-in, or the network was unreachable). Named to
/// mirror `AppwriteException` (transport) so callers see one wrapper, never the
/// SDK's own exception type. A *missing* session is **not** an error — it
/// surfaces as a `null` [AuthUser] (see [AppwriteAccountGateway.currentUser]).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException($message)';
}

/// The single seam between [AppwriteAuthService] and a concrete Appwrite
/// `Account`. Three doors, all the service needs:
///   * [createGoogleSession] — trigger the Google OAuth2 web flow; completes
///     when the callback resolves, attaching the session to the client.
///     [successUrl]/[failureUrl] are the **web** redirect targets (task 1.5):
///     on web the SDK does a full-page redirect and must be told where to
///     return; on mobile they are null and the SDK auto-derives the
///     `appwrite-callback-<projectId>` custom scheme.
///   * [currentUser] — the signed-in account, or `null` when there is no
///     session (a 401 is *no session*, not a fault). Throws [AuthException]
///     only on a genuine transport failure.
///   * [deleteCurrentSession] — logout; idempotent (no session → no-op).
abstract interface class AppwriteAccountGateway {
  Future<void> createGoogleSession({
    final List<String> scopes,
    final String? successUrl,
    final String? failureUrl,
  });

  /// Establish a session from email/password (the dev path — task 1.2, gated by
  /// [kDevEmailAuthEnabled]). Unlike [createGoogleSession] this resolves
  /// **in-place** on every surface — `account.createEmailPasswordSession` needs
  /// no redirect or callback scheme (design D4) — so the service reads
  /// [currentUser] immediately after. Throws [AuthException] on bad credentials
  /// (mirror of the Google mapping). **Sign-in only:** there is deliberately no
  /// `createAccount` door — dev accounts are minted owner-side.
  Future<void> createEmailPasswordSession({
    required final String email,
    required final String password,
  });

  Future<AuthUser?> currentUser();

  Future<void> deleteCurrentSession();
}

/// Identity service: OAuth2 session create / refresh / logout, plus a broadcast
/// current-user stream. Exposed via Riverpod (`appwrite_auth_providers.dart`).
///
/// The stream seeds from any persisted session at launch ([refresh]) and then
/// emits on every sign-in / sign-out. Session persistence across restarts is
/// the SDK's cookie/keychain store; [refresh] proves it by re-reading the
/// account (task 3.1's "session persistence proven" gate — unit-proven here via
/// the gateway seam, live-proven once 0.2 opens).
class AppwriteAuthService {
  /// [isWeb]/[baseUri] are injectable purely so the web redirect branch (task
  /// 1.5) is unit-testable on the VM; production uses `kIsWeb` + `Uri.base`.
  AppwriteAuthService(
    this._gateway, {
    final bool isWeb = kIsWeb,
    final Uri Function()? baseUri,
  })  : _isWeb = isWeb,
        _baseUri = baseUri ?? _defaultBaseUri;

  static Uri _defaultBaseUri() => Uri.base;

  final AppwriteAccountGateway _gateway;
  final bool _isWeb;
  final Uri Function() _baseUri;
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  /// Emits the current account on every identity change, `null` when signed
  /// out. Cold consumers should combine with [refresh] for the initial value.
  Stream<AuthUser?> get userStream => _controller.stream;

  /// The last known account, or `null`. Synchronous mirror of the stream.
  AuthUser? get currentUser => _current;

  bool get isSignedIn => _current != null;

  /// Re-read the session (launch seeding *and* explicit refresh). Emits and
  /// returns the account, or `null` when there is no live session.
  Future<AuthUser?> refresh() async {
    final user = await _gateway.currentUser();
    _emit(user);
    return user;
  }

  /// Run the Google OAuth2 flow and return the resulting account. Throws
  /// [AuthException] if the flow completes without a usable session.
  ///
  /// On **web** (task 1.5) [createGoogleSession] triggers a full-page redirect
  /// to Google, so control does not return here — the app reboots at
  /// [successUrl] and the returning cookie session is seeded by [refresh] on the
  /// next launch. On **mobile** the flow resolves in-app, so the account is read
  /// immediately below. The httpOnly session cookie is set by Appwrite against
  /// the registered web-platform origin; nothing is persisted in `localStorage`
  /// (repo security posture — enforced by console CORS/platform config).
  Future<AuthUser> signInWithGoogle({final List<String> scopes = const []}) async {
    final (String? success, String? failure) = _webRedirects();
    await _gateway.createGoogleSession(
      scopes: scopes,
      successUrl: success,
      failureUrl: failure,
    );
    final user = await _gateway.currentUser();
    DiagnosticsLog.info('Auth',
        'Post-OAuth session read: ${user == null ? 'NO SESSION' : 'user=${user.id} email=${user.email}'}');
    if (user == null) {
      throw const AuthException('Sign-in completed without creating a session.');
    }
    _emit(user);
    return user;
  }

  /// Sign in a dev account via email/password and return the resulting account
  /// (task 1.2, gated by [kDevEmailAuthEnabled]). Redirect-free on every surface
  /// (design D4): create the session, re-read the account, emit. Throws
  /// [AuthException] on bad credentials, and — matching [signInWithGoogle]'s
  /// contract — if a *successful* session create still yields no account (a 401
  /// on the immediate [currentUser] read is a fault here, not "no session").
  Future<AuthUser> signInWithEmailPassword({
    required final String email,
    required final String password,
  }) async {
    await _gateway.createEmailPasswordSession(email: email, password: password);
    final user = await _gateway.currentUser();
    if (user == null) {
      throw const AuthException('Sign-in completed without creating a session.');
    }
    _emit(user);
    return user;
  }

  /// The web OAuth redirect targets, or `(null, null)` off web. Both point at
  /// the app's own origin (which must be registered as an Appwrite web platform
  /// for CORS + the httpOnly cookie): success returns to the app, which reboots
  /// and re-seeds the session via [refresh]; failure lands on the in-app `/auth`
  /// screen. Mobile leaves them null so the SDK auto-derives the custom scheme.
  (String?, String?) _webRedirects() {
    if (!_isWeb) return (null, null);
    final origin = _baseUri().origin;
    return (origin, '$origin/auth');
  }

  /// Delete the current session and emit signed-out.
  Future<void> signOut() async {
    await _gateway.deleteCurrentSession();
    _emit(null);
  }

  void _emit(final AuthUser? user) {
    _current = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
