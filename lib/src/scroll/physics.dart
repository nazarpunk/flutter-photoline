import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/action.dart';
import 'position.dart';

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
  Simulation? createBallisticSimulation(covariant PhotolineScrollPosition position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) || (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double pageCur = _getPage(position);

    final v = 200 * math.exp(1.2 * math.log(.6 * velocity.abs() / 800)) * velocity.sign;

    double pageNew = 0;

    switch (position.controller.action) {
      case PhotolineAction.open:
        pageNew = position.pageAdd(v / (position.viewportDimension * position.controller.openRatio));
        if ((pageCur - pageNew).abs() < 1 && velocity.abs() > 1000) {
          if (velocity > 0) {
            pageNew += .5;
          } else {
            pageNew -= .5;
          }
        }
      case PhotolineAction.close:
        pageNew = position.pageAdd(v / (position.viewportDimension * position.controller.closeRatio));
      case PhotolineAction.opening:
      case PhotolineAction.closing:
      case PhotolineAction.drag:
    }

    final double target = _getPixels(position, pageNew.roundToDouble());
    if (target == position.pixels) return null;

    if (position.controller.action == PhotolineAction.open) {
      position.controller.pageTargetOpen = position.getPageFromPixels(target).round();
    }

    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}