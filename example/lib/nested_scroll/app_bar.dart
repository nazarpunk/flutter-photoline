import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliverHolder {


}

class _SliverAppBarDelegate {
  _SliverAppBarDelegate({
    required this.title,
    required this.vsync,
  });

  final Widget? title;

  double get minExtent => 200;

  double get maxExtent => 400;

  final TickerProvider vsync;

  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final Widget? effectiveTitle = title;

    return ColoredBox(
      color: Colors.redAccent.withOpacity(.3),
      child: Placeholder(
        child: Center(child: effectiveTitle),
      ),
    );
  }

  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) =>
      title != oldDelegate.title || vsync != oldDelegate.vsync;
}

class SliverAppBarEx extends StatefulWidget {
  const SliverAppBarEx({
    super.key,
    this.title,
  });

  final Widget? title;

  @override
  State<SliverAppBarEx> createState() => _SliverAppBarExState();
}

class _SliverAppBarExState extends State<SliverAppBarEx>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _SliverFloatingPinnedPersistentHeader(
      delegate: _SliverAppBarDelegate(
        vsync: this,
        title: widget.title,
      ),
    );
  }
}

class _SliverFloatingPinnedPersistentHeader extends RenderObjectWidget {
  const _SliverFloatingPinnedPersistentHeader({
    required this.delegate,
  });

  final _SliverAppBarDelegate delegate;

  @override
  _SliverFloatingPinnedPersistentHeaderRender createRenderObject(
      BuildContext context) {
    return _SliverFloatingPinnedPersistentHeaderRender(
      vsync: delegate.vsync,
    );
  }

  @override
  _SliverPersistentHeaderElement createElement() =>
      _SliverPersistentHeaderElement(this);

  @override
  void updateRenderObject(BuildContext context,
      _SliverFloatingPinnedPersistentHeaderRender renderObject) {
    renderObject.vsync = delegate.vsync;
  }
}

class _SliverFloatingPinnedPersistentHeaderRender extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  _SliverFloatingPinnedPersistentHeaderRender({
    TickerProvider? vsync,
    RenderBox? child,
  }) : _vsync = vsync {
    this.child = child;
  }

  @protected
  void triggerRebuild() {
    markNeedsLayout();
  }

  void updateChild(double shrinkOffset, bool overlapsContent) {
    assert(mixinElement != null);
    mixinElement!._build(shrinkOffset, overlapsContent);
  }

  _SliverPersistentHeaderElement? mixinElement;

  TickerProvider? get vsync => _vsync;
  TickerProvider? _vsync;

  set vsync(TickerProvider? value) {
    if (value == _vsync) return;
    _vsync = value;
    if (value == null) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller?.resync(value);
    }
  }

  double get maxExtent =>
      (mixinElement!.widget as _SliverFloatingPinnedPersistentHeader)
          .delegate
          .maxExtent;

  double get minExtent =>
      (mixinElement!.widget as _SliverFloatingPinnedPersistentHeader)
          .delegate
          .minExtent;

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
    final SliverConstraints constraints = this.constraints;
    final double maxExtent = this.maxExtent;
    if (_lastActualScrollOffset != null &&
        ((constraints.scrollOffset < _lastActualScrollOffset!) ||
            (_effectiveScrollOffset! < maxExtent))) {
      double delta = _lastActualScrollOffset! - constraints.scrollOffset;

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

class _SliverPersistentHeaderElement extends RenderObjectElement {
  _SliverPersistentHeaderElement(
      _SliverFloatingPinnedPersistentHeader super.widget);

  @override
  _SliverFloatingPinnedPersistentHeaderRender get renderObject =>
      super.renderObject as _SliverFloatingPinnedPersistentHeaderRender;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    renderObject.mixinElement = this;
  }

  @override
  void unmount() {
    renderObject.mixinElement = null;
    super.unmount();
  }

  @override
  void update(_SliverFloatingPinnedPersistentHeader newWidget) {
    final _SliverFloatingPinnedPersistentHeader oldWidget =
        widget as _SliverFloatingPinnedPersistentHeader;
    super.update(newWidget);
    final _SliverAppBarDelegate newDelegate = newWidget.delegate;
    final _SliverAppBarDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) {
      renderObject.triggerRebuild();
    }
  }

  @override
  void performRebuild() {
    super.performRebuild();
    renderObject.triggerRebuild();
  }

  Element? child;

  void _build(double shrinkOffset, bool overlapsContent) {
    owner!.buildScope(this, () {
      final _SliverFloatingPinnedPersistentHeader
          sliverPersistentHeaderRenderObjectWidget =
          widget as _SliverFloatingPinnedPersistentHeader;
      child = updateChild(
        child,
        sliverPersistentHeaderRenderObjectWidget.delegate
            .build(this, shrinkOffset, overlapsContent),
        null,
      );
    });
  }

  @override
  void forgetChild(Element child) {
    assert(child == this.child);
    this.child = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, Object? slot) {
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(
      covariant RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(covariant RenderObject child, Object? slot) {
    renderObject.child = null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (child != null) visitor(child!);
  }
}
