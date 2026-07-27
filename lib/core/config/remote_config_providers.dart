import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/services/appwrite_auth_providers.dart' show currentAppwriteUserProvider;
import 'package:breakdex/core/services/settings_service.dart' show sharedPreferencesProvider;
import 'package:breakdex/core/config/appwrite_env.dart';
import 'package:breakdex/core/config/appwrite_remote_config_source.dart';
import 'package:breakdex/core/config/remote_config.dart';
import 'package:breakdex/core/config/remote_config_service.dart';

/// Shared Appwrite client for the live `breakdex` project (read-only until a
/// session lands in Phase 3). Phase 2's sync backend will reuse this provider.
final appwriteClientProvider = Provider<Client>((final ref) {
  return Client()
    ..setEndpoint(kAppwriteEndpoint)
    ..setProject(kAppwriteProjectId);
});

final remoteConfigSourceProvider = Provider<RemoteConfigSource>((final ref) {
  // Session-aware (wave task 3.3): the live fetch/subscribe path fires only
  // while an Appwrite session exists. Watching the auth stream rebuilds this
  // provider (and the service + stream below) on sign-in/out — sign-out tears
  // the Realtime socket down via the source's onCancel, so the session-less
  // reconnect loop can never return.
  final sessionActive =
      ref.watch(currentAppwriteUserProvider).valueOrNull != null;
  return AppwriteRemoteConfigSource(
    client: ref.watch(appwriteClientProvider),
    sessionActive: sessionActive,
  );
});

final remoteConfigServiceProvider = Provider<RemoteConfigService>((final ref) {
  return RemoteConfigService(
    source: ref.watch(remoteConfigSourceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Fallback-ordered live config: cached/defaults immediately, then the live row,
/// then Realtime updates. Consumers read `.valueOrNull ?? const
/// RemoteConfig.defaults()` — the stream always emits a usable value first.
final remoteConfigProvider = StreamProvider<RemoteConfig>((final ref) {
  return ref.watch(remoteConfigServiceProvider).watch();
});
