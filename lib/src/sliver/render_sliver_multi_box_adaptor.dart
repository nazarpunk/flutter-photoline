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

  /// -- updater
  bool _updater;

  set updater(bool value) {
    if (_updater == value) return;
    _updater = value;
    markNeedsLayout();
  }

  /// -- photoline
  PhotolineState _photoline;

  PhotolineState get photoline => _photoline;

  set photoline(PhotolineState value) {
    if (_photoline == value) return;
    _photoline = value;
    markNeedsLayout();
  }

  /// -- controller
  PhotolineController _controller;

  PhotolineController get controller => _controller;

  set controller(PhotolineController value) {
    if (_controller == value) return;
    _controller = value;
    markNeedsLayout();
  }

  /// --- paint
  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    RenderBox? child = childAfter(firstChild!);
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
              childOffset.dx > vp + precisionErrorTolerance) {
            canPaint = false;
          }
        case PhotolineAction.drag:
          if (indexOf(child) - 1 == controller.pageDragInitial) {
            canPaint = false;
            dragBox = child;
            dragOffset = childOffset;
          }
        case PhotolineAction.open:
        case PhotolineAction.opening:
        case PhotolineAction.closing:
          canPaint = mainAxisDelta < constraints.remainingPaintExtent &&
              mainAxisDelta + paintExtentOf(child) > 0;
        case PhotolineAction.upload:
      }
      //if (child.size.width == 0) canPaint = false;

      if (canPaint) context.paintChild(child, childOffset);
      controller.canPaint(index, canPaint);
      child = childAfter(child);
    }

    if (dragBox != null && dragOffset != null) {
      //context.paintChild(dragBox, dragOffset);
    }
  }

  /// --- Perform
  RenderBox get _firstChild {
    if (firstChild == null) addInitialChild();
    firstChild!.layout(const BoxConstraints(maxHeight: 0, maxWidth: 0));
    return firstChild!;
  }

  RenderBox _childLayout(
      {required SliverConstraints constraints,
      required int index,
      required RenderBox? prev,
      required RenderBox? child,
      required double offset,
      required double width}) {
    final c = constraints.asBoxConstraints(minExtent: width, maxExtent: width);

    if (child == null || indexOf(child) != index - 1) {
      try {
        child = insertAndLayoutChild(c, after: prev);
      } catch (e) {
        print('⚠️ Build dirty widget');
      }
    } else {
      child.layout(c);
    }
    (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        offset;

    return child;
  }

  SliverGeometry _geometry(double scrollExtent) => SliverGeometry(
        scrollExtent: scrollExtent,
        paintExtent:
            calculatePaintOffset(constraints, from: 0, to: double.infinity),
        maxPaintExtent: double.infinity,
        hasVisualOverflow: true,
      );

  /// [RenderSliverFillViewport.performLayout]
  @override
  void performLayout() {
    //if (photoline.positionWidth.isNotEmpty) return _performWidth();
    return switch (controller.action.value) {
      PhotolineAction.open => _performOpen(),
      PhotolineAction.close => _performClose(),
      PhotolineAction.drag => _performDrag(),
      PhotolineAction.opening ||
      PhotolineAction.closing ||
      PhotolineAction.upload =>
        _performWidth(),
    };
  }

  void _performWidth() {
    final constraints = this.constraints;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset;
    final count = _count;

    RenderBox prev = _firstChild;

    for (int index = 0; index < count; index++) {
      final RenderBox? child = childAfter(prev);

      final p = photoline.positionWidth[index];

      prev = _childLayout(
        constraints: constraints,
        index: index,
        prev: prev,
        child: child,
        offset: p.offset.current + scrollOffset,
        width: p.width.current,
      );
    }

    geometry = _geometry(double.infinity);
    childManager.didFinishLayout();
  }

  void _performOpen() {
    final constraints = this.constraints;
    final count = _count;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final vp = constraints.viewportMainAxisExtent;

    final widthOpen = vp * _controller.openRatio;
    final widthSide = (vp - widthOpen) * .5;
    final double scrollOffset = constraints.scrollOffset;

    //print('$vp | ${scrollOffset.toStringAsFixed(2)} | ${_controller.pos.maxScrollExtent}');

    RenderBox prev = _firstChild;

    for (int index = 0; index < count; index++) {
      final RenderBox? child = childAfter(prev);

      double itemWidth = widthOpen;
      double itemOffset = index * widthOpen;

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

      prev = _childLayout(
        constraints: constraints,
        index: index,
        prev: prev,
        child: child,
        offset: itemOffset,
        width: itemWidth,
      );
    }

    geometry = _geometry(widthOpen * count);
    childManager.didFinishLayout();
  }

  void _performClose() {
    final constraints = this.constraints;
    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final wc = constraints.viewportMainAxisExtent * _controller.closeRatio;
    final count = _count;
    final mod = _controller.mod;

    double po = 0;
    double pw = 0;

    RenderBox? prev = _firstChild;
    for (int i = 0; i < count; i++) {
      final RenderBox? child = childAfter(prev!);
      po = po + pw;
      pw = i < mod.length && mod[i] != null ? mod[i]!.t * wc : wc;

      prev = _childLayout(
        constraints: constraints,
        index: i,
        prev: prev,
        child: child,
        offset: po,
        width: pw,
      );
    }

    geometry = _geometry(po + pw);
    childManager.didFinishLayout();
  }

  void _performDrag() {
    final constraints = this.constraints;
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

    RenderBox prev = _firstChild;

    for (int index = 0; index < count; index++) {
      final RenderBox? child = childAfter(prev);

      double offset = controller.positionDrag[index].offset;
      if (index == controller.pageDragInitial) {
        offset =
            offset.clamp(0, constraints.viewportMainAxisExtent - size.close);
      }

      prev = _childLayout(
        constraints: constraints,
        index: index,
        prev: prev,
        child: child,
        offset: offset + scrollOffset,
        width: size.close,
      );
    }

    //scrollExtent: widthOpen * count,
    geometry = _geometry(double.infinity);
    childManager.didFinishLayout();
  }
}
