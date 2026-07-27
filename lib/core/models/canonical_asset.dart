import 'package:breakdex/core/platform/io.dart';

sealed class CanonicalAsset {
  final String hash;
  final int fileSizeBytes;
  final String mimeType;
  final AssetSource source;
  final DateTime importedAt;

  const CanonicalAsset({
    required this.hash,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.source,
    required this.importedAt,
  });

  String get displayName;
}

class CanonicalAssetLive extends CanonicalAsset {
  final String localPath;
  final int? durationMs;
  final int? width;
  final int? height;
  final DateTime? lastVerifiedAt;
  final int copyCount;
  final ProvenanceTrail provenance;

  const CanonicalAssetLive({
    required this.localPath,
    required super.hash,
    required super.fileSizeBytes,
    super.mimeType = 'video/mp4',
    this.durationMs,
    this.width,
    this.height,
    this.lastVerifiedAt,
    this.copyCount = 1,
    required super.source,
    required super.importedAt,
    this.provenance = const ProvenanceTrail.empty(),
  });

  @override
  String get displayName {
    final fileName = localPath.split('/').last;
    return fileName.isNotEmpty ? fileName : hash.substring(0, 8);
  }

  bool get fileExists => File(localPath).existsSync();
  bool get isVerified => lastVerifiedAt != null;
}

class CanonicalAssetTrashed extends CanonicalAsset {
  final String? localPath;
  final DateTime deletedAt;
  final String tombstoneReason;
  final int daysUntilPurge;

  const CanonicalAssetTrashed({
    this.localPath,
    required super.hash,
    required super.fileSizeBytes,
    super.mimeType = 'video/mp4',
    required super.source,
    required super.importedAt,
    required this.deletedAt,
    required this.tombstoneReason,
    this.daysUntilPurge = 30,
  });

  @override
  String get displayName =>
      localPath != null ? localPath!.split('/').last : 'Deleted Asset';
  bool get isPastGrace => daysUntilPurge <= 0;
}

class CanonicalAssetOrphaned extends CanonicalAsset {
  final String? lastKnownPath;
  final List<String> availableCloudCopies;

  const CanonicalAssetOrphaned({
    this.lastKnownPath,
    required super.hash,
    required super.fileSizeBytes,
    super.mimeType = 'video/mp4',
    required super.source,
    required super.importedAt,
    this.availableCloudCopies = const [],
  });

  @override
  String get displayName =>
      lastKnownPath != null ? lastKnownPath!.split('/').last : 'Missing Asset';
  bool get isRecoverable =>
      lastKnownPath != null || availableCloudCopies.isNotEmpty;
}

class CanonicalAssetPending extends CanonicalAsset {
  final String sourcePath;
  final String originalFileName;
  final double progress;
  final String? error;

  const CanonicalAssetPending({
    required this.sourcePath,
    required this.originalFileName,
    required super.hash,
    this.progress = 0.0,
    super.fileSizeBytes = 0,
    super.mimeType = 'video/mp4',
    this.error,
    required super.source,
    required super.importedAt,
  });

  @override
  String get displayName => originalFileName;
  bool get isComplete => hash != _emptyHash && progress >= 1.0;
  bool get hasError => error != null;
  static const _emptyHash =
      '0000000000000000000000000000000000000000000000000000000000000000';
}

enum AssetSource {
  camera,
  photos,
  files,
  cloud,
  legacy;

  String get label => switch (this) {
        camera => 'Camera',
        photos => 'Photos',
        files => 'Files',
        cloud => 'Cloud',
        legacy => 'Legacy',
      };
}

class AssetProvenanceEntry {
  final String eventType;
  final DateTime recordedAt;
  final String? detail;

  const AssetProvenanceEntry({
    required this.eventType,
    required this.recordedAt,
    this.detail,
  });

  @override
  bool operator ==(final Object other) =>
      other is AssetProvenanceEntry &&
      other.eventType == eventType &&
      other.recordedAt == recordedAt;

  @override
  int get hashCode => Object.hash(eventType, recordedAt);
}

class ProvenanceTrail {
  final List<AssetProvenanceEntry> _entries;
  const ProvenanceTrail._(this._entries);
  const ProvenanceTrail.empty() : _entries = const [];

  List<AssetProvenanceEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;
  int get length => _entries.length;
  AssetProvenanceEntry get first => _entries.first;
  AssetProvenanceEntry get last => _entries.last;

  ProvenanceTrail add(final AssetProvenanceEntry entry) =>
      ProvenanceTrail._([..._entries, entry]);

  @override
  bool operator ==(final Object other) =>
      other is ProvenanceTrail &&
      _entries.length == other._entries.length &&
      _entries.asMap().entries.every(
            (final e) => e.value == other._entries[e.key],
          );

  @override
  int get hashCode => Object.hashAll(_entries);
}
