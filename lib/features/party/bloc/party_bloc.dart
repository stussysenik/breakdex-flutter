import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/diagnostics.dart';

part 'party_bloc.freezed.dart';

@freezed
abstract class PartyEvent with _$PartyEvent {
  const factory PartyEvent.shake(final List<Move> allMoves, final int durationMs) = _Shake;
  const factory PartyEvent.tick(final DateTime now) = _Tick;
}

@freezed
abstract class PartyState with _$PartyState {
  const factory PartyState.idle() = _Idle;
  const factory PartyState.cycling({
    required final List<Move> allMoves,
    required final Move currentMove,
    required final Move finalMove,
    required final DateTime startTime,
    required final DateTime lastFlip,
    required final int durationMs,
  }) = _Cycling;
  const factory PartyState.revealing({required final Move move}) = _Revealing;
  const factory PartyState.revealed({required final Move move}) = _Revealed;
}

class PartyBloc extends Bloc<PartyEvent, PartyState> {
  final Random _random = Random();
  static const _cycleFlipBaseMs = 60;
  static const _cycleFlipMaxMs = 260;
  static const _subsystem = 'Party(Move)';

  PartyBloc() : super(const PartyState.idle()) {
    on<_Shake>(_onShake);
    on<_Tick>(_onTick);
  }

  void _onShake(final _Shake event, final Emitter<PartyState> emit) {
    DiagnosticsLog.info(
      _subsystem,
      'shake received; state=${state.runtimeType} moves=${event.allMoves.length}',
    );
    if (event.allMoves.isEmpty) {
      DiagnosticsLog.warn(_subsystem, 'shake ignored: moves list is empty');
      return;
    }
    if (state is! _Idle && state is! _Revealed) {
      DiagnosticsLog.debug(
        _subsystem,
        'shake ignored: state is ${state.runtimeType}',
      );
      return;
    }

    final finalMove = event.allMoves[_random.nextInt(event.allMoves.length)];
    final currentMove = event.allMoves[_random.nextInt(event.allMoves.length)];
    final now = DateTime.now();

    DiagnosticsLog.info(
      _subsystem,
      'cycling → "${finalMove.name}"',
    );
    emit(PartyState.cycling(
      allMoves: event.allMoves,
      currentMove: currentMove,
      finalMove: finalMove,
      startTime: now,
      lastFlip: now,
      durationMs: event.durationMs,
    ));
  }

  void _onTick(final _Tick event, final Emitter<PartyState> emit) {
    final currentState = state;
    if (currentState is _Revealing) {
      DiagnosticsLog.info(
        _subsystem,
        'revealing → revealed "${currentState.move.name}"',
      );
      emit(PartyState.revealed(move: currentState.move));
      return;
    }
    if (currentState is! _Cycling) return;

    final elapsed = event.now.difference(currentState.startTime);
    if (elapsed.inMilliseconds >= currentState.durationMs) {
      DiagnosticsLog.info(
        _subsystem,
        'cycle expired (${elapsed.inMilliseconds}ms) → revealing "${currentState.finalMove.name}"',
      );
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
