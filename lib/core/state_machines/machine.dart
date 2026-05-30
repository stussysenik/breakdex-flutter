import 'package:flutter/foundation.dart';
import '../utils/diagnostics.dart';

/// Zero-dependency state machine base class.
///
/// [S] is a sealed class hierarchy of states (data-only, immutable).
/// [E] is a sealed class hierarchy of events (user intents + async results).
///
/// The transition function is `transition(S, E) -> S?` — pure, no side effects.
/// Side effects execute in [onEntry] / [onExit] hooks after state changes.
///
/// Override [diagnosticsLabel] to give this machine a subsystem name for
/// structured diagnostic logging. Defaults to `S` type name.
///
/// ```dart
/// final class MyMachine extends Machine<MyState, MyEvent> {
///   MyMachine(super.initialState);
///
///   @override
///   String get diagnosticsLabel => 'MyMachine';
///
///   @override
///   MyState? transition(MyState state, MyEvent event) => switch ((state, event)) {
///     (Idle(), TapAction()) => Doing(),
///     (Doing(), Cancel()) => Idle(),
///     _ => null,
///   };
/// }
/// ```
abstract class Machine<S, E> {
  Machine(this._state);

  S _state;

  /// The current state. Read by the UI to determine what to render.
  S get state => _state;

  /// Subsystem label for diagnostic logging. Override to customize.
  String get diagnosticsLabel => '$S';

  /// Child machines that receive events before this machine.
  final List<Machine<dynamic, E>> children = [];

  /// Sends an event to the machine. If a child handles it, the child
  /// transitions. Otherwise, this machine's [transition] is called.
  void send(E event) {
    for (final child in children) {
      final childNext = child.transition(child._state, event);
      if (childNext != null) {
        child.onExit(child._state);
        child._state = childNext;
        child.onEntry(child._state);
        return;
      }
    }

    final next = transition(_state, event);
    if (next == null) {
      if (kDebugMode) {
        DiagnosticsLog.debug(
          diagnosticsLabel,
          '↓ ignored ${_eventName(event)} @ ${_stateName(_state)}',
        );
      }
      return;
    }

    if (kDebugMode) {
      DiagnosticsLog.debug(
        diagnosticsLabel,
        '${_stateName(_state)} → ${_stateName(next)} ∵ ${_eventName(event)}',
      );
    }

    onExit(_state);
    _state = next;
    onEntry(_state);
  }

  static String _stateName(Object? s) =>
      s?.runtimeType.toString() ?? 'null';

  static String _eventName(Object? e) {
    final name = e?.runtimeType.toString() ?? 'null';
    if (e case final dynamic ee when ee.runtimeType.toString() != name) {
      return name;
    }
    return name;
  }

  /// Pure transition function. Returns the next state, or `null` if the
  /// event is invalid in the current state (identity transition — ignored).
  S? transition(S state, E event);

  /// Called after the machine enters a new state. Override to execute
  /// side effects (DB writes, API calls, navigation). If the side effect
  /// is async, call [send] with a result event when it completes.
  void onEntry(S state) {}

  /// Called before the machine leaves the current state. Override to
  /// execute cleanup (dismiss overlays, cancel timers).
  void onExit(S state) {}

  /// Registers a child machine. Child machines receive events before
  /// this machine. If a child handles an event, this machine won't see it.
  void registerChild<S2, E2 extends E>(Machine<S2, E2> child) {
    children.add(child);
  }

  /// Removes a previously registered child machine.
  void unregisterChild(Machine<dynamic, E> child) {
    children.remove(child);
  }
}
