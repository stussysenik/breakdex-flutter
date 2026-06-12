
import 'package:flutter_test/flutter_test.dart' hide Timeout;

import 'package:breakdex/core/utils/loading_state_machine.dart';

void main() {
  group('LoadingStateMachine transitions', () {
    test('Idle -> Loading on start', () {
      const state = Idle<String>();
      final next = state.transition(LoadingEvent.start);
      expect(next, isA<Loading<String>>());
    });

    test('Loading -> Downloading on progress', () {
      const state = Loading<String>();
      final next = state.transition(LoadingEvent.progress(0.47));
      expect(next, isA<Downloading<String>>());
      expect((next as Downloading<String>).progress, 0.47);
    });

    test('Loading -> Ready on complete', () {
      const state = Loading<String>();
      final next = state.transition(LoadingEvent.complete('data'));
      expect(next, isA<Ready<String>>());
      expect((next as Ready<String>).data, 'data');
    });

    test('Loading -> Timeout on timeout', () {
      const state = Loading<String>();
      final next = state.transition(LoadingEvent.timeout);
      expect(next, isA<Timeout<String>>());
    });

    test('Downloading -> Timeout on timeout', () {
      const state = Downloading<String>(progress: 0.5);
      final next = state.transition(LoadingEvent.timeout);
      expect(next, isA<Timeout<String>>());
    });

    test('Loading -> Error on fail', () {
      const state = Loading<String>();
      final next = state.transition(LoadingEvent.fail('bad'));
      expect(next, isA<Error<String>>());
      expect((next as Error<String>).message, 'bad');
    });

    test('Downloading -> Error on fail', () {
      const state = Downloading<String>(progress: 0.3);
      final next = state.transition(LoadingEvent.fail('bad'));
      expect(next, isA<Error<String>>());
    });

    test('Timeout -> Retrying on retry', () {
      const state = Timeout<String>(after: Duration(seconds: 30));
      final next = state.transition(LoadingEvent.retry);
      expect(next, isA<Retrying<String>>());
      expect((next as Retrying<String>).attempt, 1);
    });

    test('Error (retryable) -> Retrying on retry', () {
      const state = Error<String>(message: 'fail', retryable: true);
      final next = state.transition(LoadingEvent.retry);
      expect(next, isA<Retrying<String>>());
    });

    test('Retrying -> Loading on start if under max', () {
      const state = Retrying<String>(attempt: 1, maxAttempts: 3);
      final next = state.transition(LoadingEvent.start);
      expect(next, isA<Loading<String>>());
    });

    test('Idle stays Idle on irrelevant events', () {
      const state = Idle<String>();
      expect(state.transition(LoadingEvent.complete('x')), isA<Idle<String>>());
      expect(state.transition(LoadingEvent.timeout), isA<Idle<String>>());
    });

    test('Ready stays Ready on irrelevant events', () {
      const state = Ready<String>(data: 'x');
      expect(state.transition(LoadingEvent.start), isA<Ready<String>>());
    });
  });

  group('LoadingStateMachine error handling', () {
    test('non-retryable Error stays Error on retry', () {
      const state = Error<String>(message: 'fatal', retryable: false);
      final next = state.transition(LoadingEvent.retry);
      expect(next, isA<Error<String>>());
    });

    test('max retries exhausted produces non-retryable Error', () {
      const state = Retrying<String>(attempt: 3, maxAttempts: 3);
      final next = state.transition(LoadingEvent.start);
      expect(next, isA<Error<String>>());
      expect((next as Error<String>).retryable, false);
      expect(next.message, 'Max retries exhausted');
    });
  });

  group('LoadingStateController', () {
    test('broadcasts state changes via stream', () {
      final controller = LoadingStateController<String>();
      expect(controller.state, isA<Idle<String>>());

      controller.send(LoadingEvent.start);
      expect(controller.state, isA<Loading<String>>());

      controller.send(LoadingEvent.fail('oops'));
      expect(controller.state, isA<Error<String>>());

      controller.dispose();
    });

    test('enforces progress monotonicity', () {
      final controller = LoadingStateController<String>();
      controller.send(LoadingEvent.start);
      controller.send(LoadingEvent.progress(0.6));
      expect((controller.state as Downloading<String>).progress, 0.6);

      controller.send(LoadingEvent.progress(0.3));
      expect((controller.state as Downloading<String>).progress, 0.6);

      controller.dispose();
    });

    test('stream emits on state changes', () async {
      final controller = LoadingStateController<String>();
      final events = <LoadingStateMachine<String>>[];
      controller.stream.listen(events.add);

      controller.send(LoadingEvent.start);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.send(LoadingEvent.complete('done'));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.length, 2);
      expect(events[0], isA<Loading<String>>());
      expect(events[1], isA<Ready<String>>());

      controller.dispose();
    });
  });

  group('LoadingStateMachine exhaustiveness', () {
    test('map requires all 7 states', () {
      const state = Idle<String>();
      final result = state.map(
        idle: (_) => 'idle',
        loading: (_) => 'loading',
        downloading: (_) => 'downloading',
        ready: (_) => 'ready',
        timeout: (_) => 'timeout',
        error: (_) => 'error',
        retrying: (_) => 'retrying',
      );
      expect(result, 'idle');
    });

    test('Downloading map includes progress', () {
      const state = Downloading<String>(progress: 0.75);
      final result = state.map(
        idle: (_) => '',
        loading: (_) => '',
        downloading: (final d) => '${d.progress}',
        ready: (_) => '',
        timeout: (_) => '',
        error: (_) => '',
        retrying: (_) => '',
      );
      expect(result, '0.75');
    });
  });
}
