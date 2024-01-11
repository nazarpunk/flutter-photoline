import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/scroll/position.dart';

class PhotolineOpenSimulation extends Simulation {
  PhotolineOpenSimulation({
    required this.controller,
    required this.position,
    required this.velocity,
    this.friction = 0.0175, // 0.015
    super.tolerance,
  }) : pixels = position.pixels {
    _duration = _flingDuration();
    _distance = _flingDistance();
  }

  final PhotolineController controller;
  final PhotolineScrollPosition position;

  final double pixels;
  final double velocity;

  /// The amount of friction the particle experiences as it travels.
  ///
  /// The more friction the particle experiences, the sooner it stops and the
  /// less far it travels.
  ///
  /// The default value causes the particle to travel the same total distance
  /// as in the Android scroll physics.
  // See mFlingFriction.
  final double friction;

  /// The total time the simulation will run, in seconds.
  late double _duration;

  /// The total, signed, distance the simulation will travel, in logical pixels.
  late double _distance;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  // See INFLEXION.
  static const double _kInflexion = 0.35;

  // See mPhysicalCoeff.  This has a value of 0.84 times Earth gravity,
  // expressed in units of logical pixels per second^2.
  static const double _physicalCoeff = 9.80665 // g, in meters per second^2
      *
      39.37 // 1 meter / 1 inch
      *
      400.0 // 1 inch / 1 logical pixel || 160.0
      *
      0.84; // "look and feel tuning"

  // See getSplineFlingDuration().
  double _flingDuration() {
    // See getSplineDeceleration().  That function's value is
    // math.log(velocity.abs() / referenceVelocity).
    final double referenceVelocity = friction * _physicalCoeff / _kInflexion;

    // This is the value getSplineFlingDuration() would return, but in seconds.
    final double androidDuration = math.pow(
            velocity.abs() / referenceVelocity, 1 / (_kDecelerationRate - 1.0))
        as double;

    // We finish a bit sooner than Android, in order to travel the
    // same total distance.
    return _kDecelerationRate * _kInflexion * androidDuration;
  }

  // See getSplineFlingDistance().  This returns the same value but with the
  // sign of [velocity], and in logical pixels.
  double _flingDistance() {
    final double distance = velocity * _duration / _kDecelerationRate;
    double page = position.getPageFromPixels(pixels + distance);
    page = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();

    int pg = page.round();
    if (position.controller.getPagerIndexOffset() > 0) {
      pg = math.max(pg, 1);
    }
    position.controller.pageTargetOpen.value = pg;

    return position.getPixelsFromPage(page) - pixels;
  }

  @override
  double x(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return pixels + _distance * (1.0 - math.pow(1.0 - t, _kDecelerationRate));
  }

  @override
  double dx(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return velocity * math.pow(1.0 - t, _kDecelerationRate - 1.0);
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}
