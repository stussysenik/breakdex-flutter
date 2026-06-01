import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/models/learning_state.dart';
import 'package:breakdex/core/state_machines/move_detail/state.dart';
import 'package:breakdex/core/state_machines/move_detail/event.dart';
import 'package:breakdex/core/state_machines/move_detail/machine.dart';

Move _testMove() => Move(
  id: 'm1',
  name: 'Windmill',
  category: 'power',
  count: 3,
  learningState: 'new',
  notes: null,
  imagePaths: null,
  videoPath: null,
  originalVideoName: null,
  managedAlbumAssetId: null,
  managedAlbumFilename: null,
  managedAlbumName: null,
  contentHash: null,
  createdAt: DateTime(2024, 1, 1),
);

void main() {
  group('MoveDetailMachine — basic transitions', () {
    test('starts in Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      expect(m.state, isA<Idle>());
    });

    test('Idle + TapRename → Renaming', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      expect(m.state, isA<Renaming>());
      expect((m.state as Renaming).draftName, 'Windmill');
    });

    test('Idle + TapDelete → ConfirmingDelete', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapDelete(combos: []));
      expect(m.state, isA<ConfirmingDelete>());
    });

    test('Idle + TapChangeState → ChangingState', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapChangeState());
      expect(m.state, isA<ChangingState>());
    });

    test('Idle + TapChangeCategory → ChangingCategory', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapChangeCategory());
      expect(m.state, isA<ChangingCategory>());
    });

    test('Idle + TapChangeCount → ChangingCount', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapChangeCount());
      expect(m.state, isA<ChangingCount>());
    });
  });

  group('MoveDetailMachine — rename flow', () {
    test('full rename: Idle → Renaming → ValidatingName → SavingName → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));

      m.send(const TapRename());
      expect(m.state, isA<Renaming>());

      m.send(const UpdateDraft('Barrel Mill'));
      expect(m.state, isA<Renaming>());
      expect((m.state as Renaming).draftName, 'Barrel Mill');

      m.send(const SaveName('Barrel Mill'));
      expect(m.state, isA<ValidatingName>());

      m.send(const NameAvailable());
      expect(m.state, isA<SavingName>());
      expect((m.state as SavingName).newName, 'Barrel Mill');

      final updatedMove = _testMove().copyWith(name: 'Barrel Mill');
      m.send(SaveSucceeded(updatedMove));
      expect(m.state, isA<Idle>());
      expect((m.state as Idle).move.name, 'Barrel Mill');
    });

    test('rename with conflict: ValidatingName → NameConflict → Renaming', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      m.send(const SaveName('Taken'));

      expect(m.state, isA<ValidatingName>());

      m.send(const NameTaken());
      expect(m.state, isA<NameConflict>());
      expect((m.state as NameConflict).conflictingName, 'Taken');

      // User edits name to retry
      m.send(const UpdateDraft('New Name'));
      expect(m.state, isA<Renaming>());
    });

    test('cancel rename: Renaming → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      m.send(const Cancel());
      expect(m.state, isA<Idle>());
    });

    test('cancel from NameConflict', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      m.send(const SaveName('Taken'));
      m.send(const NameTaken());
      expect(m.state, isA<NameConflict>());
      m.send(const Cancel());
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — delete flow', () {
    test('full delete: Idle → ConfirmingDelete → Deleting → Gone', () {
      final m = MoveDetailMachine(Idle(_testMove()));

      m.send(const TapDelete(combos: []));
      expect(m.state, isA<ConfirmingDelete>());

      m.send(const Confirm());
      expect(m.state, isA<Deleting>());

      m.send(const DeleteSucceeded());
      expect(m.state, isA<Gone>());
    });

    test('cancel delete: ConfirmingDelete → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapDelete(combos: []));
      m.send(const Cancel());
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — mutual exclusion', () {
    test('cannot rename while confirming delete', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapDelete(combos: []));
      expect(m.state, isA<ConfirmingDelete>());

      m.send(const TapRename());
      expect(m.state, isA<ConfirmingDelete>()); // ignored
    });

    test('cannot delete while renaming', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      expect(m.state, isA<Renaming>());

      m.send(const TapDelete(combos: []));
      expect(m.state, isA<Renaming>()); // ignored
    });

    test('cannot trigger actions while saving', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      m.send(const SaveName('New'));
      m.send(const NameAvailable());
      expect(m.state, isA<SavingName>());

      // While saving, nothing else should be accepted
      m.send(const TapDelete(combos: []));
      m.send(const TapRename());
      m.send(const TapChangeCategory());
      expect(m.state, isA<SavingName>()); // all ignored
    });
  });

  group('MoveDetailMachine — state change', () {
    test('ChangingState → SavingState → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapChangeState());
      m.send(const SaveState(LearningState.learning));
      expect(m.state, isA<SavingState>());

      final updated = _testMove().copyWith(learningState: 'learning');
      m.send(SaveSucceeded(updated));
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — video flows', () {
    test('pick video: PickingVideo → SavingVideo → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapAddVideo());
      expect(m.state, isA<PickingVideo>());

      m.send(const VideoPicked('/videos/test.mp4', 'test.mp4'));
      expect(m.state, isA<SavingVideo>());

      final updated = _testMove().copyWith(videoPath: const Value('/videos/test.mp4'));
      m.send(SaveSucceeded(updated));
      expect(m.state, isA<Idle>());
    });

    test('cancel video pick: PickingVideo → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapAddVideo());
      m.send(const VideoPickCancelled());
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — log entries', () {
    test('add log: AddingLog → SavingLog → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapAddLog());
      expect(m.state, isA<AddingLog>());

      m.send(const SaveLogBody('Practiced transitions'));
      expect(m.state, isA<SavingLog>());

      m.send(SaveSucceeded(_testMove()));
      expect(m.state, isA<Idle>());
    });

    test('delete log with confirmation: ConfirmingDeleteLog → DeletingLog → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapDeleteLog('entry-1'));
      expect(m.state, isA<ConfirmingDeleteLog>());
      expect((m.state as ConfirmingDeleteLog).entryId, 'entry-1');

      m.send(const Confirm());
      expect(m.state, isA<DeletingLog>());

      m.send(SaveSucceeded(_testMove()));
      expect(m.state, isA<Idle>());
    });

    test('cancel delete log', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapDeleteLog('entry-1'));
      m.send(const Cancel());
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — notes inline', () {
    test('typing notes enters NotesDirty', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const UpdateNotes('some notes'));
      expect(m.state, isA<NotesDirty>());
      expect((m.state as NotesDirty).draftText, 'some notes');
    });

    test('further typing stays in NotesDirty', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const UpdateNotes('a'));
      m.send(const UpdateNotes('ab'));
      expect(m.state, isA<NotesDirty>());
      expect((m.state as NotesDirty).draftText, 'ab');
    });

    test('notes save succeeds', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const UpdateNotes('notes'));
      m.send(SaveSucceeded(_testMove().copyWith(notes: const Value('notes'))));
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — stream updates', () {
    test('stream update in Idle applies new data', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      final updated = _testMove().copyWith(count: 5);
      m.send(StreamUpdate(updated));
      expect((m.state as Idle).move.count, 5);
    });

    test('stream update ignored in Renaming', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      final updated = _testMove().copyWith(name: 'Changed Externally');
      m.send(StreamUpdate(updated));
      expect(m.state, isA<Renaming>());
      expect((m.state as Renaming).draftName, 'Windmill');
    });
  });

  group('MoveDetailMachine — count editor', () {
    test('ChangingCount → SavingCount → Idle', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapChangeCount());
      expect(m.state, isA<ChangingCount>());

      m.send(const SaveCount(8));
      expect(m.state, isA<SavingCount>());
      expect((m.state as SavingCount).newCount, 8);

      m.send(SaveSucceeded(_testMove().copyWith(count: 8)));
      expect(m.state, isA<Idle>());
    });
  });

  group('MoveDetailMachine — album sync failure', () {
    test('album sync failure after save transitions to AlbumSyncFailed', () {
      final m = MoveDetailMachine(Idle(_testMove()));
      m.send(const TapRename());
      m.send(const SaveName('New'));
      m.send(const NameAvailable());
      expect(m.state, isA<SavingName>());

      m.send(const AlbumSyncFailedEvent('Album sync failed'));
      expect(m.state, isA<AlbumSyncFailed>());
      expect((m.state as AlbumSyncFailed).message, 'Album sync failed');

      m.send(const Cancel());
      expect(m.state, isA<Idle>());
    });
  });
}
