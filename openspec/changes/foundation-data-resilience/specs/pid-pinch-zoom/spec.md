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

- **WHEN** the user pinches to zoom from scale 1.0 to 1.5 (error = 0.5) with Kp = 0.2, Ki = 0, Kd = 0
- **THEN** the output SHALL be 0.1 (0.2 × 0.5), producing a smooth 0.1 scale change

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

- `Kp = 0.2` — gentle proportional tracking (reaches 63% of target in ~5 frames at 60fps)
- `Ki = 0.03` — slow integral accumulation for sustained pinch holds
- `Kd = 0.003` — light derivative damping to smooth sudden finger movements without introducing perceptible lag

#### Scenario: Default constants are used when none specified

- **WHEN** a `PidController` is constructed with `PidController()`
- **THEN** Kp SHALL be 0.2, Ki SHALL be 0.03, Kd SHALL be 0.003

#### Scenario: Custom constants are supported

- **WHEN** a `PidController` is constructed with `PidController(kp: 0.6, ki: 0.1, kd: 0.2)`
- **THEN** Kp SHALL be 0.6, Ki SHALL be 0.1, Kd SHALL be 0.2

### Requirement: Time-delta-aware updates

The `update()` method SHALL accept a `dt` parameter (time delta in seconds since last update) and scale the integral and derivative terms accordingly.

#### Scenario: Frame-rate independent behavior

- **WHEN** `update()` is called at 30fps (dt ≈ 0.033) vs 60fps (dt ≈ 0.017)
- **THEN** the integral accumulation SHALL be proportional to elapsed time, producing consistent zoom feel regardless of frame rate

### Requirement: Video editor integration

The video editor's `InteractiveViewer.onInteractionStart` SHALL capture the current absolute scale as `gestureBaseScale`. `onInteractionUpdate` SHALL map gesture-relative `details.scale` to an absolute target (`gestureBaseScale × details.scale`), route it through the `PidController`, and apply the PID output as a correction delta (not an absolute value) to the `TransformationController`.

#### Scenario: Gesture scale is mapped to absolute coordinates

- **WHEN** the user starts a pinch gesture with the video at scale 2.0 and pinches to a relative scale of 1.3
- **THEN** the target scale SHALL be 2.0 × 1.3 = 2.6 (in absolute viewport coordinates), not 1.3

#### Scenario: Pinch zoom is filtered through PID as a delta

- **WHEN** the PID output for a given frame is 0.05
- **THEN** the new scale SHALL be `currentScale + 0.05`, not the PID output used directly as absolute scale

#### Scenario: Dead zone filters micro-twitches

- **WHEN** the user's fingers produce an absolute target change of |delta| < 0.008
- **THEN** the transform SHALL NOT be updated for that frame

#### Scenario: Rate limit prevents jarring jumps

- **WHEN** the PID output exceeds 0.06 in a single frame
- **THEN** the applied delta SHALL be clamped to 0.06

#### Scenario: Zoom-in-only enforcement

- **WHEN** the computed target scale is below the current scale (user is pinching outward)
- **THEN** the target SHALL be clamped to `currentScale`, preventing zoom-out

#### Scenario: Edge containment preserves full content visibility

- **WHEN** the PID-corrected transform would show empty space at any viewport edge
- **THEN** the translation SHALL be clamped so the video content fills the viewport edge-to-edge with no gaps

#### Scenario: Micro-twitches are dampened

- **WHEN** the user's fingers produce small unintentional scale fluctuations (|delta| < 0.02)
- **THEN** the dead zone and derivative term SHALL dampen these, producing negligible transformation change

#### Scenario: Intentional zoom is responsive

- **WHEN** the user performs a deliberate pinch from 1.0 to 2.0 over 300ms
- **THEN** the zoom SHALL follow smoothly with no perceptible lag and reach the target within ~250ms

#### Scenario: Reset on interaction end

- **WHEN** `onInteractionEnd` fires (user lifts fingers)
- **THEN** the `PidController`'s integral accumulator SHALL be reset to 0 to prevent stale accumulated error affecting the next gesture

### Requirement: Pure function for testability

The `PidController` SHALL be a pure Dart class with no Flutter dependencies, making it unit-testable without widget or platform setup.

#### Scenario: Unit testable

- **WHEN** a unit test calls `PidController().update(1.5, 1.0, 0.016)`
- **THEN** the test SHALL receive a deterministic numeric output and SHALL NOT require `TestWidgetsFlutterBinding` or any platform channel mocking
