import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects an intentional "swing" motion using accelerometer data.
///
/// Unlike a simple shake, a swing requires a sustained acceleration arc,
/// making it resilient to accidental pickups or table vibrations.
class SwingDetector {
  SwingDetector({
    this.threshold = 22.0, // Higher than simple shake
    this.windowSize = const Duration(milliseconds: 600),
    this.minSwingArc = 12.0,
    required this.onSwing,
  });

  final double threshold;
  final Duration windowSize;
  final double minSwingArc;
  final VoidCallback onSwing;

  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<_MomentumPoint> _window = [];
  bool _locked = false;
  DateTime _lastTrigger = DateTime(2000);

  void start() {
    _subscription?.cancel();
    _subscription = accelerometerEventStream().listen(_onEvent);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _window.clear();
  }

  void _onEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    if (_locked || now.difference(_lastTrigger) < const Duration(seconds: 1)) {
      return;
    }

    // 1. Clean window
    _window.removeWhere((p) => now.difference(p.time) > windowSize);

    // 2. Add current point (gravity compensated roughly by looking at magnitude change)
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    _window.add(_MomentumPoint(event, magnitude, now));

    // 3. Analyze for "Swing"
    if (_window.length < 5) return;

    // Detect a "pull-back" and "release" arc
    double maxMagnitude = 0;
    double minMagnitude = threshold;
    for (final p in _window) {
      if (p.magnitude > maxMagnitude) maxMagnitude = p.magnitude;
      if (p.magnitude < minMagnitude) minMagnitude = p.magnitude;
    }

    // A swing is a large delta in magnitude over a short window
    final delta = maxMagnitude - minMagnitude;
    
    // Easing Haptics: As we approach the threshold, give subtle feedback
    if (delta > threshold * 0.6 && delta < threshold) {
      _provideEasingHaptic(delta / threshold);
    }

    if (delta > threshold) {
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
  final AccelerometerEvent event;
  final double magnitude;
  final DateTime time;
  _MomentumPoint(this.event, this.magnitude, this.time);
}
