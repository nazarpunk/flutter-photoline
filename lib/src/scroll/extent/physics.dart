import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:photoline/src/scroll/extent/view.dart';

class PhotolineScrollExtentPhysics extends ScrollPhysics {
  const PhotolineScrollExtentPhysics({super.parent});

  @override
  PhotolineScrollExtentPhysics applyTo(ScrollPhysics? ancestor) =>
      PhotolineScrollExtentPhysics(parent: buildParent(ancestor));

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double get maxFlingVelocity => 4000;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final p = position.pixels;

    final max = maxScrollExtent(position);

    if (velocity == 0 && max < position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, max, 0);
    }

    double target =
        p +
        200 *
            math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
            velocity.sign;

    target = _target(
      target: target,
      position: position as ScrollPosition,
      velocity: velocity,
    );

    return target == p
        ? null
        : ScrollSpringSimulation(spring, p, target, velocity);
  }

  double _target({
    required double target,
    required ScrollPosition position,
    required double velocity,
  }) {
    final scroller = _scroller(position);
    final double ie = scroller.widget.itemExtent;

    final double items = target / ie;
    late final int p;
    if (velocity == 0) {
      p = items.round();
    } else if (velocity < 0) {
      p = items.floor();
    } else {
      p = items.ceil();
    }

    return p * ie;
  }

  PhotolineScrollExtentViewState _scroller(ScrollMetrics position) =>
      (position as ScrollPosition).context.notificationContext!
          .findAncestorStateOfType<PhotolineScrollExtentViewState>()!;

  double maxScrollExtent(ScrollMetrics position) =>
      math.max(0, position.maxScrollExtent);

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) =>
      newPosition is FixedScrollMetrics
          ? newPosition.pixels
          : math.min(maxScrollExtent(newPosition), newPosition.pixels);

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final p = position.pixels;
    assert(value != p);
    final min = position.minScrollExtent;
    final max = maxScrollExtent(position);

    if (value < p && p <= min) return value - p; // underscroll
    if (value > p && p >= max) return value - p; // overscroll
    if (p > min && min > value) return value - min; // hit top edge
    if (p < max && max < value) return value - max; // hit bottom edge
    return 0;
  }

  @override
  bool get allowImplicitScrolling => false;
}
