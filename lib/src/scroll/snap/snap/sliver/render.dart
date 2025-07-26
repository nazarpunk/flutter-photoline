part of 'list.dart';

class RenderSliverSnapMultiBoxAdaptor extends RenderSliverMultiBoxAdaptor implements RenderSliverVariedExtentList {
  RenderSliverSnapMultiBoxAdaptor({
    required ScrollSnapController controller,
    required super.childManager,
  }) : _controller = controller;

  @override
  @deprecated
  double? get itemExtent => null;

  ScrollSnapController _controller;

  ScrollSnapController get controller => _controller;

  set controller(ScrollSnapController value) {
    _controller = value;
    markNeedsLayout();
  }

  @override
  @deprecated
  ItemExtentBuilder get itemExtentBuilder => (_, _) => 0;

  @override
  @deprecated
  set itemExtentBuilder(ItemExtentBuilder value) {}

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    var offset = 0.0;
    double? itemExtent;
    for (var i = 0; i < index; i++) {
      final int? childCount = childManager.estimatedChildCount;
      if (childCount != null && i > childCount - 1) {
        break;
      }
      itemExtent = controller.snapBuilder!(i, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      offset += itemExtent;
    }
    return offset;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) => _getChildIndexForScrollOffset(scrollOffset, controller.snapBuilder!);

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) => _getChildIndexForScrollOffset(scrollOffset, controller.snapBuilder!);

  @override
  @protected
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );
  }

  @override
  @visibleForTesting
  @protected
  double computeMaxScrollOffset(
    SliverConstraints constraints,
    double itemExtent,
  ) {
    var offset = 0.0;
    double? itemExtent;
    for (var i = 0; i < childManager.childCount; i++) {
      itemExtent = controller.snapBuilder!(i, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      offset += itemExtent;
    }
    return offset;
  }

  int _getChildIndexForScrollOffset(
    double scrollOffset,
    ItemExtentBuilder callback,
  ) {
    if (scrollOffset == 0.0) {
      return 0;
    }
    var position = 0.0;
    var index = 0;
    double? itemExtent;
    while (position < scrollOffset) {
      final int? childCount = childManager.estimatedChildCount;
      if (childCount != null && index > childCount - 1) {
        break;
      }
      itemExtent = callback(index, _currentLayoutDimensions);
      if (itemExtent == null) {
        break;
      }
      position += itemExtent;
      ++index;
    }
    return index - 1;
  }

  BoxConstraints _getChildConstraints(int index) {
    final double extent = controller.snapBuilder!(index, _currentLayoutDimensions) ?? 0;
    return constraints.asBoxConstraints(minExtent: extent, maxExtent: extent);
  }

  late SliverLayoutDimensions _currentLayoutDimensions;

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    _currentLayoutDimensions = SliverLayoutDimensions(
      scrollOffset: constraints.scrollOffset,
      precedingScrollExtent: constraints.precedingScrollExtent,
      viewportMainAxisExtent: constraints.viewportMainAxisExtent,
      crossAxisExtent: constraints.crossAxisExtent,
    );

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, -1);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, -1) : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(
        firstIndex: firstIndex,
      );
      final int trailingGarbage = targetLastIndex != null ? calculateTrailingGarbage(lastIndex: targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(-1, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset(constraints, -1);
        }
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(
        _getChildConstraints(index),
      );
      if (child == null) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: indexToLayoutOffset(-1, index),
        );
        return;
      }
      final childParentData = (child.parentData! as SliverMultiBoxAdaptorParentData)..layoutOffset = indexToLayoutOffset(-1, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = indexToLayoutOffset(-1, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          _getChildConstraints(index),
          after: trailingChildWithLayout,
        );
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = indexToLayoutOffset(-1, index);
          break;
        }
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(
        -1,
        childParentData.index!,
      );
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(-1, firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(-1, lastIndex + 1);

    assert(
      firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance,
    );
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite ? getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, -1) : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow: (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint) || constraints.scrollOffset > 0.0,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
