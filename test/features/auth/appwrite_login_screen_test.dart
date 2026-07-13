import 'dart:async';

import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/features/auth/appwrite_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gateway whose sign-in the test controls: block it (loading state) or fail it
/// (error state) via [gate] / [error].
class _ControllableGateway implements AppwriteAccountGateway {
  Completer<void>? gate;
  AuthException? error;
  int emailCalls = 0;

  @override
  Future<void> createGoogleSession({
    final List<String> scopes = const [],
    final String? successUrl,
    final String? failureUrl,
  }) async {
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> createEmailPasswordSession({
    required final String email,
    required final String password,
  }) async {
    emailCalls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<AuthUser?> currentUser() async =>
      const AuthUser(id: 'u1', email: 'me@example.com');

  @override
  Future<void> deleteCurrentSession() async {}
}

Widget _host(final AppwriteAccountGateway gw, {final VoidCallback? onSignedIn}) {
  return ProviderScope(
    overrides: [
      appwriteAuthServiceProvider.overrideWith((final ref) {
        final service = AppwriteAuthService(gw);
        ref.onDispose(service.dispose);
        return service;
      }),
    ],
    child: MaterialApp(home: AppwriteLoginScreen(onSignedIn: onSignedIn)),
  );
}

void main() {
  const buttonKey = ValueKey('login-google-button');
  const errorKey = ValueKey('login-error');

  testWidgets('idle: shows the Google action, no spinner, no error',
      (final tester) async {
    await tester.pumpWidget(_host(_ControllableGateway()));

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(errorKey), findsNothing);
    expect(find.byKey(buttonKey), findsOneWidget);
  });

  testWidgets('loading: spinner shown, button disabled while signing in',
      (final tester) async {
    final gw = _ControllableGateway()..gate = Completer<void>();
    await tester.pumpWidget(_host(gw));

    await tester.tap(find.byKey(buttonKey));
    await tester.pump(); // enter loading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(buttonKey),
    );
    expect(button.onPressed, isNull); // disabled

    gw.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('error: message + "Try again" after a failed sign-in',
      (final tester) async {
    final gw = _ControllableGateway()
      ..error = const AuthException('Google sign-in was cancelled.');
    await tester.pumpWidget(_host(gw));

    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(errorKey), findsOneWidget);
    expect(find.text('Google sign-in was cancelled.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  // The dev form is compile-time gated (kDevEmailAuthEnabled), so its presence
  // follows the build's dart-define. Under a plain `flutter test` the flag is
  // OFF and the form must be absent (the byte-identical guarantee, design D2);
  // under `--dart-define=DEV_EMAIL_AUTH=true` it must appear and submit.
  const emailField = ValueKey('dev-email-field');
  const submitKey = ValueKey('dev-email-submit');

  testWidgets('dev email form presence tracks kDevEmailAuthEnabled',
      (final tester) async {
    await tester.pumpWidget(_host(_ControllableGateway()));

    if (kDevEmailAuthEnabled) {
      expect(find.byKey(emailField), findsOneWidget);
      expect(find.byKey(submitKey), findsOneWidget);
    } else {
      expect(find.byKey(emailField), findsNothing);
      expect(find.byKey(submitKey), findsNothing);
      expect(find.text('Sign in with email'), findsNothing);
    }
  });

  testWidgets('flag ON: dev form submits credentials and calls onSignedIn',
      (final tester) async {
    if (!kDevEmailAuthEnabled) return; // only meaningful with the dart-define

    final gw = _ControllableGateway();
    var signedIn = false;
    await tester.pumpWidget(_host(gw, onSignedIn: () => signedIn = true));

    await tester.enterText(find.byKey(emailField), 'dev0@example.com');
    await tester.enterText(
      find.byKey(const ValueKey('dev-password-field')),
      'hunter2',
    );
    await tester.tap(find.byKey(submitKey));
    await tester.pumpAndSettle();

    expect(gw.emailCalls, 1);
    expect(signedIn, isTrue);
  });
}
