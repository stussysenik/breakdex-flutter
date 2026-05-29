import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:breakdex/core/services/swing_detector.dart';

void main() {
  late StreamController<UserAccelerometerEvent> sensorController;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    sensorController = StreamController<UserAccelerometerEvent>.broadcast();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (call) async {
        if (call.method == 'isSensorAvailable') {
          return true;
        }
        return null;
      },
    );

    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/sensors/user_accel'),
      MockStreamHandler.inline(onListen: (args, sink) {
        sensorController.stream.listen(
          (event) => sink.success([
            event.x,
            event.y,
            event.z,
            event.timestamp.microsecondsSinceEpoch.toDouble(),
          ]),
        );
      }),
    );
  });

  tearDown(() {
    sensorController.close();
  });

  group('SwingDetector threshold behavior', () {
    test('triggers when magnitude exceeds threshold of 22.0', () async {
      int swingCount = 0;
      final detector = SwingDetector(
        threshold: 22.0,
        onSwing: () => swingCount++,
      );

      detector.start();

      final t0 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          25.0, 0.0, 0.0,
          t0.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      detector.stop();
      expect(swingCount, 1);
    });

    test('does NOT trigger when magnitude stays below threshold of 22.0',
        () async {
      int swingCount = 0;
      final detector = SwingDetector(
        threshold: 22.0,
        onSwing: () => swingCount++,
      );

      detector.start();

      final t0 = DateTime.now();
      for (int i = 0; i < 10; i++) {
        sensorController.add(UserAccelerometerEvent(
          10.0, 3.0, 2.0,
          t0.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      detector.stop();
      expect(swingCount, 0);
    });

    test('does NOT trigger with gentle movement at magnitude ~15', () async {
      int swingCount = 0;
      final detector = SwingDetector(
        threshold: 22.0,
        onSwing: () => swingCount++,
      );

      detector.start();

      final t0 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          15.0, 0.0, 0.0,
          t0.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      detector.stop();
      expect(swingCount, 0);
    });
  });

  group('SwingDetector lockout mechanism', () {
    test('locks after trigger, recovers after cooldown expires', () async {
      int swingCount = 0;
      final detector = SwingDetector(
        threshold: 22.0,
        onSwing: () => swingCount++,
      );

      detector.start();

      // First swing
      final t0 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          25.0, 0.0, 0.0,
          t0.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 50));
      expect(swingCount, 1);

      // Wait past the 1-second cooldown
      await Future.delayed(const Duration(seconds: 2));

      // Second swing — should trigger
      final t2 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          25.0, 0.0, 0.0,
          t2.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      detector.stop();
      expect(swingCount, 2);
    });

    test('stop fully resets lock state and cooldown', () async {
      int swingCount = 0;
      final detector = SwingDetector(
        threshold: 22.0,
        onSwing: () => swingCount++,
      );

      detector.start();

      // Trigger once
      final t0 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          25.0, 0.0, 0.0,
          t0.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 50));
      expect(swingCount, 1);

      // Stop and restart
      detector.stop();
      detector.start();

      // Should trigger immediately after restart (cooldown reset)
      final t1 = DateTime.now();
      for (int i = 0; i < 5; i++) {
        sensorController.add(UserAccelerometerEvent(
          25.0, 0.0, 0.0,
          t1.add(Duration(milliseconds: i * 100)),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      detector.stop();
      expect(swingCount, 2);
    });
  });
}
