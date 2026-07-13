/// Concrete [AppwriteAccountGateway] over the `appwrite` SDK `Account` — the
/// only file in the identity layer that imports the SDK (task 3.1). Mirrors the
/// `appwrite_functions_transport.dart` split: pure seam + service stay
/// SDK-free and unit-testable; this glue is verified live once 0.2 opens.
library;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;

import 'appwrite_auth_service.dart';

class AppwriteAccountSdkGateway implements AppwriteAccountGateway {
  AppwriteAccountSdkGateway(final Client client) : _account = Account(client);

  final Account _account;

  @override
  Future<void> createGoogleSession({
    final List<String> scopes = const [],
    final String? successUrl,
    final String? failureUrl,
  }) async {
    try {
      // Mobile: [successUrl]/[failureUrl] are null, so the SDK auto-derives the
      // callback scheme `appwrite-callback-<projectId>` — the scheme 0.2
      // registered in both iOS plists + AndroidManifest. Web (task 1.5): the
      // service supplies the app-origin redirect targets for the full-page
      // OAuth redirect (a custom scheme has no meaning in a browser). Empty
      // scopes ⇒ null (identity-only session; the Drive token is minted
      // separately by google_sign_in, 3.3).
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        scopes: scopes.isEmpty ? null : scopes,
        success: successUrl,
        failure: failureUrl,
      );
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Google sign-in failed.');
    }
  }

  @override
  Future<AuthUser?> currentUser() async {
    try {
      final models.User user = await _account.get();
      return AuthUser(id: user.$id, email: user.email, name: user.name);
    } on AppwriteException catch (e) {
      // 401 is *no session*, not a fault — degrade to signed-out. Any other
      // code is a genuine transport failure worth surfacing.
      if (e.code == 401) return null;
      throw AuthException(e.message ?? 'Could not read the current session.');
    }
  }

  @override
  Future<void> deleteCurrentSession() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      // Already signed out ⇒ nothing to delete; logout is idempotent.
      if (e.code == 401) return;
      throw AuthException(e.message ?? 'Sign-out failed.');
    }
  }
}
