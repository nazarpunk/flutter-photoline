import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';

class ScrollSnapPhysics extends ScrollPhysics {
  const ScrollSnapPhysics({super.parent, required this.controller});

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
  ScrollSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      ScrollSnapPhysics(parent: buildParent(ancestor), controller: controller);

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
    ScrollMetrics position,
    double velocity,
  ) {
    //print('☢️ createBallisticSimulation | $velocity');

    final ScrollSnapPosition? spos =
        position is ScrollSnapPosition ? position : null;
    final pp = position.pixels;

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
      if (spos != null) {
        final c = controller as ScrollSnapController;

        if (c.snapBuilder != null) {
          final vd = position.viewportDimension;
          final mw = c.boxConstraints!.maxWidth;
          double so = -pp;
          double area = double.infinity;
          double? target;
          double wH = 0;

          for (var i = 0; i >= 0; i++) {
            final h = c.snapBuilder!(
              i,
              SliverLayoutDimensions(
                scrollOffset: 0,
                precedingScrollExtent: 0,
                viewportMainAxisExtent: vd,
                crossAxisExtent: mw,
              ),
            );
            if (h == null) break;
            final se = so + h;
            final a = math.min(se, vd) - math.max(so, 0);

            if (a > 0 && (area.isInfinite || a > area)) {
              area = a;
              wH = h;
              target = so + pp;
            }
            so = se;
          }

          if (target == null || target == pp) return null;
          if (wH >= vd + c.photolineGap) return null;

          return ScrollSpringSimulation(
            spring,
            position.pixels,
            target,
            0.0,
            tolerance: tolerance,
          );
        }

        return ScrollSpringSimulation(
          spring,
          position.pixels,
          position.pixels,
          //position.pixels + dist,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }

      /// snap photoline at end
      final target = spos?.photolinePhysicSnap(velocity, pp);

      if (target == null || pp == target) return null;
      return ScrollSpringSimulation(
        spring,
        pp,
        target,
        math.min(0.0, velocity),
        tolerance: tolerance,
      );
    }

    if (velocity > 0.0 && pp >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && pp <= position.minScrollExtent) {
      return null;
    }

    if (position is ScrollSnapPosition) {
      double target =
          pp +
          200 *
              math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
              velocity.sign;
      if (controller is ScrollSnapController) {
        /// snap photoline
        final nT = spos?.photolinePhysicSnap(velocity, target);
        if (nT != null) target = nT;
      }
      return ScrollSnapSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
      );
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
        math.min(
          0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
          40000.0,
        );
  }

  ScrollDecelerationRate get decelerationRate => ScrollDecelerationRate.normal;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) return offset;

    final double overscrollPastStart = math.max(
      position.minScrollExtent - position.pixels,
      0.0,
    );
    final double overscrollPastEnd = math.max(
      position.pixels - position.maxScrollExtent,
      0.0,
    );
    final double overscrollPast = math.max(
      overscrollPastStart,
      overscrollPastEnd,
    );
    final bool easing =
        (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction =
        easing
            // Apply less resistance when easing the overscroll vs tensioning.
            ? frictionFactor(
              (overscrollPast - offset.abs()) / position.viewportDimension,
            )
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
    double extentOutside,
    double absDelta,
    double gamma,
  ) {
    assert(absDelta > 0);
    var total = 0.0;
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
