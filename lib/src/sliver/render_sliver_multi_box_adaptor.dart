import 'package:flutter/foundation.dart';
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
    return switch (controller.action.value) {
      PhotolineAction.open => _performOpen(),
      PhotolineAction.opening || PhotolineAction.closing => _performWidth(),
      PhotolineAction.close => _performClose(),
      PhotolineAction.drag => _performDrag(),
    };
  }

  void _performWidth() {
    print('performWidth');
    final constraints = this.constraints;

    BoxConstraints bc(double width) =>
        constraints.asBoxConstraints(minExtent: width, maxExtent: width);

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset;

    final p = photoline.positionOpen[0];
    if (firstChild == null) addInitialChild();

    firstChild!.layout(bc(p.width.current));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        p.offset.current + scrollOffset;

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
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          p.offset.current + scrollOffset;
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
    print('performOpen');
    final constraints = this.constraints;
    BoxConstraints bc(double width) =>
        constraints.asBoxConstraints(minExtent: width, maxExtent: width);
    final count = _count;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final vp = constraints.viewportMainAxisExtent;

    final widthOpen = vp * _controller.openRatio;
    final widthSide = (vp - widthOpen) * .5;
    final double scrollOffset = constraints.scrollOffset;

    print('so|${scrollOffset.toStringAsFixed(2)}|${constraints.precedingScrollExtent}|${constraints.overlap}');

    if (firstChild == null) addInitialChild();
    double itemWidth = widthOpen;
    double itemOffset = 0;
    if (_controller.useOpenSideResize && itemWidth > scrollOffset) {
      //itemWidth -= scrollOffset;
      itemOffset += scrollOffset;
    }

    firstChild!.layout(bc(itemWidth));
    //(firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = itemOffset;


    RenderBox curBox = firstChild!;
    int indexOffset = 0;
    for (int index = 1; index < count; index++) {
      RenderBox? child = childAfter(curBox);

      indexOffset++;

      itemWidth = widthOpen;
      itemOffset = indexOffset * widthOpen;

      if (_controller.useOpenSideResize) {
        final double itemViewOffset = itemOffset - scrollOffset;
        final int firstIndex = controller.getPagerIndexOffset() > 0 ? 1 : 0;
        final int lastIndex = count - 1;

        if (_controller.useOpenSideResizeScale) {
          // left
          if (itemViewOffset < 0 && itemViewOffset > -widthOpen) {
            final sm = index >= lastIndex - 1 ? widthSide * 2 : widthSide;
            final wcur = widthOpen + itemViewOffset;
            final dt = (wcur - sm) / (widthOpen - sm);
            double off = itemViewOffset * (1 - dt);
            if (itemViewOffset < widthSide - widthOpen) {
              off = itemViewOffset;
            }
            itemWidth += off;
            itemOffset -= off;
          }

          // right
          if (itemViewOffset > widthSide * 2 && itemViewOffset < vp) {
            final rdiff = vp - (itemViewOffset + itemWidth);
            final sm = index <= firstIndex + 1 ? widthSide * 2 : widthSide;
            final wcur = widthOpen + rdiff;
            final dt = (wcur - sm) / (widthOpen - sm);
            double off = rdiff * (1 - dt);
            if (itemViewOffset > vp - widthSide) {
              off = rdiff;
            }
            itemWidth += off;
          }
        } else {
          // left
          if (itemViewOffset < 0 && itemViewOffset > -widthOpen) {
            itemWidth += itemViewOffset;
            itemOffset -= itemViewOffset;
          }

          // right
          if (itemViewOffset > widthSide * 2 && itemViewOffset < vp) {
            final rdiff = vp - (itemViewOffset + itemWidth);
            if (rdiff < 0) {
              itemWidth += rdiff;
            }
          }
        }
      }

      if (itemWidth < 0) itemWidth = 0;

      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(bc(itemWidth), after: curBox);
      } else {
        child.layout(bc(itemWidth));
      }

      curBox = child!;
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          itemOffset;
    }

    geometry = SliverGeometry(
      scrollExtent: widthOpen * count,
      paintExtent: calculatePaintOffset(
        constraints,
        from: -500,
        //to: scrollExtent,
        to: double.infinity,
      ),
      maxPaintExtent: double.infinity,
      hasVisualOverflow: true,
    );

    //..setDidUnderflow(true)
    childManager.didFinishLayout();
  }

  void _performClose() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) =>
        constraints.asBoxConstraints(minExtent: width, maxExtent: width);

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final widthClose =
        constraints.viewportMainAxisExtent * _controller.closeRatio;
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
    if (firstChild == null) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    firstChild!.layout(bc(ws[0]));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        os[0];

    RenderBox curBox = firstChild!;
    for (int i = 1; i < count; i++) {
      RenderBox? child = childAfter(curBox);

      if (child == null || indexOf(child) != i) {
        child = insertAndLayoutChild(bc(ws[i]), after: curBox);
      } else {
        child.layout(bc(ws[i]));
      }
      curBox = child!;
      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          os[i];
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
      //hasVisualOverflow: true,
    );

    //..setDidUnderflow(true)
    childManager.didFinishLayout();
  }

  void _performDrag() {
    final constraints = this.constraints;
    BoxConstraints bc(double width) =>
        constraints.asBoxConstraints(minExtent: width, maxExtent: width);
    final count = _count;
    final size = controller.size;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset;

    if (controller.positionDrag.isEmpty) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final fp = controller.positionDrag[0];
    if (firstChild == null) addInitialChild();
    firstChild!.layout(bc(size.close));
    (firstChild!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        fp.offset + scrollOffset;

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
        offset =
            offset.clamp(0, constraints.viewportMainAxisExtent - size.close);
      }

      (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          offset + scrollOffset;
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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    RenderBox? child = firstChild;
    RenderBox? dragBox;
    Offset? dragOffset;

    final vp = constraints.viewportMainAxisExtent;

    int index = -1;

    while (child != null) {
      index++;
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      final Offset childOffset = Offset(
        offset.dx + mainAxisDelta,
        offset.dy + crossAxisDelta,
      );

      bool canPaint = true;

      switch (controller.action.value) {
        case PhotolineAction.close:
          if (childOffset.dx + child.size.width <= precisionErrorTolerance ||
              childOffset.dx >= vp - precisionErrorTolerance) {
            canPaint = false;
          }
        case PhotolineAction.drag:
          if (indexOf(child) == controller.pageDragInitial) {
            canPaint = false;
            dragBox = child;
            dragOffset = childOffset;
          }
        case PhotolineAction.open:
        case PhotolineAction.opening:
        case PhotolineAction.closing:
          canPaint = mainAxisDelta < constraints.remainingPaintExtent &&
              mainAxisDelta + paintExtentOf(child) > 0;
      }
      if (canPaint) context.paintChild(child, childOffset);
      child = childAfter(child);
      controller.canPaint(index, canPaint);
    }

    if (dragBox != null && dragOffset != null) {
      //context.paintChild(dragBox, dragOffset);
    }
  }
}
