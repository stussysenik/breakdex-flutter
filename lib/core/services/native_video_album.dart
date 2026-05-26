import 'native_bridge.dart';

enum PhotoLibraryAccessStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  limited,
  unknown;

  bool get allowsReadAccess =>
      this == PhotoLibraryAccessStatus.authorized ||
      this == PhotoLibraryAccessStatus.limited;

  static PhotoLibraryAccessStatus fromPlatformValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'not_determined':
        return PhotoLibraryAccessStatus.notDetermined;
      case 'restricted':
        return PhotoLibraryAccessStatus.restricted;
      case 'denied':
        return PhotoLibraryAccessStatus.denied;
      case 'authorized':
        return PhotoLibraryAccessStatus.authorized;
      case 'limited':
        return PhotoLibraryAccessStatus.limited;
      default:
        return PhotoLibraryAccessStatus.unknown;
    }
  }
}

class ManagedAlbumCopy {
  const ManagedAlbumCopy({
    required this.assetLocalIdentifier,
    required this.filename,
    required this.albumName,
  });

  final String assetLocalIdentifier;
  final String filename;
  final String albumName;

  static ManagedAlbumCopy? fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return null;
    final assetLocalIdentifier = payload['assetLocalIdentifier'] as String?;
    final filename = payload['filename'] as String?;
    final albumName = payload['albumName'] as String?;
    if (assetLocalIdentifier == null ||
        assetLocalIdentifier.trim().isEmpty ||
        filename == null ||
        filename.trim().isEmpty ||
        albumName == null ||
        albumName.trim().isEmpty) {
      return null;
    }
    return ManagedAlbumCopy(
      assetLocalIdentifier: assetLocalIdentifier.trim(),
      filename: filename.trim(),
      albumName: albumName.trim(),
    );
  }
}

class ManagedAssetLookupResult {
  const ManagedAssetLookupResult({
    required this.accessStatus,
    required this.missingAssetLocalIdentifiers,
  });

  final PhotoLibraryAccessStatus accessStatus;
  final List<String> missingAssetLocalIdentifiers;

  factory ManagedAssetLookupResult.empty({
    PhotoLibraryAccessStatus accessStatus = PhotoLibraryAccessStatus.unknown,
  }) {
    return ManagedAssetLookupResult(
      accessStatus: accessStatus,
      missingAssetLocalIdentifiers: const [],
    );
  }

  static ManagedAssetLookupResult fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return ManagedAssetLookupResult.empty();
    final missing =
        (payload['missingAssetLocalIdentifiers'] as List?)
            ?.whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList() ??
        const <String>[];
    return ManagedAssetLookupResult(
      accessStatus: PhotoLibraryAccessStatus.fromPlatformValue(
        payload['accessStatus'] as String?,
      ),
      missingAssetLocalIdentifiers: missing,
    );
  }
}

class ManagedAssetReference {
  const ManagedAssetReference({
    required this.moveId,
    required this.assetLocalIdentifier,
    required this.albumName,
  });

  final String moveId;
  final String assetLocalIdentifier;
  final String albumName;

  Map<String, dynamic> toMap() => {
    'moveId': moveId,
    'assetLocalIdentifier': assetLocalIdentifier,
    'albumName': albumName,
  };
}

enum ManagedAssetReconcileEventType {
  assetDeletedFromLibrary,
  assetRemovedFromManagedAlbum;

  static ManagedAssetReconcileEventType? fromPlatformValue(String? value) {
    switch (value?.trim()) {
      case 'assetDeletedFromLibrary':
        return ManagedAssetReconcileEventType.assetDeletedFromLibrary;
      case 'assetRemovedFromManagedAlbum':
        return ManagedAssetReconcileEventType.assetRemovedFromManagedAlbum;
      default:
        return null;
    }
  }
}

class ManagedAssetReconcileEvent {
  const ManagedAssetReconcileEvent({
    required this.type,
    required this.assetLocalIdentifier,
    required this.moveId,
    required this.albumName,
  });

  final ManagedAssetReconcileEventType type;
  final String assetLocalIdentifier;
  final String moveId;
  final String albumName;

