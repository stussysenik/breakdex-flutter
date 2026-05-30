import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/diagnostics.dart';

sealed class ComboPartyEvent {
  const ComboPartyEvent();
}

class ComboShake extends ComboPartyEvent {
  final List<ComboPartyDisplay> combos;
  final int durationMs;

  const ComboShake(this.combos, this.durationMs);
}

class ComboTick extends ComboPartyEvent {
  final DateTime now;

  const ComboTick(this.now);
}

class ComboPartyDisplay {
  final Combo combo;
  final List<String> moveNames;

  const ComboPartyDisplay({required this.combo, required this.moveNames});

  String get name => combo.name;
  String get id => combo.id;
  String? get videoPath => combo.activeVideoPath;
}

sealed class ComboPartyState {
  const ComboPartyState();
}

class ComboIdle extends ComboPartyState {
  const ComboIdle();
}

class ComboCycling extends ComboPartyState {
  final List<ComboPartyDisplay> combos;
  final ComboPartyDisplay currentCombo;
  final ComboPartyDisplay finalCombo;
  final DateTime startTime;
  final DateTime lastFlip;
  final int durationMs;

  const ComboCycling({
    required this.combos,
    required this.currentCombo,
    required this.finalCombo,
    required this.startTime,
    required this.lastFlip,
    required this.durationMs,
  });

  ComboCycling copyWith({ComboPartyDisplay? currentCombo, DateTime? lastFlip}) {
    return ComboCycling(
      combos: combos,
      currentCombo: currentCombo ?? this.currentCombo,
      finalCombo: finalCombo,
      startTime: startTime,
      lastFlip: lastFlip ?? this.lastFlip,
      durationMs: durationMs,
    );
  }
}

class ComboRevealing extends ComboPartyState {
  final ComboPartyDisplay combo;

  const ComboRevealing({required this.combo});
}

class ComboRevealed extends ComboPartyState {
  final ComboPartyDisplay combo;

  const ComboRevealed({required this.combo});
}

class ComboPartyBloc extends Bloc<ComboPartyEvent, ComboPartyState> {
  final Random _random = Random();
  static const _cycleFlipBaseMs = 60;
  static const _cycleFlipMaxMs = 260;
  static const _subsystem = 'Party(Combo)';

  ComboPartyBloc() : super(const ComboIdle()) {
    on<ComboShake>(_onShake);
    on<ComboTick>(_onTick);
  }

  void _onShake(ComboShake event, Emitter<ComboPartyState> emit) {
    DiagnosticsLog.info(
      _subsystem,
      'shake received; state=${state.runtimeType} combos=${event.combos.length}',
    );
    if (event.combos.isEmpty) {
      DiagnosticsLog.warn(_subsystem, 'shake ignored: combos list is empty');
      return;
    }
    if (state is! ComboIdle && state is! ComboRevealed) {
      DiagnosticsLog.debug(
        _subsystem,
        'shake ignored: state is ${state.runtimeType}',
      );
      return;
    }

    final finalCombo = event.combos[_random.nextInt(event.combos.length)];
    final currentCombo = event.combos[_random.nextInt(event.combos.length)];
    final now = DateTime.now();

    DiagnosticsLog.info(
      _subsystem,
      'cycling → "${finalCombo.name}" (${finalCombo.moveNames.length} moves)',
    );
    emit(ComboCycling(
      combos: event.combos,
      currentCombo: currentCombo,
      finalCombo: finalCombo,
      startTime: now,
      lastFlip: now,
      durationMs: event.durationMs,
    ));
  }

  void _onTick(ComboTick event, Emitter<ComboPartyState> emit) {
    final currentState = state;
    if (currentState is ComboRevealing) {
      DiagnosticsLog.info(
        _subsystem,
        'revealing → revealed "${currentState.combo.name}"',
      );
      emit(ComboRevealed(combo: currentState.combo));
      return;
    }
    if (currentState is! ComboCycling) return;

    final elapsed = event.now.difference(currentState.startTime);
    if (elapsed.inMilliseconds >= currentState.durationMs) {
      DiagnosticsLog.info(
        _subsystem,
        'cycle expired (${elapsed.inMilliseconds}ms) → revealing "${currentState.finalCombo.name}"',
      );
      emit(ComboRevealing(combo: currentState.finalCombo));
      return;
    }

    final progress = elapsed.inMilliseconds / currentState.durationMs;
    final intervalMs = _cycleFlipBaseMs +
        ((_cycleFlipMaxMs - _cycleFlipBaseMs) * progress * progress).round();

    final sinceLastFlip = event.now.difference(currentState.lastFlip);
    if (sinceLastFlip.inMilliseconds >= intervalMs) {
      final nextCombo =
          currentState.combos[_random.nextInt(currentState.combos.length)];
      emit(currentState.copyWith(
        currentCombo: nextCombo,
        lastFlip: event.now,
      ));
    }
  }
}
