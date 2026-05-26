import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/move_creation.dart';
import '../../providers.dart';
import 'machine.dart';

class MoveCreationNotifier extends Notifier<MoveCreationState> {
  late final MoveCreationMachine _machine;

  @override
  MoveCreationState build() {
    _machine = MoveCreationMachine();
    return Idle();
  }

  void start(CreateMoveRequest request) {
    _send(StartCreation(request));
  }

  void _send(MoveCreationEvent event) {
    final next = _machine.transition(state, event);
    if (next != null) {
      state = next;
      _executeEntryActions(next, event);
    }
  }

  void _executeEntryActions(MoveCreationState s, MoveCreationEvent e) {
    if (s is Hashing && e is StartCreation) {
      _runCreation(e.request);
    }
  }

  Future<void> _runCreation(CreateMoveRequest request) async {
    try {
      final service = ref.read(moveCreationServiceProvider);
      final result = await service.createMove(request);
      _send(CreationSuccess(result));
    } catch (e) {
      _send(CreationError(e.toString()));
    }
  }
}

final moveCreationStateProvider = NotifierProvider<MoveCreationNotifier, MoveCreationState>(
  MoveCreationNotifier.new,
);
