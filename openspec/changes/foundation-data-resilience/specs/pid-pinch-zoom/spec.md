## ADDED Requirements

### Requirement: PID controller math

The system SHALL provide a `PidController` class implementing the standard PID formula:

```
output = Kp * error + Ki * integral + Kd * derivative
```

Where:
- `error` = target_scale − current_scale
- `integral` = accumulated error over time (with anti-windup clamping)
- `derivative` = rate of change of error
- `Kp`, `Ki`, `Kd` are configurable gain constants

#### Scenario: Proportional response

- **WHEN** the user pinches to zoom from scale 1.0 to 1.5 (error = 0.5) with Kp = 0.4, Ki = 0, Kd = 0
- **THEN** the output SHALL be 0.2 (0.4 × 0.5), producing a smooth 0.2 scale change

#### Scenario: Derivative damping on sudden jerk

- **WHEN** the user makes a sudden 0.3 scale jump in one frame (high derivative)
- **THEN** the derivative term SHALL oppose the rapid change, reducing the output compared to proportional-only

#### Scenario: Integral anti-windup

- **WHEN** the integral term accumulates beyond ±1.0
- **THEN** the integral SHALL be clamped to the range [-1.0, 1.0] to prevent windup

#### Scenario: Integral accumulation for sustained gesture

- **WHEN** the user maintains a steady pinch for 500ms (error stays at 0.1)
- **THEN** the integral term SHALL accumulate, gradually increasing the zoom to match the user's sustained intent

### Requirement: Default tuning constants

The `PidController` SHALL ship with default tuning constants calibrated for cinematic zoom:

- `Kp = 0.4` — moderate proportional response
- `Ki = 0.05` — slow integral accumulation
- `Kd = 0.3` — strong derivative damping

#### Scenario: Default constants are used when none specified

- **WHEN** a `PidController` is constructed with `PidController()`
- **THEN** Kp SHALL be 0.4, Ki SHALL be 0.05, Kd SHALL be 0.3

#### Scenario: Custom constants are supported

- **WHEN** a `PidController` is constructed with `PidController(kp: 0.6, ki: 0.1, kd: 0.2)`
- **THEN** Kp SHALL be 0.6, Ki SHALL be 0.1, Kd SHALL be 0.2

### Requirement: Time-delta-aware updates

The `update()` method SHALL accept a `dt` parameter (time delta in seconds since last update) and scale the integral and derivative terms accordingly.

#### Scenario: Frame-rate independent behavior

- **WHEN** `update()` is called at 30fps (dt ≈ 0.033) vs 60fps (dt ≈ 0.017)
- **THEN** the integral accumulation SHALL be proportional to elapsed time, producing consistent zoom feel regardless of frame rate

### Requirement: Video editor integration

The video editor's `InteractiveViewer.onInteractionUpdate` SHALL route gesture scale changes through the `PidController` instead of applying them directly to the `TransformationController`.

#### Scenario: Pinch zoom is filtered

- **WHEN** the user pinches in the video editor trim mode
- **THEN** the raw gesture scale delta SHALL be passed to `PidController.update()` and the filtered output SHALL update the `TransformationController.value`

#### Scenario: Micro-twitches are dampened

- **WHEN** the user's fingers produce small unintentional scale fluctuations (|delta| < 0.02)
- **THEN** the derivative term SHALL dampen these, producing negligible transformation change

#### Scenario: Intentional zoom is responsive

- **WHEN** the user performs a deliberate pinch from 1.0 to 2.0 over 300ms
- **THEN** the zoom SHALL follow smoothly with no perceptible lag

#### Scenario: Reset on interaction end

- **WHEN** `onInteractionEnd` fires (user lifts fingers)
- **THEN** the `PidController`'s integral accumulator SHALL be reset to 0 to prevent stale accumulated error affecting the next gesture

### Requirement: Pure function for testability

The `PidController` SHALL be a pure Dart class with no Flutter dependencies, making it unit-testable without widget or platform setup.

#### Scenario: Unit testable

- **WHEN** a unit test calls `PidController().update(1.5, 1.0, 0.016)`
- **THEN** the test SHALL receive a deterministic numeric output and SHALL NOT require `TestWidgetsFlutterBinding` or any platform channel mocking
