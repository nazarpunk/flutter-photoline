import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';

class ScrollSnapPhysics extends ScrollPhysics {
  const ScrollSnapPhysics({
    super.parent,
    required this.controller,
  });

  final ScrollController controller;

  // Eyeballed from observation to counter the effect of an unintended scroll
  // from the natural motion of lifting the finger after a scroll.
  @override
  double get dragStartDistanceMotionThreshold => 2;

  @override
  double get minFlingVelocity => 50;

  @override
  double get maxFlingVelocity => 8000;

  @override
  ScrollSnapPhysics applyTo(ScrollPhysics? ancestor) => ScrollSnapPhysics(
        parent: buildParent(ancestor),
        controller: controller,
      );

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    return 0;
  }

  /// [ScrollPosition] calc in [ScrollSnapPosition.applyBoundaryConditions]
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0;

  /// [ClampingScrollPhysics.createBallisticSimulation]
  /// [BouncingScrollSimulation]
  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    //print('☢️ createBallisticSimulation | $velocity');

    final ScrollSnapPosition? pPos =
        position is ScrollSnapPosition ? position : null;
    final bool pSnap = pPos?.photolineCanSnap ?? false;

    final pp = position.pixels;
    final double pW = pPos?.controller.boxConstraints?.maxWidth ?? 0;
    final double pH =
        (pPos?.hasViewportDimension ?? false) ? pPos!.viewportDimension : 0;

    final Tolerance tolerance = toleranceFor(position);
    if (position.outOfRange) {
      double? end;
      if (pp > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (pp < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      assert(end != null);

      //print('🤡 position.outOfRange');

      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end!,
        math.min(0.0, velocity),
        tolerance: tolerance,
      );
    }

    /// end scroll
    if (velocity.abs() < tolerance.velocity) {
      /// snap box
      if (pPos != null && pPos.controller.snap) {
        double dist = double.infinity;
        for (final b in pPos.controller.box.entries) {
          final so = b.value.scrollOffset;
          final d = so - position.pixels;
          if (dist.isInfinite || d.abs() < dist.abs()) {
            dist = d;
          }
        }
        if (dist == 0 || dist.isInfinite) return null;
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          position.pixels + dist,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }

      /// snap photoline at end
      if (pSnap) {
        final (_, target) = pPos!.photolineClosest(pp);
        if (pp == target) return null;
        return ScrollSpringSimulation(
          spring,
          pp,
          target,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }
      return null;
    }

    if (velocity > 0.0 && pp >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && pp <= position.minScrollExtent) {
      return null;
    }

    if (position is ScrollSnapPosition) {
      double target = pp +
          200 *
              math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
              velocity.sign;
      if (controller is ScrollSnapController) {
        final c = controller as ScrollSnapController;
        final toBottom = velocity > 0;

        /// snap box
        if (c.snap && c.box.isNotEmpty) {
          final box = SplayTreeMap<int, ScrollSnapBox>.from(c.box,
              toBottom ? (a, b) => a.compareTo(b) : (a, b) => b.compareTo(a));
          for (final b in box.entries) {
            final so = b.value.scrollOffset;
            if ((toBottom && so >= target) || (!toBottom && so <= target)) {
              target = so;
              break;
            }
          }
        }

        /// snap photoline
        if (pSnap) {
          double so = 0;
          final List<double> offsets = [];
          for (final p in position.controller.snapPhotolines!()) {
            offsets.add(so);
            so += p.lerpConstraintsWH(pW, pH);
          }
          final list = toBottom ? offsets : offsets.reversed;
          for (final so in list) {
            if ((toBottom && so >= target) || (!toBottom && so <= target)) {
              target = so;
              break;
            }
          }
        }
      }
      return ScrollSnapSpringSimulation(
          spring, position.pixels, target, velocity);
    }

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => true;

  // ================= bouncing

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
            40000.0);
  }

  ScrollDecelerationRate get decelerationRate => ScrollDecelerationRate.normal;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) return offset;

    final double overscrollPastStart =
        math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast =
        math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    if (easing && decelerationRate == ScrollDecelerationRate.fast) {
      return direction * offset.abs();
    }
    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  double frictionFactor(double overscrollFraction) {
    switch (decelerationRate) {
      case ScrollDecelerationRate.fast:
        return 0.26 * math.pow(1 - overscrollFraction, 2);
      case ScrollDecelerationRate.normal:
        return 0.52 * math.pow(1 - overscrollFraction, 2);
    }
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }
}
