import 'dart:async';
import 'dart:io';

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

  /// Debounce duration — no upload fires until this much silence has passed.
  static const _debounceDuration = Duration(seconds: 5);

  ManifestSyncService({
    required ManifestSerializer serializer,
    required List<CloudProvider> Function() getProviders,
  })  : _serializer = serializer,
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

  Future<void> _uploadManifest() async {
    final providers = _getProviders();
    if (providers.isEmpty) return;

    _uploading = true;
    try {
      // Serialize the full library
      final json = await _serializer.serialize();
      debugPrint('[ManifestSync] Serialized manifest (${json.length} bytes)');

      // Write to temp file
      final tempFile = File(p.join(Directory.systemTemp.path, 'manifest.json'));
      await tempFile.writeAsString(json);

      // Upload to each enabled provider
      for (final provider in providers) {
        try {
          final isAuth = await provider.isAuthenticated;
          if (!isAuth) continue;

          await provider.upload(
            localPath: tempFile.path,
            remotePath: 'breakdex/manifest.json',
          );
          debugPrint(
            '[ManifestSync] Uploaded to ${provider.displayName}',
          );
        } catch (e) {
          debugPrint(
            '[ManifestSync] Upload to ${provider.displayName} failed: $e',
          );
        }
      }

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('[ManifestSync] Serialization failed: $e');
    } finally {
      _uploading = false;

      // If something changed while we were uploading, do another round
      if (_pendingWhileUploading) {
        _pendingWhileUploading = false;
        onMetadataChanged();
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
