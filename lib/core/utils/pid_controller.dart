class PidController {
  PidController({double kp = 0.4, double ki = 0.05, double kd = 0.3})
    : _kp = kp,
      _ki = ki,
      _kd = kd;

  final double _kp;
  final double _ki;
  final double _kd;

  double _previousError = 0;
  double _integral = 0;

  double update(double setpoint, double current, double dt) {
    final error = setpoint - current;
    final safeDt = dt <= 0 ? 0.016 : dt;
    final derivative = (error - _previousError) / safeDt;
    _integral = (_integral + error * safeDt).clamp(-1.0, 1.0);
    _previousError = error;
    return _kp * error + _ki * _integral + _kd * derivative;
  }

  void reset() {
    _previousError = 0;
    _integral = 0;
  }
}
