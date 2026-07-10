import 'dart:convert';

import 'package:breakdex/core/config/remote_config.dart';
import 'package:breakdex/core/config/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a raw Appwrite `appConfig` row (map columns as JSON strings, as the
/// live TablesDB stores them).
Map<String, Object?> _row({
  final int version = 1,
  final int minSupportedBuild = 0,
  final int latestBuild = 0,
  final String? updateMessage,
  final Map<String, Object?> featureFlags = const {},
  final Map<String, Object?> killSwitches = const {},
  final Map<String, Map<String, Object?>> cohortProfiles = const {},
  final int updatedAt = 1000,
}) => {
  r'$id': 'current',
  'version': version,
  'minSupportedBuild': minSupportedBuild,
  'latestBuild': latestBuild,
  'updateMessage': updateMessage,
  'featureFlags': jsonEncode(featureFlags),
  'killSwitches': jsonEncode(killSwitches),
  'cohortProfiles': jsonEncode(cohortProfiles),
  'updatedAt': updatedAt,
};

/// In-memory [RemoteConfigSource] — lets the service be proven with no backend.
class _FakeSource implements RemoteConfigSource {
  _FakeSource({this.fetchResult, this.fetchError, this.updates});

  Map<String, Object?>? fetchResult;
  Object? fetchError;
  Stream<Map<String, Object?>>? updates;
  int fetchCalls = 0;

  @override
  Future<Map<String, Object?>> fetch() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return fetchResult ?? (throw StateError('fetchResult unset'));
  }

  @override
  Stream<Map<String, Object?>> subscribe() => updates ?? const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteConfig model', () {
    test('fromRow decodes JSON string columns and scalar fields', () {
      final cfg = RemoteConfig.fromRow(
        _row(
          version: 3,
          minSupportedBuild: 42,
          latestBuild: 50,
          updateMessage: 'Please update',
          featureFlags: {'newReview': true, 'count': 2},
          killSwitches: {'sync': true},
          cohortProfiles: {
            'beta': {'newReview': false},
          },
        ),
      );

      expect(cfg.version, 3);
      expect(cfg.minSupportedBuild, 42);
      expect(cfg.latestBuild, 50);
      expect(cfg.updateMessage, 'Please update');
      expect(cfg.featureFlags['newReview'], true);
      expect(cfg.isKilled('sync'), isTrue);
      expect(cfg.cohortProfiles['beta']!['newReview'], false);
    });

    test('flag() coerces to bool and cohort override wins over base', () {
      final cfg = RemoteConfig.fromRow(
        _row(
          featureFlags: {'a': true, 'b': false},
          cohortProfiles: {
            'beta': {'b': true},
          },
        ),
      );

      expect(cfg.flag('a'), isTrue);
      expect(cfg.flag('b'), isFalse);
      expect(cfg.flag('missing'), isFalse);
      expect(cfg.flag('missing', orElse: true), isTrue);
      // cohort profile overrides the base flag
      expect(cfg.flag('b', cohort: 'beta'), isTrue);
      // unknown cohort falls back to the base flag
      expect(cfg.flag('b', cohort: 'ghost'), isFalse);
    });

    test('malformed JSON column degrades to empty map, never throws', () {
      final cfg = RemoteConfig.fromRow({
        'version': 1,
        'minSupportedBuild': 0,
        'latestBuild': 0,
        'updateMessage': null,
        'featureFlags': '{not json',
        'killSwitches': '{}',
        'cohortProfiles': '{}',
        'updatedAt': 1,
      });

      expect(cfg.featureFlags, isEmpty);
      expect(cfg.flag('anything'), isFalse);
    });

    test('defaults are inert: gate off, no flags', () {
      const cfg = RemoteConfig.defaults();
      expect(cfg.minSupportedBuild, 0);
      expect(cfg.featureFlags, isEmpty);
      expect(cfg.killSwitches, isEmpty);
      expect(cfg.flag('any'), isFalse);
      expect(cfg.isKilled('any'), isFalse);
    });

    test('toCache/fromCache round-trips to an equal value', () {
      final cfg = RemoteConfig.fromRow(
        _row(
          featureFlags: {'x': true},
          cohortProfiles: {
            'beta': {'x': false},
          },
        ),
      );
      final restored = RemoteConfig.fromCache(cfg.toCache());
      expect(restored, equals(cfg));
      expect(restored.hashCode, cfg.hashCode);
    });
  });

  group('RemoteConfigService fallback ladder', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

    test(
      'cold + fetch success: emits defaults then the live row, and caches',
      () async {
        final source = _FakeSource(
          fetchResult: _row(version: 7, featureFlags: {'live': true}),
        );
        final service = RemoteConfigService(
          source: source,
          prefs: await prefs(),
        );

        final emitted = await service.watch().toList();

        expect(emitted.first, const RemoteConfig.defaults());
        expect(emitted.last.version, 7);
        expect(emitted.last.flag('live'), isTrue);
        // persisted → the next synchronous read is the live value, not defaults
        expect(service.current.version, 7);
      },
    );

    test('offline / 401: fetch throws → stays on defaults, no crash', () async {
      final source = _FakeSource(fetchError: StateError('401 no session'));
      final service = RemoteConfigService(source: source, prefs: await prefs());

      final emitted = await service.watch().toList();

      expect(emitted, [const RemoteConfig.defaults()]);
      expect(service.current, const RemoteConfig.defaults());
    });

    test('warm cache: first emit is the cached row, not defaults', () async {
      final store = await prefs();
      // seed cache via one successful run
      final seeding = RemoteConfigService(
        source: _FakeSource(fetchResult: _row(version: 5)),
        prefs: store,
      );
      await seeding.watch().toList();

      // new service, fetch now fails → should still surface the cached v5 first
      final service = RemoteConfigService(
        source: _FakeSource(fetchError: StateError('offline')),
        prefs: store,
      );
      final emitted = await service.watch().toList();

      expect(emitted.first.version, 5);
    });

    test('realtime update reaches the stream and is cached', () async {
      final source = _FakeSource(
        fetchResult: _row(version: 1, featureFlags: {'f': false}),
        updates: Stream.fromIterable([
          _row(version: 2, featureFlags: {'f': true}),
        ]),
      );
      final service = RemoteConfigService(source: source, prefs: await prefs());

      final emitted = await service.watch().toList();

      expect(emitted.map((final c) => c.version), containsAllInOrder([1, 2]));
      expect(emitted.last.flag('f'), isTrue);
      expect(service.current.version, 2);
    });
  });
}
