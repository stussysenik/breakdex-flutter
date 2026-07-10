import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart' show sharedPreferencesProvider;
import 'appwrite_env.dart';
import 'appwrite_remote_config_source.dart';
import 'remote_config.dart';
import 'remote_config_service.dart';

/// Shared Appwrite client for the live `breakdex` project (read-only until a
/// session lands in Phase 3). Phase 2's sync backend will reuse this provider.
final appwriteClientProvider = Provider<Client>((final ref) {
  return Client()
    ..setEndpoint(kAppwriteEndpoint)
    ..setProject(kAppwriteProjectId);
});

final remoteConfigSourceProvider = Provider<RemoteConfigSource>((final ref) {
  return AppwriteRemoteConfigSource(client: ref.watch(appwriteClientProvider));
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
