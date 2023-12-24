import 'package:flutter/rendering.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/utils/action.dart';

class PhotolineRenderSliverMultiBoxAdaptor extends RenderSliverMultiBoxAdaptor {
  PhotolineRenderSliverMultiBoxAdaptor({
    required PhotolineState photoline,
    required PhotolineController controller,
    required super.childManager,
    required bool updater,
  })  : _photoline = photoline,
        _controller = controller,
        _updater = updater;

  int get _count => _controller.count;

  // -- updater
  bool _updater;

  set updater(bool value) {
    if (_updater == value) return;
    _updater = value;
    markNeedsLayout();
  }

  // -- photoline
  PhotolineState _photoline;

  PhotolineState get photoline => _photoline;

  set photoline(PhotolineState value) {
    if (_photoline == value) return;
    _photoline = value;
    markNeedsLayout();
  }

  // -- controller
  PhotolineController _controller;

  PhotolineController get controller => _controller;

  set controller(PhotolineController value) {
    if (_controller == value) return;
    _controller = value;
    markNeedsLayout();
  }

  /// [RenderSliverFillViewport.performLayout]
  @override
  void performLayout() {
    if (photoline.positionOpen.isNotEmpty) return _performWidth();
    return switch (controller.action) {
      PhotolineAction.open => _performOpen(),
      PhotolineAction.opening || PhotolineAction.closing => _performWidth(),
      PhotolineAction.close => _performClose(),
      PhotolineAction.drag => _performDrag(),
    };
  }

