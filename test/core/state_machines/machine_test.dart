import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/state_machines/machine.dart';

// --- Test types ---

sealed class S {
  const S();
}
final class A extends S {
  const A() : super();
}
final class B extends S {
  const B({this.data = ''}) : super();
  final String data;
}
final class C extends S {
  const C() : super();
}

sealed class E {
  const E();
}
final class Go extends E {
  const Go() : super();
}
final class Back extends E {
  const Back() : super();
}
final class Forward extends E {
  const Forward() : super();
}

final class TestMachine extends Machine<S, E> {
  final List<String> log = [];

  TestMachine(super.initialState);

  @override
  S? transition(final S state, final E event) => switch ((state, event)) {
    (A(), Go()) => const B(),
    (B(), Back()) => const A(),
    (B(), Forward()) => const C(),
    (C(), Back()) => const B(),
    _ => null,
  };

  @override
  void onEntry(final S state) {
    log.add('enter:${state.runtimeType}');
  }

  @override
  void onExit(final S state) {
    log.add('exit:${state.runtimeType}');
  }
}

final class ChildMachine extends Machine<S, E> {
  ChildMachine(super.initialState);

  @override
  S? transition(final S state, final E event) => switch ((state, event)) {
    (A(), Go()) => const B(),
    (B(), Back()) => const A(),
    _ => null,
  };
}

void main() {
  group('Machine base class', () {
    test('starts with initial state', () {
      final machine = TestMachine(const A());
      expect(machine.state, isA<A>());
    });

    test('valid transition changes state', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      expect(machine.state, isA<B>());
    });

    test('invalid transition does not change state', () {
      final machine = TestMachine(const A());
      machine.send(const Back());
      expect(machine.state, isA<A>());
    });

    test('invalid transition from non-start state', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      expect(machine.state, isA<B>());

      machine.send(const Go());
      expect(machine.state, isA<B>());
    });

    test('chain of valid transitions', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      expect(machine.state, isA<B>());

      machine.send(const Forward());
      expect(machine.state, isA<C>());

      machine.send(const Back());
      expect(machine.state, isA<B>());
    });
  });

  group('Machine entry/exit hooks', () {
    test('onEntry called after transition', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      expect(machine.log, contains('exit:A'));
      expect(machine.log, contains('enter:B'));
    });

    test('onExit and onEntry order', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      final exitIndex = machine.log.indexOf('exit:A');
      final enterIndex = machine.log.indexOf('enter:B');
      expect(exitIndex, lessThan(enterIndex));
    });

    test('no hooks on invalid transition', () {
      final machine = TestMachine(const A());
      final beforeLen = machine.log.length;
      machine.send(const Back());
      expect(machine.log.length, beforeLen);
    });

    test('onExit receives current state, onEntry receives next state', () {
      final machine2 = TestMachine(const A());
      machine2.send(const Go());
      expect(machine2.log[0], 'exit:A');
      expect(machine2.log[1], 'enter:B');
    });
  });

  group('Machine hierarchical composition', () {
    test('child handles event before parent', () {
      final parent = TestMachine(const A());
      // Child starts at A, same as parent initially
      final child = ChildMachine(const A());
      parent.registerChild(child);

      parent.send(const Go());

      // Child should have handled Go from A → B
      expect(child.state, isA<B>());
      // Parent should NOT have handled it (child consumed it)
      expect(parent.state, isA<A>());
    });

    test('parent handles event when child ignores it', () {
      final parent = TestMachine(const A());
      final child = ChildMachine(const A());
      parent.registerChild(child);

      // Forward is not handled by child (child only knows Go/Back)
      parent.send(const Forward());

      // Child should have ignored it
      expect(child.state, isA<A>());
      // Parent transition: A + Forward → null (ignored too in TestMachine)
      expect(parent.state, isA<A>());
    });

    test('parent handles event when child is not in matching state', () {
      final parent = TestMachine(const A());
      final child = ChildMachine(const B());

      parent.registerChild(child);

      // Go from B is not valid for child (child: B + Go → null)
      parent.send(const Go());

      // Child ignored it (B + Go → null)
      expect(child.state, isA<B>());
      // Parent handled it: A + Go → B
      expect(parent.state, isA<B>());
    });

    test('unregister child removes delegation', () {
      final parent = TestMachine(const A());
      final child = ChildMachine(const A());
      parent.registerChild(child);
      parent.unregisterChild(child);

      parent.send(const Go());

      // Child should be unaffected
      expect(child.state, isA<A>());
      // Parent should have handled it
      expect(parent.state, isA<B>());
    });
  });

  group('Machine send handles edge cases', () {
    test('send to machine with no children', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      expect(machine.state, isA<B>());
    });

    test('rapid sends do not interleave', () {
      final machine = TestMachine(const A());
      machine.send(const Go());
      machine.send(const Forward());
      machine.send(const Back());
      // A → Go → B → Forward → C → Back → B
      expect(machine.state, isA<B>());
    });

    test('state changes type on valid transition', () {
      final machine = TestMachine(const A());
      expect(machine.state, isA<A>());
      machine.send(const Go());
      expect(machine.state, isA<B>());
      expect(machine.state, isNot(isA<A>()));
    });
  });
}
