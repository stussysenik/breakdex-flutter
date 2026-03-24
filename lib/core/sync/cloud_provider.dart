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
abstract class CloudProvider {
  /// Machine-readable provider type: 'icloud', 'gdrive', 's3'.
  String get providerType;

  /// Human-readable name for UI display.
  String get displayName;

  /// What this provider supports.
  Set<CloudProviderCapability> get capabilities;

  /// Authenticate with the provider (OAuth flow, credential check, etc.).
  ///
  /// Returns true if authentication succeeded. May show platform-specific
  /// UI (e.g. Google Sign-In sheet, iCloud entitlement check).
  Future<bool> authenticate();

  /// Revoke authentication and clear stored credentials.
  Future<void> deauthenticate();

  /// Whether the provider is currently authenticated.
  Future<bool> get isAuthenticated;

  /// Upload a local file to the provider.
  ///
  /// Returns a [RemoteAsset] with the remote path, etag, and size.
  /// Supports progress callbacks and cancellation for large files.
  Future<RemoteAsset> upload({
    required String localPath,
    required String remotePath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  });

  /// Download a remote file to a local path.
  ///
  /// Supports progress callbacks and cancellation. For providers with
  /// [CloudProviderCapability.rangeDownload], partial downloads can
  /// resume after interruption.
  Future<void> download({
    required String remotePath,
    required String localPath,
    TransferProgress? onProgress,
    CancellationToken? cancel,
  });

  /// Verify that a remote file exists and optionally matches expected
  /// hash/size. Returns true if the remote copy is valid.
  Future<bool> verify({
    required String remotePath,
    String? expectedHash,
    int? expectedSize,
  });

  /// List all assets in a remote directory.
  Future<List<RemoteAsset>> list({required String directory});

  /// Delete a remote file.
  Future<void> delete({required String remotePath});

  /// Query storage quota. Returns null if quota is unavailable.
  Future<({int totalBytes, int usedBytes})?> quota();
}
