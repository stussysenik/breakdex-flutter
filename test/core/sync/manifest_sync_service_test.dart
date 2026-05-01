import 'package:breakdex/core/sync/cloud_provider.dart';
import 'package:breakdex/core/sync/manifest_serializer.dart';
import 'package:breakdex/core/sync/manifest_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManifestSyncService', () {
    test('skips serialization when no providers are authenticated', () async {
      final serializer = _FakeManifestSerializer();
      final provider = _FakeCloudProvider(isAuthenticatedValue: false);
      final service = ManifestSyncService(
        serializer: serializer,
        getProviders: () => [provider],
      );

      service.onMetadataChanged();
      await Future<void>.delayed(const Duration(seconds: 6));

      expect(provider.authChecks, 1);
      expect(provider.uploadCalls, 0);
      expect(serializer.serializeCalls, 0);

      service.dispose();
    });

    test(
      'suppresses temporarily unavailable providers during cooldown',
      () async {
        final serializer = _FakeManifestSerializer();
        final provider = _FakeCloudProvider(
          isAuthenticatedValue: true,
          uploadError: const CloudProviderUnavailableException(
            provider: 'iCloud Drive',
            reason: 'iCloud container not available',
          ),
        );
        final service = ManifestSyncService(
          serializer: serializer,
          getProviders: () => [provider],
        );

        service.onMetadataChanged();
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(serializer.serializeCalls, 1);
        expect(provider.authChecks, 1);
        expect(provider.uploadCalls, 1);

        service.onMetadataChanged();
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(serializer.serializeCalls, 1);
        expect(provider.authChecks, 1);
        expect(provider.uploadCalls, 1);

        service.dispose();
      },
    );
  });
}

class _FakeManifestSerializer implements ManifestSerializer {
  int serializeCalls = 0;

  @override
  Future<String> serialize() async {
    serializeCalls += 1;
    return '{"moves":[]}';
  }
}

class _FakeCloudProvider extends CloudProvider {
  _FakeCloudProvider({required this.isAuthenticatedValue, this.uploadError});

  final bool isAuthenticatedValue;
  final Object? uploadError;
  int authChecks = 0;
  int uploadCalls = 0;

  @override
  Set<CloudProviderCapability> get capabilities => const {};

  @override
  String get displayName => 'iCloud Drive';

  @override
  Future<bool> authenticate() async => isAuthenticatedValue;

  @override
  Future<void> deauthenticate() async {}

  @override
  Future<void> delete({required String remotePath}) async {}

  @override
  Future<void> download({
    required String remotePath,
    required String localPath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {}

  @override
  Future<bool> get isAuthenticated async {
    authChecks += 1;
    return isAuthenticatedValue;
  }

  @override
  Future<List<RemoteAsset>> list({required String directory}) async => const [];

  @override
  String get providerType => 'icloud';

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async => null;

  @override
  Future<RemoteAsset> upload({
    required String localPath,
    required String remotePath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {
    uploadCalls += 1;
    if (uploadError != null) throw uploadError!;
    return RemoteAsset(remotePath: remotePath, sizeBytes: 0);
  }

  @override
  Future<bool> verify({
    required String remotePath,
    String? expectedHash,
    int? expectedSize,
  }) async {
    return true;
  }
}
