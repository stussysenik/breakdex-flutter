import 'package:flutter_test/flutter_test.dart';
import 'package:breakdex/core/models/canonical_asset.dart';

void main() {
  final baseTime = DateTime(2026, 1, 15, 10, 0, 0);

  group('CanonicalAssetLive', () {
    test('constructs with required fields', () {
      final asset = CanonicalAssetLive(
        localPath: '/canonical/videos/abc123.mp4', hash: 'a1b2c3d4e5f6',
        fileSizeBytes: 1024, source: AssetSource.camera, importedAt: baseTime,
      );
      expect(asset.hash, 'a1b2c3d4e5f6');
      expect(asset.fileSizeBytes, 1024);
      expect(asset.mimeType, 'video/mp4');
      expect(asset.source, AssetSource.camera);
      expect(asset.copyCount, 1);
    });

    test('displayName uses filename from path', () {
      final asset = CanonicalAssetLive(
        localPath: '/canonical/videos/my_video.mp4', hash: 'abc123',
        fileSizeBytes: 100, source: AssetSource.files, importedAt: baseTime,
      );
      expect(asset.displayName, 'my_video.mp4');
    });

    test('displayName falls back to hash prefix', () {
      final asset = CanonicalAssetLive(
        localPath: '/', hash: 'abcdef1234567890', fileSizeBytes: 100,
        source: AssetSource.files, importedAt: baseTime,
      );
      expect(asset.displayName, 'abcdef12');
    });

    test('isVerified is false when lastVerifiedAt is null', () {
      final asset = CanonicalAssetLive(
        localPath: '/path/video.mp4', hash: 'abc', fileSizeBytes: 100,
        source: AssetSource.photos, importedAt: baseTime,
      );
      expect(asset.isVerified, false);
    });

    test('isVerified is true when lastVerifiedAt is set', () {
      final asset = CanonicalAssetLive(
        localPath: '/path/video.mp4', hash: 'abc', fileSizeBytes: 100,
        source: AssetSource.photos, importedAt: baseTime, lastVerifiedAt: baseTime,
      );
      expect(asset.isVerified, true);
    });

    test('all fields accessible', () {
      const provenance = ProvenanceTrail.empty();
      final asset = CanonicalAssetLive(
        localPath: '/v/abc.mp4', hash: 'hash123', fileSizeBytes: 2048,
        durationMs: 5000, width: 1920, height: 1080,
        lastVerifiedAt: baseTime, copyCount: 3,
        source: AssetSource.cloud, importedAt: baseTime, provenance: provenance,
      );
      expect(asset.durationMs, 5000);
      expect(asset.width, 1920);
      expect(asset.height, 1080);
      expect(asset.copyCount, 3);
      expect(asset.provenance, provenance);
    });
  });

  group('CanonicalAssetTrashed', () {
    test('constructs with required fields', () {
      final asset = CanonicalAssetTrashed(
        localPath: '/path/to/video.mp4', hash: 'hash', fileSizeBytes: 100,
        source: AssetSource.files, importedAt: baseTime,
        deletedAt: baseTime, tombstoneReason: 'user',
      );
      expect(asset.hash, 'hash');
      expect(asset.tombstoneReason, 'user');
      expect(asset.daysUntilPurge, 30);
      expect(asset.displayName, 'video.mp4');
    });

    test('isPastGrace true when days 0', () {
      final asset = CanonicalAssetTrashed(
        hash: 'hash', fileSizeBytes: 100, source: AssetSource.photos,
        importedAt: baseTime, deletedAt: baseTime,
        tombstoneReason: 'expired', daysUntilPurge: 0,
      );
      expect(asset.isPastGrace, true);
    });

    test('isPastGrace false when days remain', () {
      final asset = CanonicalAssetTrashed(
        hash: 'hash', fileSizeBytes: 100, source: AssetSource.photos,
        importedAt: baseTime, deletedAt: baseTime,
        tombstoneReason: 'user', daysUntilPurge: 15,
      );
      expect(asset.isPastGrace, false);
    });
  });

  group('CanonicalAssetOrphaned', () {
    test('isRecoverable with lastKnownPath', () {
      final asset = CanonicalAssetOrphaned(
        lastKnownPath: '/some/path.mp4', hash: 'hash', fileSizeBytes: 100,
        source: AssetSource.camera, importedAt: baseTime,
      );
      expect(asset.isRecoverable, true);
      expect(asset.displayName, 'path.mp4');
    });

    test('isRecoverable with cloud copies', () {
      final asset = CanonicalAssetOrphaned(
        hash: 'hash', fileSizeBytes: 100, source: AssetSource.cloud,
        importedAt: baseTime, availableCloudCopies: ['icloud', 'gdrive'],
      );
      expect(asset.isRecoverable, true);
    });

    test('isRecoverable false when no paths', () {
      final asset = CanonicalAssetOrphaned(
        hash: 'hash', fileSizeBytes: 100, source: AssetSource.legacy, importedAt: baseTime,
      );
      expect(asset.isRecoverable, false);
    });
  });

  group('CanonicalAssetPending', () {
    test('isComplete false for in-progress', () {
      final asset = CanonicalAssetPending(
        sourcePath: '/tmp/incoming.mp4', originalFileName: 'incoming.mp4',
        hash: '0000000000000000000000000000000000000000000000000000000000000000',
        progress: 0.5, source: AssetSource.files, importedAt: baseTime,
      );
      expect(asset.isComplete, false);
      expect(asset.hasError, false);
    });

    test('hasError true when error set', () {
      final asset = CanonicalAssetPending(
        sourcePath: '/tmp/bad.mp4', originalFileName: 'bad.mp4',
        hash: '0000000000000000000000000000000000000000000000000000000000000000',
        error: 'File not found', source: AssetSource.files, importedAt: baseTime,
      );
      expect(asset.hasError, true);
      expect(asset.error, 'File not found');
    });
  });

  group('AssetSource', () {
    test('each source has label', () {
      expect(AssetSource.camera.label, 'Camera');
      expect(AssetSource.photos.label, 'Photos');
      expect(AssetSource.files.label, 'Files');
      expect(AssetSource.cloud.label, 'Cloud');
      expect(AssetSource.legacy.label, 'Legacy');
    });
  });

  group('ProvenanceTrail', () {
    test('empty has no entries', () {
      const trail = ProvenanceTrail.empty();
      expect(trail.isEmpty, true);
      expect(trail.length, 0);
    });

    test('add appends entry immutably', () {
      const trail = ProvenanceTrail.empty();
      final entry = AssetProvenanceEntry(eventType: 'imported', recordedAt: baseTime);
      final updated = trail.add(entry);
      expect(updated.length, 1);
      expect(updated.first.eventType, 'imported');
      expect(trail.isEmpty, true);
    });

    test('multiple adds chain correctly', () {
      final trail = const ProvenanceTrail.empty()
          .add(AssetProvenanceEntry(eventType: 'imported', recordedAt: baseTime))
          .add(AssetProvenanceEntry(eventType: 'verified',
              recordedAt: baseTime.add(const Duration(hours: 1))))
          .add(AssetProvenanceEntry(eventType: 'trashed',
              recordedAt: baseTime.add(const Duration(days: 5)), detail: 'user deleted'));
      expect(trail.length, 3);
      expect(trail.first.eventType, 'imported');
      expect(trail.last.eventType, 'trashed');
      expect(trail.last.detail, 'user deleted');
    });

    test('equality works for identical trails', () {
      final a = const ProvenanceTrail.empty()
          .add(AssetProvenanceEntry(eventType: 'imported', recordedAt: baseTime));
      final b = const ProvenanceTrail.empty()
          .add(AssetProvenanceEntry(eventType: 'imported', recordedAt: baseTime));
      expect(a, equals(b));
    });
  });

  group('CanonicalAsset is sealed', () {
    test('subclasses type-checked by compiler', () {
      final live = CanonicalAssetLive(
        localPath: '/p/v.mp4', hash: 'hash', fileSizeBytes: 100,
        source: AssetSource.camera, importedAt: baseTime,
      );
      final label = switch (live) {
        CanonicalAssetLive() => 'live',
        CanonicalAssetTrashed() => 'trashed',
        CanonicalAssetOrphaned() => 'orphaned',
        CanonicalAssetPending() => 'pending',
      };
      expect(label, 'live');
    });
  });
}
