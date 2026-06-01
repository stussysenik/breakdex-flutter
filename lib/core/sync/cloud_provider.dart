/// Capabilities that a cloud provider may support.
enum CloudProviderCapability {
  /// Supports resumable uploads for large files.
  resumableUpload,

  /// Supports Range-header downloads for streaming playback.
  rangeDownload,

  /// Provider reports storage quota.
  quota,

  /// Supports server-side hash verification.
  serverSideHash,
}

/// Progress callback for upload/download operations.
typedef TransferProgress = void Function(int bytesTransferred, int totalBytes);

/// Token that can be checked to cancel an in-progress transfer.
class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Provider-agnostic description of an asset in object storage.
class AssetDescriptor {
  const AssetDescriptor({
    required this.assetId,
    required this.objectKey,
    required this.mimeType,
    this.sizeBytes,
  });

  final String assetId;
  final String objectKey;
  final String mimeType;
  final int? sizeBytes;
}

/// Metadata about a remote asset on a cloud provider.
class RemoteAsset {
  final String remotePath;
  final String? etag;
  final int sizeBytes;
  final DateTime? modifiedAt;

  const RemoteAsset({
    required this.remotePath,
    this.etag,
    required this.sizeBytes,
    this.modifiedAt,
  });
}

/// Thrown when a cloud provider's backing service is unavailable
/// (e.g. iCloud container missing, not signed in). Caught by the sync engine
/// to log a one-liner instead of a full stack trace.
class CloudProviderUnavailableException implements Exception {
  final String provider;
  final String reason;

  const CloudProviderUnavailableException({
    required this.provider,
    required this.reason,
  });

  @override
  String toString() => '$provider unavailable: $reason';
}

/// Storage contract used by the mobile sync engine.
///
/// This interface owns blob movement and verification only. Delivery concerns
/// such as signed URLs or media transforms live behind [MediaDeliveryProvider].
abstract interface class AssetStorageProvider {
  String get providerType;
  String get displayName;
  Set<CloudProviderCapability> get capabilities;
  Future<bool> authenticate();
  Future<void> deauthenticate();
  Future<bool> get isAuthenticated;
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  });
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  });
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  });
  Future<List<RemoteAsset>> list({required final String directory});
  Future<void> delete({required final String remotePath});
  Future<({int totalBytes, int usedBytes})?> quota();
}

/// Resolved media access for web or backend-driven playback flows.
class MediaAccessGrant {
  const MediaAccessGrant({
    required this.uri,
    this.headers = const {},
    this.expiresAt,
  });

  final Uri uri;
  final Map<String, String> headers;
  final DateTime? expiresAt;
}

/// Delivery contract for playback and previews.
///
/// The current mobile app does not require this yet, but future Phoenix/web
/// slices can use it for signed URLs and transformation-aware playback.
abstract interface class MediaDeliveryProvider {
  String get providerType;

  Future<MediaAccessGrant> resolveOriginal(final AssetDescriptor asset);

  Future<MediaAccessGrant?> resolvePreview(
    final AssetDescriptor asset, {
    final String? preset,
  });
}

/// Abstract interface for cloud storage providers.
///
/// Each provider (iCloud, Google Drive, S3-compatible) implements this
/// interface. The sync engine treats all providers uniformly, dispatching
/// uploads, downloads, and verifications through this contract.
///
/// **Lifecycle**: authenticate → upload/download/verify → deauthenticate
///
/// Providers handle their own network optimization (chunking, retries)
/// internally. The sync engine controls *when* to transfer based on
/// [NetworkPolicy]; the provider controls *how*.
abstract class CloudProvider implements AssetStorageProvider {
  /// Machine-readable provider type: 'icloud', 'gdrive', 's3'.
  @override
  String get providerType;

  /// Human-readable name for UI display.
  @override
  String get displayName;

  /// What this provider supports.
  @override
  Set<CloudProviderCapability> get capabilities;

  /// Authenticate with the provider (OAuth flow, credential check, etc.).
  ///
  /// Returns true if authentication succeeded. May show platform-specific
  /// UI (e.g. Google Sign-In sheet, iCloud entitlement check).
  @override
  Future<bool> authenticate();

  /// Revoke authentication and clear stored credentials.
  @override
  Future<void> deauthenticate();

  /// Whether the provider is currently authenticated.
  @override
  Future<bool> get isAuthenticated;

  /// Upload a local file to the provider.
  ///
  /// Returns a [RemoteAsset] with the remote path, etag, and size.
  /// Supports progress callbacks and cancellation for large files.
  @override
  Future<RemoteAsset> upload({
    required final String localPath,
    required final String remotePath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  });

  /// Download a remote file to a local path.
  ///
  /// Supports progress callbacks and cancellation. For providers with
  /// [CloudProviderCapability.rangeDownload], partial downloads can
  /// resume after interruption.
  @override
  Future<void> download({
    required final String remotePath,
    required final String localPath,
    final TransferProgress? onProgress,
    final CancellationToken? cancel,
  });

  /// Verify that a remote file exists and optionally matches expected
  /// hash/size. Returns true if the remote copy is valid.
  @override
  Future<bool> verify({
    required final String remotePath,
    final String? expectedHash,
    final int? expectedSize,
  });

  /// List all assets in a remote directory.
  @override
  Future<List<RemoteAsset>> list({required final String directory});

  /// Delete a remote file.
  @override
  Future<void> delete({required final String remotePath});

  /// Query storage quota. Returns null if quota is unavailable.
  @override
  Future<({int totalBytes, int usedBytes})?> quota();
}