  static ManagedAssetReconcileEvent? fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return null;
    final type = ManagedAssetReconcileEventType.fromPlatformValue(
      payload['type'] as String?,
    );
    final assetLocalIdentifier = payload['assetLocalIdentifier'] as String?;
    final moveId = payload['moveId'] as String?;
    final albumName = payload['albumName'] as String?;
    if (type == null ||
        assetLocalIdentifier == null ||
        assetLocalIdentifier.trim().isEmpty ||
        moveId == null ||
        moveId.trim().isEmpty ||
        albumName == null ||
        albumName.trim().isEmpty) {
      return null;
    }
    return ManagedAssetReconcileEvent(
      type: type,
      assetLocalIdentifier: assetLocalIdentifier.trim(),
      moveId: moveId.trim(),
      albumName: albumName.trim(),
    );
  }
}

class ManagedAssetReconcileResult {
  const ManagedAssetReconcileResult({
    required this.accessStatus,
    required this.events,
  });

  final PhotoLibraryAccessStatus accessStatus;
  final List<ManagedAssetReconcileEvent> events;

  factory ManagedAssetReconcileResult.empty({
    PhotoLibraryAccessStatus accessStatus = PhotoLibraryAccessStatus.unknown,
  }) {
    return ManagedAssetReconcileResult(
      accessStatus: accessStatus,
      events: const [],
    );
  }

  static ManagedAssetReconcileResult fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return ManagedAssetReconcileResult.empty();
    final events =
        (payload['events'] as List?)
            ?.whereType<Map<dynamic, dynamic>>()
            .map(ManagedAssetReconcileEvent.fromMap)
            .whereType<ManagedAssetReconcileEvent>()
            .toList() ??
        const <ManagedAssetReconcileEvent>[];
    return ManagedAssetReconcileResult(
      accessStatus: PhotoLibraryAccessStatus.fromPlatformValue(
        payload['accessStatus'] as String?,
      ),
      events: events,
    );
  }
}

class ManagedAssetRestoreResult {
  const ManagedAssetRestoreResult({
    required this.localPath,
    required this.originalFileName,
  });

  final String localPath;
  final String originalFileName;

  static ManagedAssetRestoreResult? fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return null;
    final localPath = payload['localPath'] as String?;
    final originalFileName = payload['originalFileName'] as String?;
    if (localPath == null ||
        localPath.trim().isEmpty ||
        originalFileName == null ||
        originalFileName.trim().isEmpty) {
      return null;
    }
    return ManagedAssetRestoreResult(
      localPath: localPath.trim(),
      originalFileName: originalFileName.trim(),
    );
  }
}

class RecoverableManagedAsset {
  const RecoverableManagedAsset({
    required this.assetLocalIdentifier,
    required this.filename,
    required this.albumName,
  });

  final String assetLocalIdentifier;
  final String filename;
  final String albumName;

  static RecoverableManagedAsset? fromMap(Map<dynamic, dynamic>? payload) {
    if (payload == null) return null;
    final assetLocalIdentifier = payload['assetLocalIdentifier'] as String?;
    final filename = payload['filename'] as String?;
    final albumName = payload['albumName'] as String?;
    if (assetLocalIdentifier == null ||
        assetLocalIdentifier.trim().isEmpty ||
        filename == null ||
        filename.trim().isEmpty ||
        albumName == null ||
        albumName.trim().isEmpty) {
      return null;
    }
    return RecoverableManagedAsset(
      assetLocalIdentifier: assetLocalIdentifier.trim(),
      filename: filename.trim(),
      albumName: albumName.trim(),
    );
  }
}

class RecoverableManagedAssetDiscoveryResult {
  const RecoverableManagedAssetDiscoveryResult({
    required this.accessStatus,
    required this.assets,
    this.matchingAlbumCount = 0,
    this.videoAssetCount = 0,
    this.skippedMissingFilenameCount = 0,
  });

  final PhotoLibraryAccessStatus accessStatus;
  final List<RecoverableManagedAsset> assets;
  final int matchingAlbumCount;
  final int videoAssetCount;
  final int skippedMissingFilenameCount;

  factory RecoverableManagedAssetDiscoveryResult.empty({
    PhotoLibraryAccessStatus accessStatus = PhotoLibraryAccessStatus.unknown,
  }) {
    return RecoverableManagedAssetDiscoveryResult(
      accessStatus: accessStatus,
      assets: const [],
      matchingAlbumCount: 0,
      videoAssetCount: 0,
      skippedMissingFilenameCount: 0,
    );
  }

