import 'dart:async';

sealed class LoadingStateMachine<T> {
  const LoadingStateMachine();

  LoadingStateMachine<T> transition(final LoadingEvent event) {
    return switch ((this, event.type)) {
      (Idle(), 'start') => const Loading(),
      (Loading(), 'progress') => Downloading(progress: event.progressValue!),
      (Loading(), 'complete') => Ready(data: event.data),
      (Loading() || Downloading(), 'timeout') => _timeout,
      (Loading() || Downloading(), 'fail') =>
        Error(message: event.errorMessage!, retryable: event.retryable!),
      (Timeout() || Error(), 'retry') => _currentRetrying(event),
      (Retrying(attempt: final a, maxAttempts: final m), 'start') =>
        a < m ? const Loading() : _maxRetriesExhausted,
      _ => this,
    };
  }

  LoadingStateMachine<T> get _timeout => const Timeout(after: Duration(seconds: 30));
  LoadingStateMachine<T> get _maxRetriesExhausted =>
      const Error(message: 'Max retries exhausted', retryable: false);

  LoadingStateMachine<T> _currentRetrying(final LoadingEvent event) {
    final stateRetryable = switch (this) {
      Error(retryable: final r) => r,
      _ => true,
    };
    if (event.retryable == false || !stateRetryable) return this;
    final currentAttempt = switch (this) {
      Retrying(attempt: final a) => a,
      _ => 0,
    };
    final maxAttempts = switch (this) {
      Retrying(maxAttempts: final m) => m,
      _ => 3,
    };
    if (currentAttempt >= maxAttempts) return _maxRetriesExhausted;
    return Retrying(attempt: currentAttempt + 1, maxAttempts: maxAttempts);
  }

  R map<R>({
    required final R Function(Idle<T>) idle,
    required final R Function(Loading<T>) loading,
    required final R Function(Downloading<T>) downloading,
    required final R Function(Ready<T>) ready,
    required final R Function(Timeout<T>) timeout,
    required final R Function(Error<T>) error,
    required final R Function(Retrying<T>) retrying,
  }) {
    return switch (this) {
      Idle() => idle(this as Idle<T>),
      Loading() => loading(this as Loading<T>),
      Downloading() => downloading(this as Downloading<T>),
      Ready() => ready(this as Ready<T>),
      Timeout() => timeout(this as Timeout<T>),
      Error() => error(this as Error<T>),
      Retrying() => retrying(this as Retrying<T>),
    };
  }
}

class Idle<T> extends LoadingStateMachine<T> {
  const Idle();
}

class Loading<T> extends LoadingStateMachine<T> {
  const Loading();
}

class Downloading<T> extends LoadingStateMachine<T> {
  const Downloading({required this.progress});

  final double progress;
}

class Ready<T> extends LoadingStateMachine<T> {
  const Ready({required this.data});

  final dynamic data;
}

class Timeout<T> extends LoadingStateMachine<T> {
  const Timeout({required this.after});

  final Duration after;
}

class Error<T> extends LoadingStateMachine<T> {
  const Error({required this.message, required this.retryable});

  final String message;
  final bool retryable;
}

class Retrying<T> extends LoadingStateMachine<T> {
  const Retrying({required this.attempt, required this.maxAttempts});

  final int attempt;
  final int maxAttempts;
}

class LoadingEvent {
  const LoadingEvent._(
    this.type, {
    this.progressValue,
    this.data,
    this.errorMessage,
    this.retryable,
  });

  static const start = LoadingEvent._('start');
  static LoadingEvent progress(final double p) =>
      LoadingEvent._('progress', progressValue: p);
  static LoadingEvent complete(final dynamic data) =>
      LoadingEvent._('complete', data: data);
  static const timeout = LoadingEvent._('timeout');
  static LoadingEvent fail(final String msg, {final bool retryable = true}) =>
      LoadingEvent._('fail', errorMessage: msg, retryable: retryable);
  static const retry = LoadingEvent._('retry');
  static const reset = LoadingEvent._('reset');

  final String type;
  final double? progressValue;
  final dynamic data;
  final String? errorMessage;
  final bool? retryable;
}

class LoadingStateController<T> {
  LoadingStateController({final int maxAttempts = 3})
    : _maxAttempts = maxAttempts,
      _state = const Idle();

  final int _maxAttempts;
  final StreamController<LoadingStateMachine<T>> _controller =
      StreamController<LoadingStateMachine<T>>.broadcast();

  LoadingStateMachine<T> _state;
  double _lastProgress = 0;

  LoadingStateMachine<T> get state => _state;
  Stream<LoadingStateMachine<T>> get stream => _controller.stream;

  void send(final LoadingEvent event) {
    final next = switch (event.type) {
      'retry' => _state.transition(LoadingEvent._('retry', retryable: _isRetryable)),
      'progress' => _withMonotonicProgress(event),
      _ => _state.transition(event),
    };
    if (next != _state) {
      _state = next;
      _controller.add(next);
    }
  }

  void dispose() {
    _controller.close();
  }

  bool get _isRetryable {
    return switch (_state) {
      Error(retryable: final r) => r,
      Timeout() => true,
      _ => false,
    };
  }

  LoadingStateMachine<T> _withMonotonicProgress(final LoadingEvent event) {
    final p = event.progressValue ?? 0;
    if (p < _lastProgress) {
      return Downloading(progress: _lastProgress);
    }
    _lastProgress = p;
    return _state.transition(event);
  }
}
