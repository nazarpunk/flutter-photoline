import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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

    // When a header is present, the overlap includes the header height.
    // We need to subtract it so the refresh indicator only reflects the
    // actual pull-down distance beyond the header.
    final double headerHeight =
        refresh.widget.controller.headerHolder?.height.value ?? 0.0;
    final double effectiveOverlap =
        math.min(0.0, constraints.overlap + headerHeight);

    final double oh = refresh.overlapHeight;

    // During closing, use the animation-driven height for the child layout,
    // not the overlap (which is stale without scrollOffsetCorrection).
    final double childMaxExtent = refresh.isClosing
        ? math.max(0.0, oh)
        : math.max(0.0, effectiveOverlap.abs());

    child!.layout(
      constraints.asBoxConstraints(
        maxExtent: childMaxExtent,
      ),
      parentUsesSize: true,
    );

    // Only issue scrollOffsetCorrection when actively pulling (not during
    // the closing animation), otherwise the correction shifts pixels and
    // drags the header along.
    final double? scrollOffsetCorrection;
    if (refresh.isClosing) {
      scrollOffsetCorrection = null;
    } else {
      scrollOffsetCorrection =
          effectiveOverlap <= 0 && effectiveOverlap > -oh
              ? -oh - effectiveOverlap
              : null;
    }

    if (kDebugMode && scrollOffsetCorrection != null) {
      debugPrint('🔃 RefreshSliver scrollOffsetCorrection=$scrollOffsetCorrection, overlap=${constraints.overlap}, effectiveOverlap=$effectiveOverlap, oh=$oh');
    }

    // During closing, the child extent is driven by the animation (oh),
    // not by the overlap, so clamp the painted extent accordingly.
    final double childHeight = refresh.isClosing
        ? math.max(0.0, oh)
        : child!.size.height;

    geometry = SliverGeometry(
      scrollOffsetCorrection: scrollOffsetCorrection,
      paintOrigin: refresh.isClosing ? -childHeight : effectiveOverlap,
      paintExtent: math.max(childHeight - constraints.scrollOffset, 0.0),
      maxPaintExtent:
          math.max(childHeight - constraints.scrollOffset, 0.0),
      layoutExtent: math.max(0 - constraints.scrollOffset, 0.0),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (refresh.isClosing) {
      // During closing, always paint if there's still extent
      final double oh = refresh.overlapHeight;
      if (oh > 0) {
        context.paintChild(child!, offset);
      }
      return;
    }
    if (constraints.overlap + (refresh.widget.controller.headerHolder?.height.value ?? 0.0) < 0.0 ||
        constraints.scrollOffset + child!.size.height > 0) {
      context.paintChild(child!, offset);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}
