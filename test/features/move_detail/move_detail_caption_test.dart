import 'package:breakdex/core/models/move_detail_caption.dart';
import 'package:flutter_test/flutter_test.dart';

/// The caption slot under a move's name on the detail screen.
///
/// Before this change the slot rendered `originalVideoName`, falling back to
/// `ID: <hash8>` — a camera filename or a raw identifier as the only thing
/// captioning a move's name. D4 rules that slot is a subtitle, so it shows the
/// date; the filename keeps its labeled home in the Video Info panel.
void main() {
  final createdAt = DateTime(2026, 7, 12, 14, 22);

  MoveDetailCaptionSpec resolve(
    final MoveDetailCaption mode, {
    final String? originalVideoName = 'IMG_4471.mov',
    final String? contentHash = 'a1b2c3d4e5f6',
  }) => resolveMoveDetailCaption(
    mode: mode,
    createdAt: createdAt,
    originalVideoName: originalVideoName,
    contentHash: contentHash,
    moveId: 'deadbeef-0000-1111-2222-333344445555',
  );

  group('resolveMoveDetailCaption', () {
    test('dateAdded shows the added date even when a filename exists', () {
      // The behaviour swap: today this slot would render 'IMG_4471.mov'.
      expect(
        resolve(MoveDetailCaption.dateAdded),
        MoveDetailCaptionSpec.date(createdAt),
      );
    });

    test('filename shows the original video name', () {
      expect(
        resolve(MoveDetailCaption.filename),
        const MoveDetailCaptionSpec.text('IMG_4471.mov'),
      );
    });

    test('filename with no filename falls back to the date, never to an id', () {
      // The ruling. Today's code falls back to `ID: <hash8>` here — asking for
      // a *name* and being handed an identifier is the exact D4 violation.
      expect(
        resolve(MoveDetailCaption.filename, originalVideoName: null),
        MoveDetailCaptionSpec.date(createdAt),
      );
    });

    test('contentId shows the content hash, truncated', () {
      expect(
        resolve(MoveDetailCaption.contentId),
        const MoveDetailCaptionSpec.text('ID: a1b2c3d4'),
      );
    });

    test('contentId with no hash falls back to the move id', () {
      expect(
        resolve(MoveDetailCaption.contentId, contentHash: null),
        const MoveDetailCaptionSpec.text('ID: deadbeef'),
      );
    });

    test('hidden shows nothing', () {
      expect(resolve(MoveDetailCaption.hidden), const MoveDetailCaptionSpec.none());
    });

    test('an identifier is reachable ONLY by explicitly asking for one', () {
      // Pins the ruling against every future mode: a raw identifier can never
      // arrive by fallback, only by the owner selecting contentId. Without this
      // an added mode could quietly reintroduce the UUID caption.
      for (final mode in MoveDetailCaption.values) {
        final spec = resolve(mode, originalVideoName: null, contentHash: null);
        final isIdentifier =
            spec is MoveDetailCaptionText && spec.value.startsWith('ID: ');
        expect(
          isIdentifier,
          mode == MoveDetailCaption.contentId,
          reason: '$mode must not resolve to an identifier by fallback',
        );
      }
    });
  });

  group('MoveDetailCaption.fromString', () {
    test('round-trips every value through its persisted name', () {
      for (final mode in MoveDetailCaption.values) {
        expect(MoveDetailCaption.fromString(mode.name), mode);
      }
    });

    test('absent or unknown falls back to the date, not to today\'s filename', () {
      // Data-safety fallback per the AddFlowOrder idiom — but the default is
      // deliberately the *new* humane behaviour, since D4 rules the filename
      // caption a defect rather than a preference worth preserving.
      expect(MoveDetailCaption.fromString(null), MoveDetailCaption.dateAdded);
      expect(MoveDetailCaption.fromString('nonsense'), MoveDetailCaption.dateAdded);
    });
  });
}
