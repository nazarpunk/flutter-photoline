import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// [ScrollSpringSimulation]
class ScrollSnapSpringSimulation extends Simulation {
  ScrollSnapSpringSimulation(
    SpringDescription spring,
    double start,
    this.end,
    double velocity, {
    super.tolerance,
  }) {
    final double cmk =
        spring.damping * spring.damping - 4 * spring.mass * spring.stiffness;
    final double distance = start - end;
    _r1 = (-spring.damping - math.sqrt(cmk)) / (2.0 * spring.mass);
    _r2 = (-spring.damping + math.sqrt(cmk)) / (2.0 * spring.mass);
    _c2 = (velocity - _r1 * distance) / (_r2 - _r1);
    _c1 = distance - _c2;
  }

  final double end;

  late final double _r1, _r2, _c1, _c2;

  double _x(double time) =>
      _c1 * math.pow(math.e, _r1 * time) + _c2 * math.pow(math.e, _r2 * time);

  @override
  double x(double time) => isDone(time) ? end : end + _x(time);

  @override
  double dx(double time) =>
      _c1 * _r1 * math.pow(math.e, _r1 * time) +
      _c2 * _r2 * math.pow(math.e, _r2 * time);

  @override
  bool isDone(double time) {
    final x = _x(time);

    if (nearEqual(end + x, end, 1)) return true;

    return nearZero(x, tolerance.distance) &&
        nearZero(dx(time), tolerance.velocity);
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SnapSpringSimulation')}(end: ${end.toStringAsFixed(1)})';
}
