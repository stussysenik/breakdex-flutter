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
///   * [currentUser] — the signed-in account, or `null` when there is no
///     session (a 401 is *no session*, not a fault). Throws [AuthException]
///     only on a genuine transport failure.
///   * [deleteCurrentSession] — logout; idempotent (no session → no-op).
abstract interface class AppwriteAccountGateway {
  Future<void> createGoogleSession({final List<String> scopes});

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
  AppwriteAuthService(this._gateway);

  final AppwriteAccountGateway _gateway;
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
  Future<AuthUser> signInWithGoogle({final List<String> scopes = const []}) async {
    await _gateway.createGoogleSession(scopes: scopes);
    final user = await _gateway.currentUser();
    if (user == null) {
      throw const AuthException('Sign-in completed without creating a session.');
    }
    _emit(user);
    return user;
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
