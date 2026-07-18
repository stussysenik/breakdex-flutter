/// Regression: [hydrateOnLoginTriggerProvider] must not write to another
/// provider synchronously while it is building — Riverpod asserts
/// "Providers are not allowed to modify other providers during their
/// initialization", which surfaced as a red screen at shell root the first
/// time the app booted with a live Appwrite session.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/providers.dart' show syncServiceProvider;
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:breakdex/core/services/hydrate_on_login_providers.dart';

void main() {
  const user = AuthUser(id: 'user-1', email: 'a@b.c');

  test('trigger does not modify providers during its own build', () async {
    var hydrateAttempts = 0;
    final container = ProviderContainer(
      overrides: [
        currentAppwriteUserProvider.overrideWith(
          (final ref) => Stream.value(user),
        ),
        // _hydrate reads this lazily inside its try/catch; throwing here counts
        // the attempt without needing a full SyncService fake.
        syncServiceProvider.overrideWith((final ref) {
          hydrateAttempts++;
          throw StateError('fake backend unavailable');
        }),
      ],
    );
    addTearDown(container.dispose);

    // Make the user available before the trigger first builds — the crash
    // path is "session already live when the shell mounts".
    await container.read(currentAppwriteUserProvider.future);

    // Pre-fix this read threw the framework assertion.
    expect(() => container.read(hydrateOnLoginTriggerProvider), returnsNormally);

    // The deferred hydrate fires exactly once for the same user.
    await Future<void>.delayed(Duration.zero);
    container.read(hydrateOnLoginTriggerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(hydrateAttempts, 1);
  });
}
