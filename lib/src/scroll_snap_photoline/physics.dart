import 'package:flutter/material.dart';
import 'package:photoline/src/scroll_snap_photoline/position.dart';

class PageScrollPhysicsPhotoline extends ScrollPhysics {
  const PageScrollPhysicsPhotoline({super.parent});

  @override
  PageScrollPhysicsPhotoline applyTo(ScrollPhysics? ancestor) {
    return PageScrollPhysicsPhotoline(parent: buildParent(ancestor));
  }

  double _getPage(ScrollMetrics position) {
    if (position is ScrollSnapPhotolinePagePosition) {
      return position.page!;
    }
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    if (position is ScrollSnapPhotolinePagePosition) {
      return position.getPixelsFromPage(page);
    }
    return page * position.viewportDimension;
  }

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return _getPixels(position, page.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
