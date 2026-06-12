import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'machine.dart';
import '../../../core/database/database.dart';
import '../../../core/database/daos/combos_dao.dart';
import '../../../core/providers.dart';
import '../../../core/utils/diagnostics.dart';

final comboByIdStreamProvider = StreamProvider.family<Combo, String>((final ref, final id) {
  return ref.watch(comboRepositoryProvider).watchById(id);
});

final comboMovesStreamProvider = StreamProvider.family<List<ComboMoveWithDetail>, String>((final ref, final id) {
  return ref.watch(comboRepositoryProvider).watchComboMoves(id);
});

class ComboDetailNotifier extends FamilyNotifier<ComboDetailState, String> {
  late final ComboDetailMachine _machine;
  int _saveGeneration = 0;
  String _latestDraft = '';
  bool _streamInitialized = false;

  @override
  ComboDetailState build(final String arg) {
    final initialState = Idle(Combo(
      id: arg,
      name: 'Loading...',
      notes: null,
      activeVideoPath: null,
      status: 'idea',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ));
    _machine = ComboDetailMachine(initialState);
    DiagnosticsLog.info('ComboDetailNotifier', 'build comboId=$arg');

    ref.listen(comboByIdStreamProvider(arg), (final prev, final next) {
      if (next.hasValue) {
        final combo = next.value!;
        final log = StageLogger.begin('ComboDetailNotifier._onComboStream',
            subsystem: 'ComboDetail',
            context: {'comboId': arg, 'name': combo.name});
        log.stage('emit', {'initializedBefore': _streamInitialized});
        if (!_streamInitialized) {
          _streamInitialized = true;
          _latestDraft = combo.notes ?? '';
        }
        send(StreamUpdate(combo));
        log.complete();
      }
    });

    return initialState;
  }

  void send(final ComboDetailEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next, event);
    }
  }

  void _executeEntryActions(final ComboDetailState s, final ComboDetailEvent e) {
    if (s is SavingNotes && e is UpdateNotes) {
      _latestDraft = e.text;
      _saveNotes(s.combo, e.text, ++_saveGeneration);
    } else if (s is NotesDirty && e is UpdateNotes) {
      _latestDraft = e.text;
      _saveNotes(s.combo, e.text, ++_saveGeneration);
    } else if (s is Deleting && e is ConfirmDelete) {
      _deleteCombo(s.combo);
    } else if (s is SavingLog && e is SaveLogBody) {
      _saveLogEntry(s.combo, s.body);
    } else if (s is DeletingLog && e is Cancel) {
      _deleteLogEntry(s.combo, s.entryId);
    }
  }

  Future<void> _saveNotes(final Combo combo, final String notes, final int generation) async {
    final log = StageLogger.begin('_saveNotes', subsystem: 'ComboDetail', context: {
      'comboId': combo.id, 'generation': generation,
    });
    try {
      if (_latestDraft != notes) {
        log.stage('skipped_stale', {'latestDraft': _latestDraft});
        log.complete('superseded by newer draft');
        return;
      }
      await ref.read(blackboxServiceProvider).log('update_combo_notes', 'combo', combo.id);
      log.stage('blackboxLogged');
      await ref.read(comboRepositoryProvider).update(
            CombosCompanion(
              id: Value(combo.id),
              notes: Value(notes.isEmpty ? null : notes),
            ),
          );
      log.stage('dbUpdated');
      if (_saveGeneration == generation) {
        send(SaveSucceeded(combo.copyWith(notes: Value(notes.isEmpty ? null : notes))));
      } else {
        log.complete('skipped — newer generation $_saveGeneration');
        return;
      }
      log.complete();
    } catch (e, stack) {
      log.fail(e, stack);
      if (_saveGeneration == generation) {
        send(SaveFailed(e.toString()));
      }
    }
  }

  Future<void> _deleteCombo(final Combo combo) async {
    final log = StageLogger.begin('_deleteCombo', subsystem: 'ComboDetail', context: {
      'comboId': combo.id, 'name': combo.name,
    });
    try {
      await ref.read(blackboxServiceProvider).log('delete_combo', 'combo', combo.id, {'name': combo.name});
      log.stage('blackboxLogged');
      await ref.read(mediaCleanupServiceProvider).cleanupComboMedia(combo);
      log.stage('cleanupComboMedia');
      await ref.read(comboRepositoryProvider).delete(combo.id);
      log.stage('dbDeleted');
      send(DeleteSucceeded());
      log.complete();
    } catch (e, stack) {
      log.fail(e, stack);
      send(DeleteFailed(e.toString()));
    }
  }

  Future<void> _saveLogEntry(final Combo combo, final String body) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      final dao = ref.read(comboNoteEntriesDaoProvider);
      await dao.addEntry(id: const Uuid().v4(), comboId: combo.id, body: body);
      send(SaveSucceeded(combo));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }

  Future<void> _deleteLogEntry(final Combo combo, final String entryId) async {
    try {
      unawaited(HapticFeedback.mediumImpact());
      final dao = ref.read(comboNoteEntriesDaoProvider);
      await dao.deleteEntry(entryId);
      send(SaveSucceeded(combo));
    } catch (e) {
      send(SaveFailed('$e'));
    }
  }
}

final comboDetailStateProvider = NotifierProvider.family<ComboDetailNotifier, ComboDetailState, String>(
  ComboDetailNotifier.new,
);

final allComboIdsProvider = StreamProvider<List<String>>((final ref) {
  return ref.watch(combosDaoProvider).watchAll().map(
        (final combos) => combos.map((final c) => c.id).toList(),
      );
});
