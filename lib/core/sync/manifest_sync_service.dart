import 'dart:async';
import '../platform/io.dart';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'cloud_provider.dart';
import 'manifest_serializer.dart';

/// Debounced manifest uploader — after any metadata change, waits for 5 seconds
/// of inactivity then serializes the full library and uploads `manifest.json`
/// to each enabled cloud provider.
///
/// This ensures the web viewer always has a recent snapshot without thrashing
/// during bulk operations (e.g., reviewing 20 cards in a row).
class ManifestSyncService {
  final ManifestSerializer _serializer;
  final List<CloudProvider> Function() _getProviders;

  Timer? _debounceTimer;
  bool _uploading = false;
  bool _pendingWhileUploading = false;
  final Map<String, DateTime> _providerCooldownUntil = {};

  /// Debounce duration — no upload fires until this much silence has passed.
  static const _debounceDuration = Duration(seconds: 5);
  static const _providerUnavailableCooldown = Duration(seconds: 30);

  ManifestSyncService({
    required final ManifestSerializer serializer,
    required final List<CloudProvider> Function() getProviders,
  }) : _serializer = serializer,
       _getProviders = getProviders;

  /// Call this whenever any metadata changes (move/combo/review/fsrs/deck).
  ///
  /// Resets the debounce timer. The actual upload only fires after
  /// [_debounceDuration] of inactivity.
  void onMetadataChanged() {
    _debounceTimer?.cancel();

    if (_uploading) {
      // An upload is in progress — flag that we need another once it completes
      _pendingWhileUploading = true;
      return;
    }

    _debounceTimer = Timer(_debounceDuration, _uploadManifest);
  }

  /// Force an immediate manifest upload, bypassing the debounce. Used by the
  /// manual "Re-upload library now" control so the web mirror can be refreshed
  /// on demand (e.g. to verify Drive writes or push a corrected snapshot)
  /// without waiting for the next metadata edit. Respects the in-flight guard:
  /// if an upload is already running, this coalesces into the pending round.
  /// Returns the number of providers the manifest was successfully uploaded to
  /// (0 if none are connected/available, or an upload is already in flight and
  /// this call coalesced into it).
  Future<int> syncNow() async {
    _debounceTimer?.cancel();
    if (_uploading) {
      _pendingWhileUploading = true;
      return 0;
    }
    return _uploadManifest();
  }

  Future<int> _uploadManifest() async {
    _uploading = true;
    var uploaded = 0;
    try {
      final providers = await _availableProviders();
      if (providers.isEmpty) return 0;

      // Serialize the full library only when some provider can accept it.
      final json = await _serializer.serialize();
      debugPrint('[ManifestSync] Serialized manifest (${json.length} bytes)');

      final tempDir = await Directory.systemTemp.createTemp(
        'breakdex_manifest_',
      );
      try {
        final tempFile = File(p.join(tempDir.path, 'manifest.json'));
        await tempFile.writeAsString(json);

        // Upload to each enabled provider
        for (final provider in providers) {
          try {
            await provider.upload(
              localPath: tempFile.path,
              remotePath: 'breakdex/manifest.json',
            );
            debugPrint('[ManifestSync] Uploaded to ${provider.displayName}');
            uploaded++;
            _providerCooldownUntil.remove(provider.providerType);
          } on CloudProviderUnavailableException catch (e) {
            _providerCooldownUntil[provider.providerType] = DateTime.now().add(
              _providerUnavailableCooldown,
            );
            debugPrint('[ManifestSync] ${e.provider} unavailable: ${e.reason}');
          } on Object catch (e) {
            debugPrint(
              '[ManifestSync] Upload to ${provider.displayName} failed: $e',
            );
          }
        }
      } finally {
        try {
          await tempDir.delete(recursive: true);
        } on Object catch (_) {}
      }
    } on Object catch (e) {
      debugPrint('[ManifestSync] Serialization failed: $e');
    } finally {
      _uploading = false;

      // If something changed while we were uploading, do another round
      if (_pendingWhileUploading) {
        _pendingWhileUploading = false;
        onMetadataChanged();
      }
    }
    return uploaded;
  }

  Future<List<CloudProvider>> _availableProviders() async {
    final now = DateTime.now();
    final available = <CloudProvider>[];

    for (final provider in _getProviders()) {
      final cooldownUntil = _providerCooldownUntil[provider.providerType];
      if (cooldownUntil != null && cooldownUntil.isAfter(now)) {
        continue;
      }

      try {
        if (await provider.isAuthenticated) {
          available.add(provider);
          _providerCooldownUntil.remove(provider.providerType);
        }
      } on CloudProviderUnavailableException catch (e) {
        _providerCooldownUntil[provider.providerType] = now.add(
          _providerUnavailableCooldown,
        );
        debugPrint('[ManifestSync] ${e.provider} unavailable: ${e.reason}');
      } on Object catch (e) {
        debugPrint(
          '[ManifestSync] Auth check for ${provider.displayName} failed: $e',
        );
      }
    }

    return available;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