  void _performWidth() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) => constraints.asBoxConstraints(minExtent: width, maxExtent: width);

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;

    final p = photoline.positionOpen[0];
    if (firstChild == null) addInitialChild();
    firstChild!.layout(bc(p.width.current));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = p.offset.current + scrollOffset;

    RenderBox curBox = firstChild!;

    final count = _count;

    for (int i = 1; i < count; i++) {
      RenderBox? child = childAfter(curBox);

      final p = photoline.positionOpen[i];

      if (child == null || indexOf(child) != i) {
        child = insertAndLayoutChild(bc(p.width.current), after: curBox);
      } else {
        child.layout(bc(p.width.current));
      }

      curBox = child!;
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = p.offset.current + scrollOffset;
    }

    geometry = SliverGeometry(
      //scrollExtent: widthOpen * count,
      scrollExtent: double.infinity,
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0,
        to: double.infinity,
      ),
      maxPaintExtent: double.infinity,
      hasVisualOverflow: true,
    );

    childManager.didFinishLayout();
  }

  void _performOpen() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) => constraints.asBoxConstraints(minExtent: width, maxExtent: width);
    final count = _count;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final widthOpen = constraints.viewportMainAxisExtent * _photoline.widget.controller.openRatio;
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    final scrollExtent = widthOpen * count;

    if (firstChild == null) addInitialChild();
    double itemWidth = widthOpen;
    double itemOffset = 0;
    if (itemWidth > scrollOffset) {
      itemWidth -= scrollOffset;
      itemOffset += scrollOffset;
    }
    firstChild!.layout(bc(itemWidth));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = itemOffset;

    RenderBox curBox = firstChild!;
    int indexOffset = 0;
    for (int indexReal = 1; indexReal < count; indexReal++) {
      RenderBox? child = childAfter(curBox);

      indexOffset++;

      itemWidth = widthOpen;
      itemOffset = indexOffset * widthOpen;

      // left
      final double leftDiff = scrollOffset - itemOffset;
      if (leftDiff > 0 && itemWidth > leftDiff) {
        itemWidth -= leftDiff;
        itemOffset += leftDiff;
      }

      // right
      final double rightDiff = (itemWidth + itemOffset) - (scrollOffset + constraints.viewportMainAxisExtent);
      if (rightDiff > 0 && itemWidth > rightDiff) {
        itemWidth -= rightDiff;
      }

      if (child == null || indexOf(child) != indexReal) {
        child = insertAndLayoutChild(bc(itemWidth), after: curBox);
      } else {
        child.layout(bc(itemWidth));
      }
      curBox = child!;
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = itemOffset;
    }

    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0,
        //to: scrollExtent,
        to: double.infinity,
      ),
      maxPaintExtent: double.infinity,
      hasVisualOverflow: true,
    );

    //..setDidUnderflow(true)
    childManager.didFinishLayout();
  }

  void _performDrag() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) => constraints.asBoxConstraints(minExtent: width, maxExtent: width);
    final count = _count;
    final size = controller.size;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final widthOpen = constraints.viewportMainAxisExtent * _photoline.widget.controller.openRatio;
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;

    final fp = controller.positionDrag[0];
    if (firstChild == null) addInitialChild();
    firstChild!.layout(bc(size.close));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = fp.offset + scrollOffset;

    RenderBox curBox = firstChild!;

    for (int i = 1; i < count; i++) {
      RenderBox? child = childAfter(curBox);

      final p = controller.positionDrag[i];

      if (child == null || indexOf(child) != i) {
        child = insertAndLayoutChild(bc(size.close), after: curBox);
      } else {
        child.layout(bc(size.close));
      }

      curBox = child!;
      double offset = p.offset;
      if (i == controller.pageDragInitial) {
        offset = offset.clamp(0, constraints.viewportMainAxisExtent - size.close);
      }

      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = offset + scrollOffset;
    }

    geometry = SliverGeometry(
      scrollExtent: widthOpen * count,
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0,
        to: double.infinity,
      ),
      maxPaintExtent: double.infinity,
      hasVisualOverflow: true,
    );

    childManager.didFinishLayout();
  }

  void _performClose() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) => constraints.asBoxConstraints(minExtent: width, maxExtent: width);

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final widthClose = constraints.viewportMainAxisExtent * _controller.closeRatio;
    final count = _count;

    final List<double> ws = [];
    final List<double> os = [];

    final mod = _controller.mod;

    for (int i = 0; i < count; i++) {
      final double o = i == 0 ? 0 : os[i - 1] + ws[i - 1];
      final double w;
      if (i < mod.length && mod[i] != null) {
        w = mod[i]!.t * widthClose;
      } else {
        w = widthClose;
      }
      os.add(o);
      ws.add(w);
    }

    if (firstChild == null) addInitialChild();
    firstChild!.layout(bc(ws[0]));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = os[0];

    RenderBox curBox = firstChild!;
    for (int i = 1; i < count; i++) {
      RenderBox? child = childAfter(curBox);

      if (child == null || indexOf(child) != i) {
        child = insertAndLayoutChild(bc(ws[i]), after: curBox);
      } else {
        child.layout(bc(ws[i]));
      }
      curBox = child!;
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = os[i];
    }

    final scrollExtent = os.last + ws.last;

    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0,
        //to: scrollExtent,
        to: double.infinity,
      ),
      maxPaintExtent: double.infinity,
      hasVisualOverflow: true,
    );

    //..setDidUnderflow(true)
    childManager.didFinishLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    final Offset mainAxisUnit, crossAxisUnit, originOffset;
    final bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry!.paintExtent);
        addExtent = true;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry!.paintExtent, 0.0);
        addExtent = true;
    }
    RenderBox? child = firstChild;
    RenderBox? dragBox;
    Offset? dragOffset;

    while (child != null) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx + mainAxisUnit.dx * mainAxisDelta + crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy + mainAxisUnit.dy * mainAxisDelta + crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) childOffset += mainAxisUnit * paintExtentOf(child);

      bool canPaint = mainAxisDelta < constraints.remainingPaintExtent && mainAxisDelta + paintExtentOf(child) > 0;

      if (controller.action == PhotolineAction.drag && indexOf(child) == controller.pageDragInitial) {
        canPaint = false;
        dragBox = child;
        dragOffset = childOffset;
      }

      if (canPaint) context.paintChild(child, childOffset);
      child = childAfter(child);
    }

    if (dragBox != null && dragOffset != null) {
      //context.paintChild(dragBox, dragOffset);
    }
  }
}
