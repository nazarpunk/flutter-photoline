import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:photoline/src/viewport/offset.dart';

class PhotolineRenderViewport<
        ParentDataClass extends ContainerParentDataMixin<RenderSliver>>
    extends RenderBox
    with ContainerRenderObjectMixin<RenderSliver, ParentDataClass> {
  PhotolineRenderViewport({
    required ViewportOffset offset,
    List<RenderSliver>? children,
  }) : _offset = offset {
    addAll(children);
    if (firstChild != null) {
      _center = firstChild;
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    childrenInPaintOrder
        .where((sliver) =>
            sliver.geometry!.visible || sliver.geometry!.cacheExtent > 0.0)
        .forEach(visitor);
  }

  final AxisDirection _axisDirection = AxisDirection.right;
  final AxisDirection _crossAxisDirection = AxisDirection.down;

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;

  set offset(ViewportOffset value) {
    if (value == _offset) {
      return;
    }
    if (attached) {
      _offset.removeListener(markNeedsLayout);
    }
    _offset = value;
    if (attached) {
      _offset.addListener(markNeedsLayout);
    }
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0.0;

  @override
  double computeMinIntrinsicHeight(double width) => 0.0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0.0;

  @override
  bool get isRepaintBoundary => true;

  @protected
  double layoutChildSequence({
    required RenderSliver? child,
    required double scrollOffset,
    required double overlap,
    required double layoutOffset,
    required double remainingPaintExtent,
    required double mainAxisExtent,
    required double crossAxisExtent,
    required GrowthDirection growthDirection,
    required RenderSliver? Function(RenderSliver child) advance,
    required double remainingCacheExtent,
    required double cacheOrigin,
  }) {
    assert(scrollOffset.isFinite);
    assert(scrollOffset >= 0.0);
    final double initialLayoutOffset = layoutOffset;
    final ScrollDirection adjustedUserScrollDirection =
        applyGrowthDirectionToScrollDirection(
            offset.userScrollDirection, growthDirection);
    double maxPaintOffset = layoutOffset + overlap;
    double precedingScrollExtent = 0.0;

    while (child != null) {
      final double sliverScrollOffset =
          scrollOffset <= 0.0 ? 0.0 : scrollOffset;
      final double correctedCacheOrigin =
          math.max(cacheOrigin, -sliverScrollOffset);
      final double cacheExtentCorrection = cacheOrigin - correctedCacheOrigin;

      assert(sliverScrollOffset >= correctedCacheOrigin.abs());
      assert(correctedCacheOrigin <= 0.0);
      assert(sliverScrollOffset >= 0.0);
      assert(cacheExtentCorrection <= 0.0);

      child.layout(
          SliverConstraints(
            axisDirection: _axisDirection,
            growthDirection: growthDirection,
            userScrollDirection: adjustedUserScrollDirection,
            scrollOffset: sliverScrollOffset,
            precedingScrollExtent: precedingScrollExtent,
            overlap: maxPaintOffset - layoutOffset,
            remainingPaintExtent: math.max(
                0.0, remainingPaintExtent - layoutOffset + initialLayoutOffset),
            crossAxisExtent: crossAxisExtent,
            crossAxisDirection: _crossAxisDirection,
            viewportMainAxisExtent: mainAxisExtent,
            remainingCacheExtent:
                math.max(0.0, remainingCacheExtent + cacheExtentCorrection),
            cacheOrigin: correctedCacheOrigin,
          ),
          parentUsesSize: true);

      final SliverGeometry childLayoutGeometry = child.geometry!;
      assert(childLayoutGeometry.debugAssertIsValid());

      if (childLayoutGeometry.scrollOffsetCorrection != null) {
        return childLayoutGeometry.scrollOffsetCorrection!;
      }

      final double effectiveLayoutOffset =
          layoutOffset + childLayoutGeometry.paintOrigin;

      if (childLayoutGeometry.visible || scrollOffset > 0) {
        updateChildLayoutOffset(child, effectiveLayoutOffset, growthDirection);
      } else {
        updateChildLayoutOffset(
            child, -scrollOffset + initialLayoutOffset, growthDirection);
      }

      maxPaintOffset = math.max(
          effectiveLayoutOffset + childLayoutGeometry.paintExtent,
          maxPaintOffset);
      scrollOffset -= childLayoutGeometry.scrollExtent;
      precedingScrollExtent += childLayoutGeometry.scrollExtent;
      layoutOffset += childLayoutGeometry.layoutExtent;
      if (childLayoutGeometry.cacheExtent != 0.0) {
        remainingCacheExtent -=
            childLayoutGeometry.cacheExtent - cacheExtentCorrection;
        cacheOrigin = math.min(
            correctedCacheOrigin + childLayoutGeometry.cacheExtent, 0.0);
      }

      updateOutOfBandData(growthDirection, childLayoutGeometry);

      child = advance(child);
    }

    return 0.0;
  }

  @override
  Rect? describeApproximatePaintClip(RenderSliver child) {
    final Rect viewportClip = Offset.zero & size;

    if (child.constraints.overlap == 0 ||
        !child.constraints.viewportMainAxisExtent.isFinite) {
      return viewportClip;
    }

    // Adjust the clip rect for this sliver by the overlap from the previous sliver.
    double left = viewportClip.left;
    double right = viewportClip.right;
    double top = viewportClip.top;
    double bottom = viewportClip.bottom;
    final double startOfOverlap = child.constraints.viewportMainAxisExtent -
        child.constraints.remainingPaintExtent;
    final double overlapCorrection = startOfOverlap + child.constraints.overlap;
    switch (applyGrowthDirectionToAxisDirection(
        _axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        top += overlapCorrection;
      case AxisDirection.up:
        bottom -= overlapCorrection;
      case AxisDirection.right:
        left += overlapCorrection;
      case AxisDirection.left:
        right -= overlapCorrection;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Rect describeSemanticsClip(RenderSliver? child) => Rect.fromLTRB(
        semanticBounds.left,
        semanticBounds.top,
        semanticBounds.right,
        semanticBounds.bottom,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;
    if (hasVisualOverflow) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintContents,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      _paintContents(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  void _paintContents(PaintingContext context, Offset offset) {
    for (final RenderSliver child in childrenInPaintOrder) {
      if (child.geometry!.visible) {
        context.paintChild(child, offset + paintOffsetOf(child));
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final (double mainAxisPosition, double crossAxisPosition) =
        (position.dx, position.dy);
    final SliverHitTestResult sliverResult = SliverHitTestResult.wrap(result);
    for (final RenderSliver child in childrenInHitTestOrder) {
      if (!child.geometry!.visible) {
        continue;
      }
      final Matrix4 transform = Matrix4.identity();
      applyPaintTransform(child, transform); // must be invertible
      final bool isHit = result.addWithOutOfBandPosition(
        paintTransform: transform,
        hitTest: (result) {
          return child.hitTest(
            sliverResult,
            mainAxisPosition:
                computeChildMainAxisPosition(child, mainAxisPosition),
            crossAxisPosition: crossAxisPosition,
          );
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  PhotolineViewportRevealedOffset getOffsetToReveal(
    RenderObject target,
    double alignment, {
    Rect? rect,
  }) {
    double leadingScrollOffset = 0.0;
    // Starting at `target` and walking towards the root:
    //  - `child` will be the last object before we reach this viewport, and
    //  - `pivot` will be the last RenderBox before we reach this viewport.
    RenderObject child = target;
    RenderBox? pivot;
    bool onlySlivers = target
        is RenderSliver; // ... between viewport and `target` (`target` included).
    while (child.parent != this) {
      final RenderObject parent = child.parent!;
      if (child is RenderBox) {
        pivot = child;
      }
      if (parent is RenderSliver) {
        leadingScrollOffset += parent.childScrollOffset(child)!;
      } else {
        onlySlivers = false;
        leadingScrollOffset = 0.0;
      }
      child = parent;
    }

    // `rect` in the new intermediate coordinate system.
    final Rect rectLocal;
    // Our new reference frame render object's main axis extent.
    final double pivotExtent;
    final GrowthDirection growthDirection;

    // `leadingScrollOffset` is currently the scrollOffset of our new reference
    // frame (`pivot` or `target`), within `child`.
    if (pivot != null) {
      assert(pivot.parent != null);
      assert(pivot.parent != this);
      assert(pivot != this);
      assert(pivot.parent is RenderSliver);
      final RenderSliver pivotParent = pivot.parent! as RenderSliver;
      growthDirection = pivotParent.constraints.growthDirection;
      pivotExtent = pivot.size.width;
      rect ??= target.paintBounds;
      rectLocal = MatrixUtils.transformRect(target.getTransformTo(pivot), rect);
    } else if (onlySlivers) {
      final RenderSliver targetSliver = target as RenderSliver;
      growthDirection = targetSliver.constraints.growthDirection;
      pivotExtent = targetSliver.geometry!.scrollExtent;
      rect ??= Rect.fromLTWH(
        0,
        0,
        targetSliver.geometry!.scrollExtent,
        targetSliver.constraints.crossAxisExtent,
      );
      rectLocal = rect;
    } else {
      assert(rect != null);
      return PhotolineViewportRevealedOffset(
          offset: offset.pixels, rect: rect!);
    }

    assert(child.parent == this);
    assert(child is RenderSliver);
    final RenderSliver sliver = child as RenderSliver;

    // The scroll offset of `rect` within `child`.
    leadingScrollOffset += switch (
        applyGrowthDirectionToAxisDirection(_axisDirection, growthDirection)) {
      AxisDirection.up => pivotExtent - rectLocal.bottom,
      AxisDirection.left => pivotExtent - rectLocal.right,
      AxisDirection.right => rectLocal.left,
      AxisDirection.down => rectLocal.top,
    };

    final bool isPinned = sliver.geometry!.maxScrollObstructionExtent > 0 &&
        leadingScrollOffset >= 0;

    leadingScrollOffset = scrollOffsetOf(sliver, leadingScrollOffset);

    final Matrix4 transform = target.getTransformTo(this);
    Rect targetRect = MatrixUtils.transformRect(transform, rect);
    final double extentOfPinnedSlivers =
        maxScrollObstructionExtentBefore(sliver);

    switch (sliver.constraints.growthDirection) {
      case GrowthDirection.forward:
        if (isPinned && alignment <= 0) {
          return PhotolineViewportRevealedOffset(
              offset: double.infinity, rect: targetRect);
        }
        leadingScrollOffset -= extentOfPinnedSlivers;
      case GrowthDirection.reverse:
        if (isPinned && alignment >= 1) {
          return PhotolineViewportRevealedOffset(
              offset: double.negativeInfinity, rect: targetRect);
        }
        leadingScrollOffset -= targetRect.width;
    }

    final double mainAxisExtentDifference =
        size.width - extentOfPinnedSlivers - rectLocal.width;

    final double targetOffset =
        leadingScrollOffset - mainAxisExtentDifference * alignment;
    final double offsetDifference = offset.pixels - targetOffset;

    targetRect = switch (_axisDirection) {
      AxisDirection.up => targetRect.translate(0.0, -offsetDifference),
      AxisDirection.down => targetRect.translate(0.0, offsetDifference),
      AxisDirection.left => targetRect.translate(-offsetDifference, 0.0),
      AxisDirection.right => targetRect.translate(offsetDifference, 0.0),
    };

    return PhotolineViewportRevealedOffset(
        offset: targetOffset, rect: targetRect);
  }

  Offset computeAbsolutePaintOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    assert(hasSize);
    assert(child.geometry != null);
    return switch (
        applyGrowthDirectionToAxisDirection(_axisDirection, growthDirection)) {
      AxisDirection.up =>
        Offset(0.0, size.height - layoutOffset - child.geometry!.paintExtent),
      AxisDirection.left =>
        Offset(size.width - layoutOffset - child.geometry!.paintExtent, 0.0),
      AxisDirection.right => Offset(layoutOffset, 0.0),
      AxisDirection.down => Offset(0.0, layoutOffset),
    };
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }

    final Rect? newRect = showInViewport(
      descendant: descendant,
      viewport: this,
      offset: offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }

  static Rect? showInViewport({
    RenderObject? descendant,
    Rect? rect,
    required PhotolineRenderViewport viewport,
    required ViewportOffset offset,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant == null) return rect;
    final PhotolineViewportRevealedOffset leadingEdgeOffset =
        viewport.getOffsetToReveal(descendant, 0.0, rect: rect);
    final PhotolineViewportRevealedOffset trailingEdgeOffset =
        viewport.getOffsetToReveal(descendant, 1.0, rect: rect);
    final double currentOffset = offset.pixels;
    final PhotolineViewportRevealedOffset? targetOffset =
        PhotolineViewportRevealedOffset.clampOffset(
      leadingEdgeOffset: leadingEdgeOffset,
      trailingEdgeOffset: trailingEdgeOffset,
      currentOffset: currentOffset,
    );
    if (targetOffset == null) {
      assert(viewport.parent != null);
      final Matrix4 transform = descendant.getTransformTo(viewport.parent);
      return MatrixUtils.transformRect(
          transform, rect ?? descendant.paintBounds);
    }

    unawaited(
        offset.moveTo(targetOffset.offset, duration: duration, curve: curve));
    return targetOffset.rect;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
    }
  }

  RenderSliver? get center => _center;
  RenderSliver? _center;

  set center(RenderSliver? value) {
    if (value == _center) {
      return;
    }
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  static const int _maxLayoutCyclesPerChild = 10;

  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    offset.applyViewportDimension(size.width);

    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center!.parent == this);

    final (double mainAxisExtent, double crossAxisExtent) =
        (size.width, size.height);

    final double centerOffsetAdjustment = center!.centerOffsetAdjustment;
    final int maxLayoutCycles = _maxLayoutCyclesPerChild * childCount;

    double correction;
    int count = 0;
    do {
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent,
          offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        if (offset.applyContentDimensions(
          math.min(0.0, _minScrollExtent),
          math.max(0.0, _maxScrollExtent - mainAxisExtent),
        )) {
          break;
        }
      }
      count += 1;
    } while (count < maxLayoutCycles);
    assert(() {
      if (count >= maxLayoutCycles) {
        assert(count != 1);
        throw FlutterError(
          'A RenderViewport exceeded its maximum number of layout cycles.\n'
          'RenderViewport render objects, during layout, can retry if either their '
          'slivers or their ViewportOffset decide that the offset should be corrected '
          'to take into account information collected during that layout.\n'
          'In the case of this RenderViewport object, however, this happened $count '
          'times and still there was no consensus on the scroll offset. This usually '
          'indicates a bug. Specifically, it means that one of the following three '
          'problems is being experienced by the RenderViewport object:\n'
          ' * One of the RenderSliver children or the ViewportOffset have a bug such'
          ' that they always think that they need to correct the offset regardless.\n'
          ' * Some combination of the RenderSliver children and the ViewportOffset'
          ' have a bad interaction such that one applies a correction then another'
          ' applies a reverse correction, leading to an infinite loop of corrections.\n'
          ' * There is a pathological case that would eventually resolve, but it is'
          ' so complicated that it cannot be resolved in any reasonable number of'
          ' layout passes.',
        );
      }
      return true;
    }());
  }

  double _attemptLayout(
      double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    final double centerOffset = -correctedOffset;

    final double reverseDirectionRemainingPaintExtent =
        clampDouble(centerOffset, 0.0, mainAxisExtent);

    final double forwardDirectionRemainingPaintExtent =
        clampDouble(mainAxisExtent - centerOffset, 0.0, mainAxisExtent);

    final double fullCacheExtent = mainAxisExtent;
    final double centerCacheOffset = centerOffset;
    final double reverseDirectionRemainingCacheExtent =
        clampDouble(centerCacheOffset, 0.0, fullCacheExtent);
    final double forwardDirectionRemainingCacheExtent =
        clampDouble(fullCacheExtent - centerCacheOffset, 0.0, fullCacheExtent);

    final RenderSliver? leadingNegativeChild = childBefore(center!);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final double result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0.0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: clampDouble(mainAxisExtent - centerOffset, 0, 0.0),
      );
      if (result != 0.0) {
        return -result;
      }
    }

    // positive scroll offsets
    return layoutChildSequence(
      child: center,
      scrollOffset: math.max(0.0, -centerOffset),
      overlap:
          leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
      layoutOffset: centerOffset >= mainAxisExtent
          ? centerOffset
          : reverseDirectionRemainingPaintExtent,
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: clampDouble(centerOffset, 0, 0.0),
    );
  }

  bool get hasVisualOverflow => _hasVisualOverflow;

  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
    }
    if (childLayoutGeometry.hasVisualOverflow) {
      _hasVisualOverflow = true;
    }
  }

  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    (child.parentData! as SliverPhysicalParentData).paintOffset =
        computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
  }

  Offset paintOffsetOf(RenderSliver child) {
    final SliverPhysicalParentData childParentData =
        child.parentData! as SliverPhysicalParentData;
    return childParentData.paintOffset;
  }

  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          scrollOffsetToChild += current!.geometry!.scrollExtent;
          current = childAfter(current);
        }
        return scrollOffsetToChild + scrollOffsetWithinChild;
      case GrowthDirection.reverse:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          scrollOffsetToChild -= current!.geometry!.scrollExtent;
          current = childBefore(current);
        }
        return scrollOffsetToChild - scrollOffsetWithinChild;
    }
  }

  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        double pinnedExtent = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        double pinnedExtent = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    (child.parentData! as SliverPhysicalParentData)
        .applyPaintTransform(transform);
  }

  double computeChildMainAxisPosition(
      RenderSliver child, double parentMainAxisPosition) {
    final Offset paintOffset =
        (child.parentData! as SliverPhysicalParentData).paintOffset;
    return switch (applyGrowthDirectionToAxisDirection(
        child.constraints.axisDirection, child.constraints.growthDirection)) {
      AxisDirection.down => parentMainAxisPosition - paintOffset.dy,
      AxisDirection.right => parentMainAxisPosition - paintOffset.dx,
      AxisDirection.up =>
        child.geometry!.paintExtent - (parentMainAxisPosition - paintOffset.dy),
      AxisDirection.left =>
        child.geometry!.paintExtent - (parentMainAxisPosition - paintOffset.dx),
    };
  }

  int get indexOfFirstChild {
    assert(center != null);
    assert(center!.parent == this);
    assert(firstChild != null);
    int count = 0;
    RenderSliver? child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child!);
    }
    return count;
  }

  String labelForChild(int index) {
    if (index == 0) {
      return 'center child';
    }
    return 'child $index';
  }

  Iterable<RenderSliver> get childrenInPaintOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    if (firstChild == null) {
      return children;
    }
    RenderSliver? child = firstChild;
    while (child != center) {
      children.add(child!);
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      children.add(child!);
      if (child == center) {
        return children;
      }
      child = childBefore(child);
    }
  }

  Iterable<RenderSliver> get childrenInHitTestOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    if (firstChild == null) return children;
    RenderSliver? child = center;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    child = childBefore(center!);
    while (child != null) {
      children.add(child);
      child = childBefore(child);
    }
    return children;
  }
}