  static RecoverableManagedAssetDiscoveryResult fromMap(
    Map<dynamic, dynamic>? payload,
  ) {
    if (payload == null) {
      return RecoverableManagedAssetDiscoveryResult.empty();
    }
    final assets =
        (payload['assets'] as List?)
            ?.whereType<Map<dynamic, dynamic>>()
            .map(RecoverableManagedAsset.fromMap)
            .whereType<RecoverableManagedAsset>()
            .toList() ??
        const <RecoverableManagedAsset>[];
    return RecoverableManagedAssetDiscoveryResult(
      accessStatus: PhotoLibraryAccessStatus.fromPlatformValue(
        payload['accessStatus'] as String?,
      ),
      assets: assets,
      matchingAlbumCount: (payload['matchingAlbumCount'] as num?)?.toInt() ?? 0,
      videoAssetCount: (payload['videoAssetCount'] as num?)?.toInt() ?? 0,
      skippedMissingFilenameCount:
          (payload['skippedMissingFilenameCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Dart bridge to the native `VideoAlbumPlugin` — saves exported video
/// clips into a dated Photos album (e.g. "Breakdex 03-07-2026").
///
/// This uses write-only photo library access (`NSPhotoLibraryAddUsageDescription`),
/// so the user is only prompted once and we never read their existing library.
class NativeVideoAlbum extends NativeBridge {
  NativeVideoAlbum() : super('video_album');

  static final RegExp breakdexAlbumPattern = RegExp(
    r'(break[\s\-_]*dex|break[\s\-_]*ing|break[\s\-_]*in|b[\s\-_]*boy|b[\s\-_]*girl|break[\s\-_]*dance)',
    caseSensitive: false,
  );

  static const List<String> historicalAlbumPatterns = <String>[
    r'break[\s\-_]*(dex|ing|in|dance)',
    r'b[\s\-_]*(boy|girl)',
  ];

  Stream<Map<String, dynamic>> get libraryChangeStream => eventStream;

  static String defaultAlbumName([DateTime? date]) {
    final now = date ?? DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return 'Breakdex $month-$day-${now.year}';
  }

  static String semanticFilename({
    String? assetTitle,
    String? category,
    String? fileExtension,
  }) {
    final parts = [assetTitle, category]
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();
    final base = parts.isEmpty ? 'Breakdex Clip' : parts.join(' - ');
    final sanitized = base
        .split('')
        .map((char) {
          final code = char.codeUnitAt(0);
          final isAlphaNumeric =
              (code >= 48 && code <= 57) ||
              (code >= 65 && code <= 90) ||
              (code >= 97 && code <= 122);
          const allowedExtras = {' ', '-', '_'};
          return isAlphaNumeric || allowedExtras.contains(char) ? char : '-';
        })
        .join()
        .replaceAll(RegExp(r'-{2,}'), '-')
        .trim();
    final trimmed = sanitized.replaceAll(RegExp(r'^[\s\-_]+|[\s\-_]+$'), '');
    final normalizedBase = trimmed.isEmpty ? 'Breakdex Clip' : trimmed;
    final normalizedExt = _normalizeFileExtension(fileExtension);
    return '$normalizedBase.$normalizedExt';
  }

  static String _normalizeFileExtension(String? fileExtension) {
    final trimmed = fileExtension?.trim() ?? '';
    if (trimmed.isEmpty) return 'mp4';
    return trimmed.startsWith('.') ? trimmed.substring(1) : trimmed;
  }

  /// Save a video file to a named Photos album.
  /// Creates the album if it doesn't exist yet.
  Future<ManagedAlbumCopy?> saveToAlbum({
    required String videoPath,
    required String albumName,
    String? assetTitle,
    String? category,
  }) async {
    final normalizedPath = videoPath.trim();
    final normalizedAlbum = albumName.trim();
    if (normalizedPath.isEmpty || normalizedAlbum.isEmpty) {
      return null;
    }

    final args = <String, dynamic>{
      'videoPath': normalizedPath,
      'albumName': normalizedAlbum,
    };
    if (assetTitle != null && assetTitle.trim().isNotEmpty) {
      args['assetTitle'] = assetTitle.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      args['category'] = category.trim();
    }

    final payload = await method.invokeMapMethod<String, dynamic>(
      'saveToAlbum',
      args,
    );
    return ManagedAlbumCopy.fromMap(payload);
  }

  /// Best-effort cleanup for app-managed album copies created by Breakdex.
  ///
  /// The native side scans Breakdex albums for assets whose semantic filename
  /// matches the current title/category pair and deletes those copies.
  Future<void> deleteManagedCopies({
    required String assetTitle,
    String? category,
    String? fileExtension,
    String? assetLocalIdentifier,
  }) async {
    final normalizedTitle = assetTitle.trim();
    if (normalizedTitle.isEmpty) return;

    final args = <String, dynamic>{
      'assetTitle': normalizedTitle,
      'fileExtension': _normalizeFileExtension(fileExtension),
    };
    if (category != null && category.trim().isNotEmpty) {
      args['category'] = category.trim();
    }
    if (assetLocalIdentifier != null &&
        assetLocalIdentifier.trim().isNotEmpty) {
      args['assetLocalIdentifier'] = assetLocalIdentifier.trim();
    }

    await method.invokeMethod<void>('deleteManagedCopies', args);
  }

  Future<PhotoLibraryAccessStatus> requestReadAccess() async {
    final payload = await method.invokeMethod<String>('requestReadAccess');
    return PhotoLibraryAccessStatus.fromPlatformValue(payload);
  }

  Future<void> openSettings() async {
    await method.invokeMethod<void>('openSettings');
  }

  Future<ManagedAssetLookupResult> findMissingManagedAssets(
    List<String> assetLocalIdentifiers,
  ) async {
    final normalized = assetLocalIdentifiers
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) return ManagedAssetLookupResult.empty();

    final payload = await method.invokeMapMethod<String, dynamic>(
      'findMissingManagedAssets',
      {'assetLocalIdentifiers': normalized},
    );
    return ManagedAssetLookupResult.fromMap(payload);
  }

  Future<ManagedAssetReconcileResult> reconcileManagedAssets(
    List<ManagedAssetReference> trackedAssets, {
    String source = 'manual',
  }) async {
    final normalized = trackedAssets
        .where(
          (asset) =>
              asset.moveId.trim().isNotEmpty &&
              asset.assetLocalIdentifier.trim().isNotEmpty &&
              asset.albumName.trim().isNotEmpty,
        )
        .map(
          (asset) => ManagedAssetReference(
            moveId: asset.moveId.trim(),
            assetLocalIdentifier: asset.assetLocalIdentifier.trim(),
            albumName: asset.albumName.trim(),
          ),
        )
        .toList();
    if (normalized.isEmpty) return ManagedAssetReconcileResult.empty();

    final payload = await method
        .invokeMapMethod<String, dynamic>('reconcileManagedAssets', {
          'trackedAssets': normalized.map((asset) => asset.toMap()).toList(),
          'source': source.trim().isEmpty ? 'manual' : source.trim(),
        });
    return ManagedAssetReconcileResult.fromMap(payload);
  }

  Future<ManagedAssetRestoreResult?> restoreManagedAsset(
    String assetLocalIdentifier,
  ) async {
    final normalized = assetLocalIdentifier.trim();
    if (normalized.isEmpty) return null;
    final payload = await method.invokeMapMethod<String, dynamic>(
      'restoreManagedAsset',
      {'assetLocalIdentifier': normalized},
    );
    return ManagedAssetRestoreResult.fromMap(payload);
  }

  Future<RecoverableManagedAssetDiscoveryResult>
  discoverRecoverableManagedAssets({
    List<String> albumPatterns = historicalAlbumPatterns,
  }) async {
    final normalizedPatterns = albumPatterns
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedPatterns.isEmpty) {
      return RecoverableManagedAssetDiscoveryResult.empty();
    }

    final payload = await method.invokeMapMethod<String, dynamic>(
      'discoverRecoverableManagedAssets',
      {'albumPatterns': normalizedPatterns},
    );
    return RecoverableManagedAssetDiscoveryResult.fromMap(payload);
  }
}
