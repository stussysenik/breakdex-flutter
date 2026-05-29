import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:math';
import '../../../core/database/database.dart';

part 'party_bloc.freezed.dart';

@freezed
class PartyEvent with _$PartyEvent {
  const factory PartyEvent.shake(List<Move> allMoves, int durationMs) = _Shake;
  const factory PartyEvent.tick(DateTime now) = _Tick;
}

@freezed
class PartyState with _$PartyState {
  const factory PartyState.idle() = _Idle;
  const factory PartyState.cycling({
    required List<Move> allMoves,
    required Move currentMove,
    required Move finalMove,
    required DateTime startTime,
    required DateTime lastFlip,
    required int durationMs,
  }) = _Cycling;
  const factory PartyState.revealing({required Move move}) = _Revealing;
  const factory PartyState.revealed({required Move move}) = _Revealed;
}

class PartyBloc extends Bloc<PartyEvent, PartyState> {
  final Random _random = Random();
  static const _cycleFlipBaseMs = 60;
  static const _cycleFlipMaxMs = 260;

  PartyBloc() : super(const PartyState.idle()) {
    on<_Shake>(_onShake);
    on<_Tick>(_onTick);
  }

  void _onShake(_Shake event, Emitter<PartyState> emit) {
    print('[PartyBloc] _onShake called. State: $state. Moves count: ${event.allMoves.length}');
    if (event.allMoves.isEmpty) {
      print('[PartyBloc] _onShake ignored: Moves list is empty');
      return;
    }
    if (state is! _Idle && state is! _Revealed) {
      print('[PartyBloc] _onShake ignored: State is not Idle or Revealed');
      return;
    }

    final finalMove = event.allMoves[_random.nextInt(event.allMoves.length)];
    final currentMove = event.allMoves[_random.nextInt(event.allMoves.length)];
    final now = DateTime.now();

    print('[PartyBloc] Emitting cycling state. currentMove: ${currentMove.name}, finalMove: ${finalMove.name}');
    emit(PartyState.cycling(
      allMoves: event.allMoves,
      currentMove: currentMove,
      finalMove: finalMove,
      startTime: now,
      lastFlip: now,
      durationMs: event.durationMs,
    ));
  }

  void _onTick(_Tick event, Emitter<PartyState> emit) {
    final currentState = state;
    if (currentState is _Revealing) {
      print('[PartyBloc] _onTick: currentState is _Revealing. Emitting revealed with ${currentState.move.name}');
      emit(PartyState.revealed(move: currentState.move));
      return;
    }
    if (currentState is! _Cycling) {
      // Don't spam print for every tick when idle, but print once if we get ticks while idle
      return;
    }

    final elapsed = event.now.difference(currentState.startTime);
    if (elapsed.inMilliseconds >= currentState.durationMs) {
      print('[PartyBloc] _onTick: Cycling duration elapsed (${elapsed.inMilliseconds} >= ${currentState.durationMs} ms). Emitting revealing with finalMove: ${currentState.finalMove.name}');
      emit(PartyState.revealing(move: currentState.finalMove));
      return;
    }

    final progress = elapsed.inMilliseconds / currentState.durationMs;
    final intervalMs = _cycleFlipBaseMs +
        ((_cycleFlipMaxMs - _cycleFlipBaseMs) * progress * progress).round();

    final sinceLastFlip = event.now.difference(currentState.lastFlip);
    if (sinceLastFlip.inMilliseconds >= intervalMs) {
      final nextMove = currentState.allMoves[_random.nextInt(currentState.allMoves.length)];
      emit(currentState.copyWith(
        currentMove: nextMove,
        lastFlip: event.now,
      ));
    }
  }
}
