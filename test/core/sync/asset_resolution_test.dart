import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/sync/asset_resolution.dart';

/// The classifier exists to keep four materially different situations from
/// collapsing into the engine's single "Local file missing" sentence, so every
/// test here pins one of the four apart from the others.
void main() {
  group('classifyAssetResolution', () {
    test('an active owner with bytes wins — the heal already had this owner', () {
      expect(
        classifyAssetResolution(
          ownerCount: 1,
          activeOwnerHasBytes: true,
          archivedOwnerHasBytes: false,
        ),
        AssetResolution.activeOwnerOnDisk,
      );
    });

    test('only an archived owner with bytes is the heal blind spot', () {
      expect(
        classifyAssetResolution(
          ownerCount: 1,
          activeOwnerHasBytes: false,
          archivedOwnerHasBytes: true,
        ),
        AssetResolution.archivedOwnerOnDisk,
      );
    });

    test('active outranks archived when both have bytes', () {
      // Load-bearing: reporting this against the archived owner would invent a
      // blind spot the heal does not have, and send the fix at the wrong query.
      expect(
        classifyAssetResolution(
          ownerCount: 2,
          activeOwnerHasBytes: true,
          archivedOwnerHasBytes: true,
        ),
        AssetResolution.activeOwnerOnDisk,
      );
    });

    test('owners exist but no bytes anywhere is terminal', () {
      expect(
        classifyAssetResolution(
          ownerCount: 3,
          activeOwnerHasBytes: false,
          archivedOwnerHasBytes: false,
        ),
        AssetResolution.bytesGone,
      );
    });

    test('no owning entity at all is an orphan, not merely byte-less', () {
      // Distinct from bytesGone on purpose: an orphan has nothing to heal
      // *from*, so widening the heal's query could never recover it.
      expect(
        classifyAssetResolution(
          ownerCount: 0,
          activeOwnerHasBytes: false,
          archivedOwnerHasBytes: false,
        ),
        AssetResolution.orphan,
      );
    });

    test('is total — every input combination lands on a verdict', () {
      for (final ownerCount in [0, 1, 5]) {
        for (final active in [true, false]) {
          for (final archived in [true, false]) {
            expect(
              () => classifyAssetResolution(
                ownerCount: ownerCount,
                activeOwnerHasBytes: active,
                archivedOwnerHasBytes: archived,
              ),
              returnsNormally,
            );
          }
        }
      }
    });
  });

  group('labels', () {
    test('every verdict has a distinct greppable label and a meaning', () {
      final labels = AssetResolution.values.map(assetResolutionLabel).toSet();
      expect(labels.length, AssetResolution.values.length);
      for (final resolution in AssetResolution.values) {
        expect(assetResolutionMeaning(resolution), isNotEmpty);
      }
    });

    test('only the archived verdict is described as recoverable', () {
      // The dump is read by someone deciding whether a video is gone forever.
      // Exactly one verdict may say otherwise.
      final recoverable = AssetResolution.values
          .where((final r) => assetResolutionMeaning(r).contains('recoverable'))
          .toList();
      expect(recoverable, [AssetResolution.archivedOwnerOnDisk]);
    });
  });
}
