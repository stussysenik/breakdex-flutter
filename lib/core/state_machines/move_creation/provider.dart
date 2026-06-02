import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/move_creation.dart';
import '../../providers.dart';
import '../../services/storage_action_machine.dart';
import 'machine.dart';

class MoveCreationNotifier extends Notifier<MoveCreationState> {
  late final MoveCreationMachine _machine;

  @override
  MoveCreationState build() {
    _machine = MoveCreationMachine();
    return Idle();
  }

  void start(final CreateMoveRequest request) {
    _send(StartCreation(request));
  }

  void _send(final MoveCreationEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next, event);
    }
  }

  void _executeEntryActions(final MoveCreationState s, final MoveCreationEvent e) {
    if (s is Hashing && e is StartCreation) {
      _runCreation(e.request);
    }
  }

  Future<void> _runCreation(final CreateMoveRequest request) async {
    final engine = ref.read(storageActionMachineProvider);
    
    // Listen for "Hot" progress updates
    final subscription = engine.progress.listen((final p) {
      _send(CreationProgress(p.progress));
    });

    try {
      final service = ref.read(moveCreationServiceProvider);
      final result = await service.createMove(request);
      _send(CreationSuccess(result));
    } catch (e) {
      _send(CreationError(e.toString()));
    } finally {
      await subscription.cancel();
    }
  }
}

final moveCreationStateProvider = NotifierProvider<MoveCreationNotifier, MoveCreationState>(
  MoveCreationNotifier.new,
);
