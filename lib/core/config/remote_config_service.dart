import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'remote_config.dart';

/// Resolves the app's remote config with a strict fallback ladder:
/// **remote → last-cached → compiled defaults**.
///
/// [watch] yields the best-known config immediately (cache or defaults, so the
/// UI never waits on the network), then upgrades to the live row once fetched,
/// then tracks Realtime updates. Every network failure — offline, or a 401 from
/// a session-less client before Phase 3 identity lands — is swallowed, leaving
/// the last good value in place. Successful reads are persisted so the next cold
/// start is instant and offline-correct.
class RemoteConfigService {
  RemoteConfigService({
    required final RemoteConfigSource source,
    required final SharedPreferences prefs,
    final String cacheKey = _defaultCacheKey,
  }) : _source = source,
       _prefs = prefs,
       _cacheKey = cacheKey;

  static const String _defaultCacheKey = 'remote_config.cache.v1';

  final RemoteConfigSource _source;
  final SharedPreferences _prefs;
  final String _cacheKey;

  /// Best-known config available synchronously (cache or compiled defaults).
  /// Callers that need a value before [watch] emits (e.g. a first frame) read
  /// this; it never throws.
  RemoteConfig get current => _cachedOrDefaults();

  /// Fallback-ordered stream of config snapshots. Safe to listen at launch.
  Stream<RemoteConfig> watch() async* {
    yield _cachedOrDefaults();

    try {
      final fetched = RemoteConfig.fromRow(await _source.fetch());
      await _persist(fetched);
      yield fetched;
    } on Object {
      // Offline / unauthenticated / transport error → keep the fallback value.
    }

    yield* _source
        .subscribe()
        .asyncMap((final row) async {
          final live = RemoteConfig.fromRow(row);
          await _persist(live);
          return live;
        })
        .handleError((final Object _) {
          // Socket drop → stop tracking; the cached value stays authoritative
          // until the next launch re-fetches. (Reconnect is a Phase 2 concern.)
        });
  }

  RemoteConfig _cachedOrDefaults() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return const RemoteConfig.defaults();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return RemoteConfig.fromCache(decoded.cast<String, Object?>());
      }
    } on FormatException {
      // Corrupt cache — fall through to compiled defaults.
    }
    return const RemoteConfig.defaults();
  }

  Future<void> _persist(final RemoteConfig config) async {
    await _prefs.setString(_cacheKey, jsonEncode(config.toCache()));
  }
}
