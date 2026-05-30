import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/utils/diagnostics.dart';

final shakeEnabledProvider = StateProvider<bool>((ref) => true);

class ShakeDetector extends ConsumerStatefulWidget {
  const ShakeDetector({super.key, required this.child, required this.onShake});

  final Widget child;
  final VoidCallback onShake;

  @override
  ConsumerState<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends ConsumerState<ShakeDetector> {
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.now();
  static const _shakeThreshold = 15.0;
  static const _minInterval = Duration(seconds: 2);
  static const _sampleWindow = Duration(milliseconds: 500);

  final List<double> _xSamples = [];
  final List<double> _ySamples = [];
  final List<double> _zSamples = [];

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen(_onAccelerometerData);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAccelerometerData(AccelerometerEvent event) {
    if (!ref.read(shakeEnabledProvider)) return;

    final now = DateTime.now();
    _xSamples.add(event.x);
    _ySamples.add(event.y);
    _zSamples.add(event.z);

    final oldest = now.subtract(_sampleWindow);
    _xSamples.removeWhere((_) => _xSamples.length > 50);
    _ySamples.removeWhere((_) => _ySamples.length > 50);
    _zSamples.removeWhere((_) => _zSamples.length > 50);

    if (_xSamples.length < 5) return;

    final xMag = _stdDev(_xSamples);
    final yMag = _stdDev(_ySamples);
    final zMag = _stdDev(_zSamples);
    final total = sqrt(xMag * xMag + yMag * yMag + zMag * zMag);

    if (total > _shakeThreshold && now.difference(_lastShake) > _minInterval) {
      _lastShake = now;
      DiagnosticsLog.info('ShakeDetector', 'shake detected magnitude=${total.toStringAsFixed(1)}');
      _xSamples.clear();
      _ySamples.clear();
      _zSamples.clear();
      unawaited(HapticFeedback.heavyImpact());
      widget.onShake();
    }
  }

  double _stdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / values.length);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ComboShakeWrapper extends ConsumerWidget {
  const ComboShakeWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shakeEnabled = ref.watch(shakeEnabledProvider);
    if (!shakeEnabled) {
      return ref.watch(bottomNavShellProvider);
    }

    return ShakeDetector(
      onShake: () {
        final router = GoRouter.of(context);
        final current = router.routerDelegate.currentConfiguration.uri.path;
        if (current.startsWith('/breakdex')) {
          context.go('/review');
        }
      },
      child: ref.watch(bottomNavShellProvider),
    );
  }
}

final bottomNavShellProvider = Provider.autoDispose<Widget>((ref) {
  throw UnimplementedError('Use ComboShakeWrapper as a wrapper instead');
});

extension on GoRouter {
  String get currentPath => routerDelegate.currentConfiguration.uri.path;
}
