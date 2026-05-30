import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../utils/diagnostics.dart';

/// Detects an intentional "swing" motion using accelerometer data.
///
/// Unlike a simple shake, a swing requires a sustained acceleration arc,
/// making it resilient to accidental pickups or table vibrations.
class SwingDetector {
  SwingDetector({
    this.threshold = 22.0,
    this.windowSize = const Duration(milliseconds: 600),
    required this.onSwing,
  });

  final double threshold;
  final Duration windowSize;
  final VoidCallback onSwing;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<_MomentumPoint> _window = [];
  bool _locked = false;
  DateTime _lastTrigger = DateTime(2000);

  int _eventCount = 0;
  int _aboveHalfThresholdCount = 0;

  void start() {
    DiagnosticsLog.info('SwingDetector', 'listener started — threshold=$threshold');
    _eventCount = 0;
    _aboveHalfThresholdCount = 0;
    _subscription?.cancel();
    _subscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_onEvent);
  }

  void stop() {
    DiagnosticsLog.info('SwingDetector',
        'listener stopped — totalEvents=$_eventCount aboveHalf=$_aboveHalfThresholdCount');
    _subscription?.cancel();
    _subscription = null;
    _window.clear();
    _locked = false;
    _lastTrigger = DateTime(2000);
  }

  void _onEvent(UserAccelerometerEvent event) {
    _eventCount++;
    final now = DateTime.now();
    if (_locked || now.difference(_lastTrigger) < const Duration(seconds: 1)) {
      return;
    }

    // 1. Clean window
    _window.removeWhere((p) => now.difference(p.time) > windowSize);

    // 2. Add current point (userAccelerometer already excludes gravity)
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    _window.add(_MomentumPoint(event, magnitude, now));

    if (_eventCount % 50 == 0) {
      DiagnosticsLog.info('SwingDetector',
          'listener alive — ${_eventCount} events, maxRecent=${magnitude.toStringAsFixed(1)}, '
          'threshold=$threshold, aboveHalf=$_aboveHalfThresholdCount');
    }

    // 3. Analyze for "Swing"
    if (_window.length < 5) return;

    double maxMagnitude = 0;
    for (final p in _window) {
      if (p.magnitude > maxMagnitude) maxMagnitude = p.magnitude;
    }

    final effectiveThreshold = threshold;
    if (maxMagnitude > effectiveThreshold * 0.5) {
      _aboveHalfThresholdCount++;
    }

    if (maxMagnitude > effectiveThreshold * 0.6 && maxMagnitude < effectiveThreshold) {
      DiagnosticsLog.debug('SwingDetector',
          'near swing — maxMag=${maxMagnitude.toStringAsFixed(1)} threshold=$effectiveThreshold');
      _provideEasingHaptic(maxMagnitude / effectiveThreshold);
    }

    if (maxMagnitude > effectiveThreshold) {
      DiagnosticsLog.info('SwingDetector',
          'SWING TRIGGERED — maxMag=${maxMagnitude.toStringAsFixed(1)} threshold=$effectiveThreshold');
      _trigger();
    }
  }

  int _lastHapticMs = 0;
  void _provideEasingHaptic(double intensity) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < 150) return;
    _lastHapticMs = now;

    if (intensity > 0.8) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _trigger() {
    _locked = true;
    _lastTrigger = DateTime.now();
    _window.clear();
    
    // Final satisfying trigger haptic
    HapticFeedback.heavyImpact();
    
    onSwing();
    
    // Unlock after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _locked = false;
    });
  }
}

class _MomentumPoint {
  final UserAccelerometerEvent event;
  final double magnitude;
  final DateTime time;
  _MomentumPoint(this.event, this.magnitude, this.time);
}
