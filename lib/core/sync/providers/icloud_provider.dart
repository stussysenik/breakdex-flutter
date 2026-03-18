import 'package:flutter/services.dart';

import '../cloud_provider.dart';

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
    required String localPath,
    required String remotePath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('upload', {
      'localPath': localPath,
      'remotePath': remotePath,
    });

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
    required String remotePath,
    required String localPath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  }) async {
    await _channel.invokeMethod<void>('download', {
      'remotePath': remotePath,
      'localPath': localPath,
    });
  }

  @override
  Future<bool> verify({
    required String remotePath,
    String? expectedHash,
    int? expectedSize,
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
  Future<List<RemoteAsset>> list({required String directory}) async {
    final result =
        await _channel.invokeListMethod<Map<String, dynamic>>('list', {
      'directory': directory,
    });
    if (result == null) return [];

    return result.map((map) {
      return RemoteAsset(
        remotePath: map['path'] as String,
        sizeBytes: map['size'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> delete({required String remotePath}) async {
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
