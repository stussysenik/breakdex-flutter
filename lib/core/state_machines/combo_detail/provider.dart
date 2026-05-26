import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'machine.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';

class ComboDetailNotifier extends FamilyNotifier<ComboDetailState, String> {
  late final ComboDetailMachine _machine;

  @override
  ComboDetailState build(String arg) {
    // We don't have the combo yet, but the UI will call init() or we can watch it.
    // For simplicity, we start with a dummy or expect a stream to feed it.
    final initialState = Idle(Combo(
      id: arg,
      name: 'Loading...',
      notes: null,
      activeVideoPath: null,
    ));
    _machine = ComboDetailMachine(initialState);
    return initialState;
  }

  void init(Combo combo) {
    state = Idle(combo);
    _machine.send(StreamUpdate(combo));
  }

  void send(ComboDetailEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next, event);
    }
  }

  void _executeEntryActions(ComboDetailState s, ComboDetailEvent e) {
    if (s is SavingNotes && e is UpdateNotes) {
      _saveNotes(s.combo, e.notes);
    } else if (s is Deleting && e is ConfirmDelete) {
      _deleteCombo(s.combo);
    }
  }

  Future<void> _saveNotes(Combo combo, String notes) async {
    try {
      await ref.read(blackboxServiceProvider).log('update_combo_notes', 'combo', combo.id);
      await ref.read(comboRepositoryProvider).update(
            CombosCompanion(
              id: Value(combo.id),
              notes: Value(notes.isEmpty ? null : notes),
            ),
          );
      send(SaveSucceeded(combo.copyWith(notes: Value(notes.isEmpty ? null : notes))));
    } catch (e) {
      send(SaveFailed(e.toString()));
    }
  }

  Future<void> _deleteCombo(Combo combo) async {
    try {
      await ref.read(blackboxServiceProvider).log('delete_combo', 'combo', combo.id, {'name': combo.name});
      await ref.read(mediaCleanupServiceProvider).cleanupComboMedia(combo);
      await ref.read(comboRepositoryProvider).delete(combo.id);
      send(DeleteSucceeded());
    } catch (e) {
      send(DeleteFailed(e.toString()));
    }
  }
}

final comboDetailStateProvider = NotifierProvider.family<ComboDetailNotifier, ComboDetailState, String>(
  ComboDetailNotifier.new,
);
