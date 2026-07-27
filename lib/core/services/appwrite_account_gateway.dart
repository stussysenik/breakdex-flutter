/// Concrete [AppwriteAccountGateway] over the `appwrite` SDK `Account` — the
/// only file in the identity layer that imports the SDK (task 3.1). Mirrors the
/// `appwrite_functions_transport.dart` split: pure seam + service stay
/// SDK-free and unit-testable; this glue is verified live once 0.2 opens.
library;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:breakdex/core/utils/diagnostics.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';

class AppwriteAccountSdkGateway implements AppwriteAccountGateway {
  AppwriteAccountSdkGateway(final Client client)
      : _account = Account(client),
        _projectId = client.config['project'] ?? '',
        _endpoint = client.endPoint;

  final Account _account;
  final String _projectId;
  final String _endpoint;

  @override
  Future<void> createGoogleSession({
    final List<String> scopes = const [],
    final String? successUrl,
    final String? failureUrl,
  }) async {
    // Web (task 1.5): the service supplies app-origin redirect targets for the
    // full-page OAuth redirect — the SDK path is fine there.
    if (successUrl != null) {
      try {
        DiagnosticsLog.info('Auth',
            'OAuth start (web) success=$successUrl failure=$failureUrl scopes=${scopes.length}');
        await _account.createOAuth2Session(
          provider: OAuthProvider.google,
          scopes: scopes.isEmpty ? null : scopes,
          success: successUrl,
          failure: failureUrl,
        );
      } on AppwriteException catch (e) {
        DiagnosticsLog.error('Auth',
            'OAuth failed code=${e.code} type=${e.type} message=${e.message}');
        throw AuthException(e.message ?? 'Google sign-in failed.');
      }
      return;
    }

    // Mobile: drive the browser leg ourselves instead of the SDK's `webAuth` —
    // SDK 25.x's parser swallows the callback's query params (incl. Appwrite's
    // `error` on the failure redirect), which reduced a live server-side
    // failure to the opaque "Key and Secret not available" (device,
    // 2026-07-16). Token flow (`/account/tokens/oauth2`) is the recommended
    // mobile pattern: the callback carries userId+secret, exchanged via
    // [Account.createSession]. The `appwrite-callback-<projectId>` scheme is
    // registered in both iOS plists + AndroidManifest (0.2). Empty scopes ⇒
    // identity-only session (the Drive token is minted by google_sign_in, 3.3).
    final String scheme = 'appwrite-callback-$_projectId';
    final Uri authUrl = Uri.parse('$_endpoint/account/tokens/oauth2/google').replace(
      queryParameters: {
        'project': _projectId,
        'success': '$scheme://oauth',
        'failure': '$scheme://oauth',
        if (scopes.isNotEmpty) 'scopes[]': scopes,
      },
    );
    DiagnosticsLog.info('Auth', 'OAuth start (mobile token flow) url=$authUrl');

    final String rawCallback;
    try {
      rawCallback = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: scheme,
        options: const FlutterWebAuth2Options(useWebview: false),
      );
    } on Exception catch (e) {
      DiagnosticsLog.error('Auth', 'OAuth browser leg failed/cancelled: $e');
      throw const AuthException('Google sign-in was cancelled or failed to open.');
    }

    final Map<String, String> params = Uri.parse(rawCallback).queryParameters;
    DiagnosticsLog.info('Auth', 'OAuth callback params: ${params.map(
      (k, v) => MapEntry(k, k == 'secret' ? '${v.substring(0, v.length < 8 ? v.length : 8)}…' : v),
    )}');

    final String? userId = params['userId'];
    final String? secret = params['secret'];
    if (userId == null || secret == null) {
      final reason = params['error'] ?? params['message'] ?? 'no error param';
      DiagnosticsLog.error('Auth', 'OAuth failure redirect: $reason');
      throw AuthException('Google sign-in failed: $reason');
    }

    try {
      await _account.createSession(userId: userId, secret: secret);
      DiagnosticsLog.info('Auth', 'OAuth token exchanged: session created for user=$userId');
    } on AppwriteException catch (e) {
      DiagnosticsLog.error('Auth',
          'Token→session exchange failed code=${e.code} type=${e.type} message=${e.message}');
      throw AuthException(e.message ?? 'Google sign-in failed.');
    }
  }

  @override
  Future<void> createEmailPasswordSession({
    required final String email,
    required final String password,
  }) async {
    try {
      // Resolves in-place — no OAuth redirect, no callback scheme (design D4).
      // A wrong password / unknown account surfaces as an AppwriteException,
      // mapped to AuthException so callers only ever see the one wrapper.
      await _account.createEmailPasswordSession(email: email, password: password);
    } on AppwriteException catch (e) {
      throw AuthException(e.message ?? 'Email sign-in failed.');
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
