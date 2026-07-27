import 'package:flutter/services.dart';

import 'package:breakdex/core/sync/cloud_provider.dart';

/// iCloud Drive adapter using native Swift via MethodChannel.
///
/// Delegates all file operations to [iCloudSyncPlugin.swift] which uses
/// `NSFileCoordinator` and `FileManager.url(forUbiquityContainerIdentifier:)`
/// for safe cloud file access. iCloud handles network optimization natively
/// (WiFi vs cellular is managed by iOS) — we just coordinate file placement.
///
/// **Requirements**:
/// - iCloud entitlement in Runner.entitlements
/// - iCloud container configured in Xcode Signing & Capabilities
/// - iCloudSyncPlugin registered in CapabilityRegistry
class ICloudProvider extends CloudProvider {
  static const _channel = MethodChannel('com.breakdex/icloud_sync');

  @override
  String get providerType => 'icloud';

  @override
  String get displayName => 'iCloud Drive';

  @override
  Set<CloudProviderCapability> get capabilities => {
        CloudProviderCapability.quota,
      };

  @override
  Future<bool> authenticate() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkAvailability');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> deauthenticate() async {
    // iCloud auth is managed by iOS — no explicit deauth needed.
  }

  @override
  Future<bool> get isAuthenticated async {
    try {
      return await _channel.invokeMethod<bool>('checkAvailability') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    final Map<String, dynamic>? result;
    try {
      result = await _channel.invokeMapMethod<String, dynamic>('upload', {
        'localPath': localPath,
        'remotePath': remotePath,
      });
    } on PlatformException catch (e) {
      if (e.code == 'NO_ICLOUD') {
        // Container unavailable (simulator, signed-out, or entitlement issue).
        // Throw a lightweight error so ManifestSync logs a one-liner, not a
        // full stack trace.
        throw CloudProviderUnavailableException(
          provider: displayName,
          reason: 'iCloud container not available',
        );
      }
      rethrow;
    }

    if (result == null) {
      throw PlatformException(
        code: 'UPLOAD_FAILED',
        message: 'iCloud upload returned null',
      );
    }

    return RemoteAsset(
      remotePath: result['remotePath'] as String? ?? remotePath,
      sizeBytes: result['sizeBytes'] as int? ?? 0,
    );
  }

  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  }) async {
    await _channel.invokeMethod<void>('download', {
      'remotePath': remotePath,
      'localPath': localPath,
    });
  }

  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  }) async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('verify', {
        'remotePath': remotePath,
        'expectedSize': expectedSize,
      });
      return result?['exists'] as bool? ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<RemoteAsset>> list({required final String directory}) async {
    final result =
        await _channel.invokeListMethod<Map<String, dynamic>>('list', {
      'directory': directory,
    });
    if (result == null) return [];

    return result.map((final map) {
      return RemoteAsset(
        remotePath: map['path'] as String,
        sizeBytes: map['size'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> delete({required final String remotePath}) async {
    await _channel.invokeMethod<void>('delete', {
      'remotePath': remotePath,
    });
  }

  @override
  Future<({int totalBytes, int usedBytes})?> quota() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('quota');
      if (result == null) return null;
      return (
        totalBytes: result['totalBytes'] as int? ?? 0,
        usedBytes: result['usedBytes'] as int? ?? 0,
      );
    } on PlatformException {
      return null;
    }
  }
}
