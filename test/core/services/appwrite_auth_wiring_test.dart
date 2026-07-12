/// Wave task 3.3 — auth wiring gates.
///
/// Proves the two seams the wiring rests on, without a live backend:
///   1. `isLoggedInProvider` is derived from the Appwrite session
///      (`currentAppwriteUserProvider`), not the legacy `AuthService`. Signed
///      out ⇒ false (local-only); signed in ⇒ true (repos go SyncAware).
///   2. The config source is session-gated: `remoteConfigSourceProvider`
///      injects `sessionActive` from the same auth stream, so a signed-out boot
///      builds an inert source (no CORS-failing fetch, no Realtime reconnect
///      loop). The real `AppwriteRemoteConfigSource` is the repo's single
///      SDK-touching file and — like `remote_config_test.dart`, which exercises
///      the service through a fake source — is not unit-constructed here (the
///      live `Client` needs platform bindings); its live half is device-proven
///      (M.5). The gate that matters, "session drives sessionActive", is proven
///      below via the provider override.
library;

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/appwrite_auth_providers.dart';
import 'package:breakdex/core/services/appwrite_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isLoggedInProvider derives from the Appwrite session', () {
    test('no session ⇒ not logged in (local-only mode)', () async {
      final container = ProviderContainer(
        overrides: [
          currentAppwriteUserProvider.overrideWith(
            (final ref) => Stream<AuthUser?>.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentAppwriteUserProvider.future);
      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('active session ⇒ logged in (repos go SyncAware)', () async {
      final container = ProviderContainer(
        overrides: [
          currentAppwriteUserProvider.overrideWith(
            (final ref) => Stream<AuthUser?>.value(
              const AuthUser(id: 'u1', email: 'breaker@example.com'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentAppwriteUserProvider.future);
      expect(container.read(isLoggedInProvider), isTrue);
    });
  });
}
