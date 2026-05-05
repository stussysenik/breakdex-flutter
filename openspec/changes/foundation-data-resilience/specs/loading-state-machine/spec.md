## ADDED Requirements

### Requirement: Sealed state hierarchy

The system SHALL provide a `LoadingStateMachine<T>` sealed class hierarchy with the following states:

- `Idle` — no operation in progress
- `Loading` — operation started, no progress data available yet
- `Downloading(progress: double)` — operation in progress with 0.0–1.0 completion
- `Ready(data: T)` — operation completed successfully with typed result
- `Timeout(after: Duration)` — operation exceeded its deadline
- `Error(message: String, retryable: bool)` — operation failed, may or may not be retryable
- `Retrying(attempt: int, maxAttempts: int)` — retry in progress

#### Scenario: State machine lifecycle

- **WHEN** a new `LoadingStateMachine<void>` is created
- **THEN** its state SHALL be `Idle`

#### Scenario: Start transition

- **WHEN** `Idle` receives a `Start` event
- **THEN** the state SHALL transition to `Loading`

#### Scenario: Progress event

- **WHEN** `Loading` receives a `Progress(0.47)` event
- **THEN** the state SHALL transition to `Downloading(0.47)`

#### Scenario: Progress monotonically increases

- **WHEN** `Downloading(0.3)` receives a `Progress(0.2)` event
- **THEN** the state SHALL remain `Downloading(0.3)` (progress never decreases)

#### Scenario: Complete transition

- **WHEN** `Loading` or `Downloading` receives a `Complete(data)` event
- **THEN** the state SHALL transition to `Ready(data)`

#### Scenario: Timeout transition

- **WHEN** `Loading` or `Downloading` receives a `Timeout(duration)` event
- **THEN** the state SHALL transition to `Timeout(duration)`

#### Scenario: Error transition

- **WHEN** `Loading` or `Downloading` receives a `Fail(message, retryable: true)` event
- **THEN** the state SHALL transition to `Error(message, retryable: true)`

#### Scenario: Retry from timeout

- **WHEN** `Timeout` receives a `Retry` event and `maxAttempts` is not yet exceeded
- **THEN** the state SHALL transition to `Retrying(attempt: 1, maxAttempts: 3)`

#### Scenario: Retry from error (retryable)

- **WHEN** `Error(message, retryable: true)` receives a `Retry` event
- **THEN** the state SHALL transition to `Retrying` then automatically to `Loading`

#### Scenario: Retry from error (non-retryable)

- **WHEN** `Error(message, retryable: false)` receives a `Retry` event
- **THEN** the state SHALL remain `Error` — non-retryable errors cannot transition to `Retrying`

#### Scenario: Max retries exhausted

- **WHEN** `Retrying(attempt: 3, maxAttempts: 3)` would transition to retry again
- **THEN** the state SHALL transition to `Error` with a "Max retries exhausted" message

#### Scenario: Exhaustive switch

- **WHEN** any code pattern-matches on `LoadingStateMachine` state
- **THEN** the Dart compiler SHALL require all 7 states to be handled (sealed class exhaustiveness)

### Requirement: Reactive state observation

The `LoadingStateMachine` SHALL expose a `Stream<LoadingStateMachine<T>>` of state changes, emitting the new state on every transition.

Consumers (Riverpod providers, widgets) SHALL subscribe to this stream for reactive UI updates.

#### Scenario: Stream emits on transition

- **WHEN** a state machine in `Idle` transitions to `Loading`
- **THEN** the stream SHALL emit `Loading` state

#### Scenario: Stream does not emit on same state

- **WHEN** a state machine in `Downloading(0.5)` receives a `Progress(0.5)` event
- **THEN** the stream SHALL NOT emit (state unchanged)

### Requirement: Video service integration

The `VideoService` SHALL use `LoadingStateMachine` for:
1. Video file existence checks (iCloud download status)
2. Thumbnail generation requests
3. Asset import from Photos library

#### Scenario: Video file check with iCloud download

- **WHEN** `VideoService.checkVideoFile()` is called for a video that requires iCloud download
- **THEN** the state machine SHALL transition: `Idle → Loading → Downloading(0.0...1.0) → Ready` as the file materializes

#### Scenario: Video file check timeout

- **WHEN** `VideoService.checkVideoFile()` is called and the video does not materialize within the timeout period
- **THEN** the state machine SHALL transition: `Idle → Loading → Timeout → Retrying → Loading` for up to `maxAttempts` attempts, then `Error`

#### Scenario: Thumbnail generation progress

- **WHEN** `ThumbnailLoadCoordinator` is loading a thumbnail
- **THEN** the state machine SHALL expose `Loading → Ready` for cache hits and `Loading → Downloading(progress) → Ready` for generation

### Requirement: UI shell integration

The `VideoPlayerWidget` and video editor SHALL consume `LoadingStateMachine` state to render:

- `Idle`: placeholder thumbnail
- `Loading`: shimmer/skeleton
- `Downloading(p)`: progress bar with percentage
- `Ready`: video player or full thumbnail
- `Timeout`: "Taking longer than expected" with retry button
- `Error(msg, retryable)`: error message, retry button if retryable
- `Retrying(n, max)`: "Retrying (n/max)" indicator

#### Scenario: Downloading shows progress

- **WHEN** a video is downloading with state `Downloading(0.65)`
- **THEN** the UI SHALL display a progress indicator at 65%

#### Scenario: Timeout shows retry option

- **WHEN** a video check times out with state `Timeout`
- **THEN** the UI SHALL display a retry button that dispatches a `Retry` event

#### Scenario: Ready shows player

- **WHEN** the state is `Ready(videoPath)`
- **THEN** the UI SHALL display the video player initialized with `videoPath`
