import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/models/asset_residency.dart';

AssetCopyFact _copy(final String provider, final String status) =>
    AssetCopyFact(provider: provider, status: status);

void main() {
  group('describeResidency', () {
    test('no rows at all is untracked, not local-only', () {
      // An asset the copy ledger has never heard of is a different fact from
      // one it knows lives only on this device. Conflating them would promise
      // the two-copy guarantee has been evaluated when it has not.
      final r = describeResidency(const []);
      expect(r.state, AssetResidencyState.untracked);
      expect(r.cloudPlaces, isEmpty);
    });

    test('a verified local copy with no cloud row is localOnly', () {
      final r = describeResidency([_copy('local', 'verified')]);
      expect(r.state, AssetResidencyState.localOnly);
      expect(r.cloudPlaces, isEmpty);
    });

    test('a verified cloud copy names the place it lives', () {
      final r = describeResidency([
        _copy('local', 'verified'),
        _copy('gdrive', 'verified'),
      ]);
      expect(r.state, AssetResidencyState.uploaded);
      expect(r.cloudPlaces, [CloudPlace.gdrive]);
    });

    test('uploading outranks a verified sibling — the transfer is the news', () {
      final r = describeResidency([
        _copy('local', 'verified'),
        _copy('gdrive', 'verified'),
        _copy('icloud', 'uploading'),
      ]);
      expect(r.state, AssetResidencyState.pending);
      // The verified place is still named: "on Google Drive, sending to iCloud".
      expect(r.cloudPlaces, [CloudPlace.gdrive]);
      expect(r.pendingPlaces, [CloudPlace.icloud]);
    });

    test('a failure outranks everything — it is the only actionable state', () {
      final r = describeResidency([
        _copy('local', 'verified'),
        _copy('gdrive', 'verified'),
        _copy('icloud', 'uploading'),
        _copy('s3', 'failed'),
      ]);
      expect(r.state, AssetResidencyState.failed);
      expect(r.failedPlaces, [CloudPlace.s3]);
    });

    test('cloud-only: the bytes are up there but not on this device', () {
      final r = describeResidency([_copy('gdrive', 'verified')]);
      expect(r.state, AssetResidencyState.cloudOnly);
      expect(r.cloudPlaces, [CloudPlace.gdrive]);
    });

    test('a deleted cloud row does not count as a place it lives', () {
      final r = describeResidency([
        _copy('local', 'verified'),
        _copy('gdrive', 'deleted'),
      ]);
      expect(r.state, AssetResidencyState.localOnly);
      expect(r.cloudPlaces, isEmpty);
    });

    test('a pending local row is not a cloud transfer', () {
      // 'local' is never in flight to anywhere — a pending local row means the
      // import has not finished hashing, which is not an upload direction.
      final r = describeResidency([_copy('local', 'pending')]);
      expect(r.state, AssetResidencyState.localOnly);
      expect(r.pendingPlaces, isEmpty);
    });

    test('an unknown provider key is carried, not dropped', () {
      final r = describeResidency([_copy('dropbox', 'verified')]);
      expect(r.state, AssetResidencyState.cloudOnly);
      expect(r.cloudPlaces.single.label, 'dropbox');
    });

    test('places are ordered by provider key so the line is stable', () {
      final r = describeResidency([
        _copy('s3', 'verified'),
        _copy('gdrive', 'verified'),
        _copy('local', 'verified'),
      ]);
      expect(r.cloudPlaces, [CloudPlace.gdrive, CloudPlace.s3]);
    });
  });
}
