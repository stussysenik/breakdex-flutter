import 'dart:convert';

import 'package:meta/meta.dart';

/// Typed, immutable snapshot of the `appConfig` singleton row.
///
/// The three map columns (`featureFlags`, `killSwitches`, `cohortProfiles`) ride
/// as JSON **strings** in Appwrite (TablesDB has no native map type — the repo's
/// payload-as-JSON idiom). [RemoteConfig.fromRow] decodes them defensively:
/// malformed JSON degrades to an empty map, never throws — a corrupt remote
/// value must not brick a launch.
///
/// [RemoteConfig.defaults] is the **compiled fallback**: `minSupportedBuild == 0`
/// (the version gate can never fire) and every map empty (no flag flips behavior).
/// This is the last rung of the fallback ladder — remote → last-cached → defaults.
@immutable
class RemoteConfig {
  const RemoteConfig({
    required this.version,
    required this.minSupportedBuild,
    required this.latestBuild,
    required this.updateMessage,
    required this.featureFlags,
    required this.killSwitches,
    required this.cohortProfiles,
    required this.updatedAt,
  });

  /// Compiled defaults — safe, inert config used offline / pre-auth / on error.
  const RemoteConfig.defaults()
    : version = 0,
      minSupportedBuild = 0,
      latestBuild = 0,
      updateMessage = null,
      featureFlags = const {},
      killSwitches = const {},
      cohortProfiles = const {},
      updatedAt = 0;

  /// Config schema/content version (owner-bumped on each publish).
  final int version;

  /// Builds below this are unsupported (feeds the 1R.3 update gate). `0` ⇒ never.
  final int minSupportedBuild;

  /// Newest build available (feeds the soft "update available" nudge).
  final int latestBuild;

  /// Message shown by the update prompt; `null` ⇒ use the default copy.
  final String? updateMessage;

  /// Feature flags, decoded from the `featureFlags` JSON column.
  final Map<String, Object?> featureFlags;

  /// Kill-switches (subsumes the sync kill-switch surface), decoded from JSON.
  final Map<String, Object?> killSwitches;

  /// Per-invite-cohort flag overrides, keyed by cohort id — the "my own
  /// versions" mechanism (same binary, per-cohort flag profile).
  final Map<String, Map<String, Object?>> cohortProfiles;

  /// Epoch millis of the last owner write.
  final int updatedAt;

  /// Build from a raw Appwrite row (`Row.data` or a Realtime payload). The map
  /// columns arrive as JSON strings; ints arrive as ints. Tolerant by design.
  factory RemoteConfig.fromRow(final Map<String, Object?> row) => RemoteConfig(
    version: _asInt(row['version']),
    minSupportedBuild: _asInt(row['minSupportedBuild']),
    latestBuild: _asInt(row['latestBuild']),
    updateMessage: row['updateMessage'] as String?,
    featureFlags: _decodeMap(row['featureFlags']),
    killSwitches: _decodeMap(row['killSwitches']),
    cohortProfiles: _decodeCohorts(row['cohortProfiles']),
    updatedAt: _asInt(row['updatedAt']),
  );

  /// Rehydrate from the local cache written by [toCache] (maps already parsed).
  factory RemoteConfig.fromCache(final Map<String, Object?> json) =>
      RemoteConfig.fromRow(json);

  /// Serialize for the SharedPreferences cache — maps re-encoded to JSON strings
  /// so the round-trip is symmetric with [RemoteConfig.fromRow].
  Map<String, Object?> toCache() => {
    'version': version,
    'minSupportedBuild': minSupportedBuild,
    'latestBuild': latestBuild,
    'updateMessage': updateMessage,
    'featureFlags': jsonEncode(featureFlags),
    'killSwitches': jsonEncode(killSwitches),
    'cohortProfiles': jsonEncode(cohortProfiles),
    'updatedAt': updatedAt,
  };

  /// Resolve a feature flag as a bool. When [cohort] is given and that cohort
  /// profile overrides [key], the cohort value wins over the base flag.
  bool flag(
    final String key, {
    final String? cohort,
    final bool orElse = false,
  }) {
    final override = cohort == null ? null : cohortProfiles[cohort]?[key];
    return _asBool(override ?? featureFlags[key], orElse);
  }

  /// Whether kill-switch [key] is engaged.
  bool isKilled(final String key) => _asBool(killSwitches[key], false);

  static int _asInt(final Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  static bool _asBool(final Object? v, final bool orElse) => switch (v) {
    final bool b => b,
    final num n => n != 0,
    'true' => true,
    'false' => false,
    _ => orElse,
  };

  /// Decode a JSON-string (or already-a-map) column into a string-keyed map.
  static Map<String, Object?> _decodeMap(final Object? v) {
    if (v is Map) return v.map((final k, final val) => MapEntry('$k', val));
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) {
          return decoded.map((final k, final val) => MapEntry('$k', val));
        }
      } on FormatException {
        // Corrupt remote value — degrade to empty, never brick the launch.
      }
    }
    return const {};
  }

  static Map<String, Map<String, Object?>> _decodeCohorts(final Object? v) =>
      _decodeMap(v).map(
        (final cohort, final profile) => MapEntry(cohort, _decodeMap(profile)),
      );

  /// Canonical serialized form — value identity for two snapshots. Configs are
  /// tiny, so encoding on demand is cheaper than caching (keeps `const` ctors).
  String get _signature => jsonEncode(toCache());

  @override
  bool operator ==(final Object other) =>
      other is RemoteConfig && other._signature == _signature;

  @override
  int get hashCode => _signature.hashCode;

  @override
  String toString() =>
      'RemoteConfig(v$version, minBuild=$minSupportedBuild, '
      'flags=${featureFlags.length}, kills=${killSwitches.length})';
}

/// The single seam between the config service and a concrete Appwrite client.
///
/// Mirrors the `ConvexTransport` idiom (Decision 6): only the Appwrite
/// implementation touches an SDK, so the client is swappable and the service
/// stays unit-testable against a fake source with no live backend.
abstract interface class RemoteConfigSource {
  /// Fetch the current config row once. Throws on transport / auth failure
  /// (a session-less client gets 401 — treated as "offline" by the service).
  Future<Map<String, Object?>> fetch();

  /// Live updates to the config row. The stream errors when the socket drops.
  Stream<Map<String, Object?>> subscribe();
}
