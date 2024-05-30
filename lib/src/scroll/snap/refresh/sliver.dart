import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/scroll/snap/refresh/refresh.dart';

class ScrollSnapRefreshSliver extends SingleChildRenderObjectWidget {
  const ScrollSnapRefreshSliver({
    super.key,
    required this.refresh,
    this.refreshIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    super.child,
  }) : assert(refreshIndicatorLayoutExtent >= 0.0);

  final double refreshIndicatorLayoutExtent;

  final bool hasLayoutExtent;
  final ScrollSnapRefreshState refresh;

  @override
  ScrollSnapRefreshSliverRender createRenderObject(BuildContext context) =>
      ScrollSnapRefreshSliverRender(
        refresh: refresh,
      );

  @override
  void updateRenderObject(BuildContext context,
      covariant ScrollSnapRefreshSliverRender renderObject) {
    renderObject.refresh = refresh;
  }
}

class ScrollSnapRefreshSliverRender extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  ScrollSnapRefreshSliverRender({
    required ScrollSnapRefreshState refresh,
    RenderBox? child,
  }) : _refresh = refresh {
    this.child = child;
  }

  ScrollSnapRefreshState get refresh => _refresh;
  ScrollSnapRefreshState _refresh;

  set refresh(ScrollSnapRefreshState value) {
    if (value == _refresh) return;
    _refresh = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);

    child!.layout(
      constraints.asBoxConstraints(
        maxExtent: constraints.overlap.abs(),
      ),
      parentUsesSize: true,
    );

    final double oh = refresh.overlapHeight;

    geometry = SliverGeometry(
      scrollOffsetCorrection:
          constraints.overlap <= 0 && constraints.overlap > -oh
              ? -oh - constraints.overlap
              : null,
      paintOrigin: constraints.overlap,
      paintExtent: math.max(child!.size.height - constraints.scrollOffset, 0.0),
      maxPaintExtent:
          math.max(child!.size.height - constraints.scrollOffset, 0.0),
      layoutExtent: math.max(0 - constraints.scrollOffset, 0.0),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (constraints.overlap < 0.0 ||
        constraints.scrollOffset + child!.size.height > 0) {
      context.paintChild(child!, offset);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}
