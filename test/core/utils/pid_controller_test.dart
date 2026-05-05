import 'package:flutter_test/flutter_test.dart';

import 'package:breakdex/core/utils/pid_controller.dart';

void main() {
  group('PidController', () {
    test('produces proportional response to error', () {
      final pid = PidController(kp: 0.5, ki: 0, kd: 0);
      final output = pid.update(1.0, 0.0, 0.016);
      expect(output, closeTo(0.5, 0.001));
    });

    test('derivative damps sudden jerk', () {
      // No derivative effect on first call (previous error = 0)
      final pid = PidController(kp: 0.4, ki: 0, kd: 0.3);

      // First step: error = 0.5, no derivative contribution
      final out1 = pid.update(1.5, 1.0, 0.016);
      // P: 0.4 * 0.5 = 0.2, D: (0.5 - 0) / 0.016 * 0.3 = 9.375
      // Total ≈ 9.575
      expect(out1, greaterThan(9.0));

      // Second step (sudden jerk back): error = -0.3, large negative derivative
      final out2 = pid.update(0.7, 1.0, 0.016);
      // P: 0.4 * (-0.3) = -0.12, D: (-0.3 - 0.5) / 0.016 * 0.3 = -15.0
      // Total ≈ -15.12 — strongly negative, damping the jerk
      expect(out2, lessThan(-12.0));
    });

    test('integral accumulates over sustained error', () {
      final pid = PidController(kp: 0, ki: 0.1, kd: 0);

      // Apply sustained setpoint error over multiple frames
      var output = pid.update(2.0, 1.0, 0.016); // err=1.0, integral += 0.016
      expect(output, closeTo(0.0 + 0.1 * 0.016, 0.0001));

      output = pid.update(2.0, 1.0, 0.016); // integral += 0.032
      expect(output, closeTo(0.1 * 0.032, 0.001));
    });

    test('integral anti-windup clamps within [-1, 1]', () {
      final pid = PidController(kp: 0, ki: 0.1, kd: 0);

      // Large sustained error over many frames
      for (var i = 0; i < 200; i++) {
        pid.update(100.0, 0.0, 0.016);
      }

      // Integral should be clamped to 1.0, so output = ki * 1.0 = 0.1
      final output = pid.update(100.0, 0.0, 0.016);
      expect(output, closeTo(0.1, 0.001));
    });

    test('reset clears integral and previous error', () {
      final pid = PidController();

      pid.update(2.0, 1.0, 0.016); // accumulate error
      pid.update(2.0, 1.0, 0.016); // more accumulation
      pid.reset();

      // After reset, behaves like fresh controller with defaults: Kp=0.4, Ki=0.05, Kd=0.3
      final output = pid.update(1.5, 1.0, 0.016);
      // P: 0.4*0.5=0.2, D: 0.3*(0.5/0.016)=9.375, I: 0.05*0.5*0.016=0.0004
      expect(output, closeTo(9.5754, 0.01));
    });

    test('consistent behavior at 30fps vs 60fps dt', () {
      // At 60fps, dt ≈ 0.016; at 30fps, dt ≈ 0.033
      // Proportional should be same, derivative and integral scale accordingly

      final pid60 = PidController(kp: 0.5, ki: 0.05, kd: 0.2);
      final out60 = pid60.update(1.1, 1.0, 0.016);
      // P: 0.05, I: 0.05*0.1*0.016=0.00008, D: (0.1-0)/0.016*0.2=1.25
      // Total ≈ 1.30008

      final pid30 = PidController(kp: 0.5, ki: 0.05, kd: 0.2);
      final out30 = pid30.update(1.1, 1.0, 0.033);
      // P: 0.05, I: 0.05*0.1*0.033=0.000165, D: (0.1-0)/0.033*0.2=0.606
      // Total ≈ 0.656

      // Derivative response should be stronger at higher frame rates (smaller dt)
      // because the same error over smaller dt = larger rate of change
      expect(out60, greaterThan(out30));

      // But proportional contribution should be identical
      final pidP = PidController(kp: 0.5, ki: 0, kd: 0);
      final pOut60 = pidP.update(1.1, 1.0, 0.016);
      final pOut30 = pidP.update(1.1, 1.0, 0.033);
      expect(pOut60, closeTo(pOut30, 0.001));
    });

    test('default tuning constants match spec', () {
      final pid = PidController();
      final output = pid.update(1.5, 1.0, 0.016);
      // P: 0.4*0.5=0.2, D: 0.3*(0.5/0.016)=9.375, I: 0.05*0.5*0.016=0.0004
      expect(output, closeTo(9.575, 0.01));
      pid.reset();
    });

    test('zero dt produces output without NaN (safeDt fallback)', () {
      final pid = PidController(kp: 0.4, ki: 0.05, kd: 0.3);
      final output = pid.update(1.5, 1.0, 0.0);
      expect(output, isNotNaN);
      expect(output.isFinite, isTrue);
    });
  });
}
