import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline_example/nested_scroll/header/render_object_element.dart';

class ScrollSnapSliverHeaderRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  ScrollSnapSliverHeaderRenderSliver({
    RenderBox? child,
  }) {
    this.child = child;
  }

  void triggerRebuild() {
    markNeedsLayout();
  }

  void updateChild(double shrinkOffset, bool overlapsContent) {
    assert(mixinElement != null);
    mixinElement!.buildEx(shrinkOffset, overlapsContent);
  }

  ScrollSnapSliverHeaderRenderObjectElement? mixinElement;

  double get maxExtent => 400;

  double get minExtent => 200;

  @protected
  double get childExtent {
    if (child == null) return 0.0;
    assert(child!.hasSize);
    switch (constraints.axis) {
      case Axis.vertical:
        return child!.size.height;
      case Axis.horizontal:
        return child!.size.width;
    }
  }

  bool _needsUpdateChild = true;
  double _lastShrinkOffset = 0.0;
  bool _lastOverlapsContent = false;

  @override
  void markNeedsLayout() {
    _needsUpdateChild = true;
    super.markNeedsLayout();
  }

  @protected
  void layoutChild(double scrollOffset, double maxExtent,
      {bool overlapsContent = false}) {
    final double shrinkOffset = math.min(scrollOffset, maxExtent);
    if (_needsUpdateChild ||
        _lastShrinkOffset != shrinkOffset ||
        _lastOverlapsContent != overlapsContent) {
      invokeLayoutCallback<SliverConstraints>((constraints) {
        assert(constraints == this.constraints);
        updateChild(shrinkOffset, overlapsContent);
      });
      _lastShrinkOffset = shrinkOffset;
      _lastOverlapsContent = overlapsContent;
      _needsUpdateChild = false;
    }

    assert(minExtent <= maxExtent);

    child?.layout(
      constraints.asBoxConstraints(
        maxExtent: math.max(minExtent, maxExtent - shrinkOffset),
      ),
      parentUsesSize: true,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition ?? 0.0;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null) {
      return hitTestBoxChild(BoxHitTestResult.wrap(result), child!,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      switch (applyGrowthDirectionToAxisDirection(
          constraints.axisDirection, constraints.growthDirection)) {
        case AxisDirection.up:
          offset += Offset(
              0.0,
              geometry!.paintExtent -
                  childMainAxisPosition(child!) -
                  childExtent);
        case AxisDirection.down:
          offset += Offset(0.0, childMainAxisPosition(child!));
        case AxisDirection.left:
          offset += Offset(
              geometry!.paintExtent -
                  childMainAxisPosition(child!) -
                  childExtent,
              0.0);
        case AxisDirection.right:
          offset += Offset(childMainAxisPosition(child!), 0.0);
      }
      context.paintChild(child!, offset);
    }
  }

  AnimationController? _controller;

  double? _lastActualScrollOffset;
  double? _effectiveScrollOffset;

  ScrollDirection? _lastStartedScrollDirection;

  double? _childPosition;

  @override
  void detach() {
    _controller?.dispose();
    _controller = null;
    super.detach();
  }

  double updateGeometry() {
    final double minExtent = this.minExtent;
    final double minAllowedExtent = constraints.remainingPaintExtent > minExtent
        ? minExtent
        : constraints.remainingPaintExtent;
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset!;
    final double clampedPaintExtent = clampDouble(
      paintExtent,
      minAllowedExtent,
      constraints.remainingPaintExtent,
    );
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    const double stretchOffset = 0.0;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: clampedPaintExtent,
      layoutExtent: clampDouble(layoutExtent, 0.0, clampedPaintExtent),
      maxPaintExtent: maxExtent + stretchOffset,
      maxScrollObstructionExtent: minExtent,
      hasVisualOverflow: true,
    );
    return 0.0;
  }

  @override
  void performLayout() {
    //print("💋perform|$this");

    final SliverConstraints constraints = this.constraints;
    final double maxExtent = this.maxExtent;
    if (_lastActualScrollOffset != null &&
        ((constraints.scrollOffset < _lastActualScrollOffset!) ||
            (_effectiveScrollOffset! < maxExtent))) {
      double delta = _lastActualScrollOffset! - constraints.scrollOffset;

      //print(delta);

      final bool allowFloatingExpansion =
          constraints.userScrollDirection == ScrollDirection.forward ||
              (_lastStartedScrollDirection != null &&
                  _lastStartedScrollDirection == ScrollDirection.forward);
      if (allowFloatingExpansion) {
        if (_effectiveScrollOffset! > maxExtent) {
          _effectiveScrollOffset = maxExtent;
        }
      } else {
        if (delta > 0.0) delta = 0.0;
      }
      _effectiveScrollOffset = clampDouble(
          _effectiveScrollOffset! - delta, 0.0, constraints.scrollOffset);
    } else {
      _effectiveScrollOffset = constraints.scrollOffset;
    }
    final bool overlapsContent =
        _effectiveScrollOffset! < constraints.scrollOffset;

    layoutChild(
      _effectiveScrollOffset!,
      maxExtent,
      overlapsContent: overlapsContent,
    );
    _childPosition = updateGeometry();
    _lastActualScrollOffset = constraints.scrollOffset;
  }
}
