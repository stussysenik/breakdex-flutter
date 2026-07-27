import 'package:breakdex/core/state_machines/machine.dart';
import 'package:breakdex/core/models/move_creation.dart';

sealed class MoveCreationState {}
class Idle extends MoveCreationState {}
class Hashing extends MoveCreationState {
  final double progress;
  Hashing(this.progress);
}
class Saving extends MoveCreationState {}
class Success extends MoveCreationState {
  final CreateMoveResult result;
  Success(this.result);
}
class Error extends MoveCreationState {
  final String message;
  Error(this.message);
}

sealed class MoveCreationEvent {}
class StartCreation extends MoveCreationEvent {
  final CreateMoveRequest request;
  StartCreation(this.request);
}
class CreationProgress extends MoveCreationEvent {
  final double progress;
  CreationProgress(this.progress);
}
class CreationSuccess extends MoveCreationEvent {
  final CreateMoveResult result;
  CreationSuccess(this.result);
}
class CreationError extends MoveCreationEvent {
  final String message;
  CreationError(this.message);
}

class MoveCreationMachine extends Machine<MoveCreationState, MoveCreationEvent> {
  MoveCreationMachine() : super(Idle());

  @override
  MoveCreationState? transition(final MoveCreationState state, final MoveCreationEvent event) {
    return switch ((state, event)) {
      (Idle(), StartCreation _) => Hashing(0.0),
      (Hashing(), final CreationProgress e) => Hashing(e.progress),
      (Hashing(), final CreationSuccess e) => Success(e.result),
      (Hashing(), final CreationError e) => Error(e.message),
      (Error(), StartCreation _) => Hashing(0.0),
      (Success(), StartCreation _) => Hashing(0.0),
      _ => null,
    };
  }
}
