import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoline/src/scroll/position.dart';
import 'package:photoline/src/scroll/simulation/open.dart';
import 'package:photoline/src/utils/action.dart';

class PhotolineScrollPhysics extends ScrollPhysics {
  const PhotolineScrollPhysics({super.parent});

  @override
  PhotolineScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PhotolineScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position is PhotolineScrollPosition) {}
    return super.applyPhysicsToUserOffset(position, offset);
  }

  double _getPage(ScrollMetrics position) {
    if (position is PhotolineScrollPosition) return position.page!;
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    if (position is PhotolineScrollPosition) {
      return position.getPixelsFromPage(page);
    }
    return page * position.viewportDimension;
  }

  @override
  Simulation? createBallisticSimulation(
      covariant PhotolineScrollPosition position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double pageCur = _getPage(position);

    final v = 200 *
        math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) *
        velocity.sign;

    double pageNew = 0;

    switch (position.controller.action.value) {
      case PhotolineAction.open:
        if (position.controller.useOpenSimulation) {
          if (velocity.abs() < tolerance.velocity) {
            final double page = position.getPageFromPixels(position.pixels);
            final double target =
                position.getPixelsFromPage(page.roundToDouble());
            if (position.pixels == target) return null;

            return ScrollSpringSimulation(
              spring,
              position.pixels,
              target,
              math.min(0.0, velocity),
              tolerance: tolerance,
            );
          }

          return PhotolineOpenSimulation(
            controller: position.controller,
            position: position,
            velocity: velocity,
            tolerance: tolerance,
          );
        } else {
          pageNew = position.pageAdd(
              v / (position.viewportDimension * position.controller.openRatio));
          if ((pageCur - pageNew).abs() < 1 && velocity.abs() > 1000) {
            if (velocity > 0) {
              pageNew += .5;
            } else {
              pageNew -= .5;
            }
          }
        }
      case PhotolineAction.close:
        pageNew = position.pageAdd(
            v / (position.viewportDimension * position.controller.closeRatio));
      case PhotolineAction.opening:
      case PhotolineAction.closing:
      case PhotolineAction.drag:
    }

    final double target = _getPixels(position, pageNew.roundToDouble());
    if (target == position.pixels) return null;

    if (!position.controller.useOpenSimulation) {
      if (position.controller.action.value == PhotolineAction.open) {
        int pg = position
            .getPageFromPixels(target)
            .round()
            .clamp(0, position.controller.getPhotoCount() - 1);
        if (position.controller.getPagerIndexOffset() > 0) {
          pg = math.max(pg, 1);
        }
        position.controller.pageTargetOpen.value = pg;
      }
    }

    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}
