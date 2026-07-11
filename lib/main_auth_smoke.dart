/// THROWAWAY smoke harness for task 0.2 / 3.1 — DELETE after the live login
/// proof. Runs *only* the Appwrite login screen against the live `breakdex`
/// client, then shows the resolved session so we can eyeball a non-null
/// `account.get()`. Not wired to production routing; run with:
///   flutter run -t lib/main_auth_smoke.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/appwrite_auth_providers.dart';
import 'features/auth/appwrite_login_screen.dart';

void main() {
  runApp(const ProviderScope(child: _SmokeApp()));
}

class _SmokeApp extends StatelessWidget {
  const _SmokeApp();

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Auth smoke (0.2)',
      theme: ThemeData(useMaterial3: true),
      home: Builder(
        builder: (final context) => AppwriteLoginScreen(
          onSignedIn: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _ProofScreen()),
          ),
        ),
      ),
    );
  }
}

/// Reads the live session back through the same provider the app will use.
/// A visible id + email here is the green proof that 0.2's OAuth round-trip
/// issued a real Appwrite session.
class _ProofScreen extends ConsumerWidget {
  const _ProofScreen();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final user = ref.watch(currentAppwriteUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Session proof')),
      body: Center(
        child: user.when(
          loading: () => const CircularProgressIndicator(),
          error: (final e, _) => Text('ERROR: $e'),
          data: (final u) => u == null
              ? const Text('NULL session (signed out)')
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅ SESSION OK',
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 16),
                      SelectableText('id:    ${u.id}'),
                      SelectableText('email: ${u.email}'),
                      SelectableText('name:  ${u.name}'),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
