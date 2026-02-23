import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/photoline/controller.dart';
import 'package:photoline/src/photoline/photoline.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/draw_image.dart';

class PhotolineRenderSliverMultiBoxAdaptor extends RenderSliverMultiBoxAdaptor {
  PhotolineRenderSliverMultiBoxAdaptor({
    required PhotolineState photoline,
    required PhotolineController controller,
    required super.childManager,
  }) : _photoline = photoline,
       _controller = controller;

  int get _count => _controller.count;

  @override
  void attach(PipelineOwner owner) {
    _controller.photoline?.animationRepaint.addListener(markNeedsLayout);
    //_controller.photoline?.animationPosition.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    _controller.photoline?.animationRepaint.removeListener(markNeedsLayout);
    //_controller.photoline?.animationPosition.removeListener(markNeedsLayout);
    super.detach();
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

  /// Helper method to draw image with proper scaling and filtering
  void _drawImage({
    required Canvas canvas,
    required ui.Image image,
    required double width,
    required double height,
    required double dx,
    required double dy,
    required double opacity,
    ui.ImageFilter? filter,
  }) {
    drawPhotolineImage(
      canvas: canvas,
      image: image,
      width: width,
      height: height,
      dx: dx,
      dy: dy,
      opacity: opacity,
      filter: filter,
    );
  }

  /// --- paint
  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    RenderBox? child = childAfter(firstChild!);
    RenderBox? dragBox;
    Offset? dragOffset;

    final vp = constraints.viewportMainAxisExtent;

    var index = -1;

    while (child != null) {
      index++;
      final double cdx = childMainAxisPosition(child);
      final double cdy = childCrossAxisPosition(child);
      final childOffset = Offset(
        offset.dx + cdx,
        offset.dy + cdy,
      );

      var canPaint = true;

      switch (controller.action.value) {
        case PhotolineAction.close:
          if (childOffset.dx + child.size.width <= precisionErrorTolerance || childOffset.dx > vp - precisionErrorTolerance) {
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
          canPaint = cdx < constraints.remainingPaintExtent && cdx + paintExtentOf(child) > 0;
        case PhotolineAction.upload:
      }
      if (child.size.width == 0) canPaint = false;
      if (dragBox != null && child == dragBox) canPaint = false;

      final loader = _controller.getLoader?.call(index);

      if (canPaint && loader != null) {
        loader.spawn();

        final canvas = context.canvas;
        final size = child.size;
        final w = size.width;
        final h = size.height;
        final imrect = Rect.fromLTWH(childOffset.dx, childOffset.dy, w, h);

        canvas
          ..save()
          ..clipRect(imrect);

        final double opacity = loader.opacity;

        // Draw blur with inverse opacity
        if (loader.blur != null && opacity < 1) {
          _drawImage(
            canvas: canvas,
            image: loader.blur!,
            width: w,
            height: h,
            dx: cdx,
            dy: cdy,
            opacity: 1,
            filter: ui.ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
              tileMode: TileMode.mirror,
            ),
          );
        } else if (loader.color != null) {
          canvas.drawRect(
            imrect,
            Paint()
              ..color = loader.color!
              ..style = PaintingStyle.fill,
          );
        }

        // Draw image with opacity
        if (loader.image != null) {
          _drawImage(
            canvas: canvas,
            image: loader.image!,
            width: w,
            height: h,
            dx: cdx,
            dy: cdy,
            opacity: opacity,
          );
        }

        if (loader.stripe != null) {
          context.canvas.drawRect(
            Rect.fromLTWH(cdx, cdy, math.min(w, 10), h),
            Paint()
              ..color = loader.stripe!
              ..style = PaintingStyle.fill,
          );
        }

        canvas.restore();

        context.paintChild(child, childOffset);
      }
      child = childAfter(child);
    }

    if (dragBox != null && dragOffset != null) {
      //context.paintChild(dragBox, dragOffset);
    }
  }

  /// --- Perform
  RenderBox _firstChild({int index = 0}) {
    if (firstChild == null) addInitialChild(index: index);
    firstChild!.layout(const BoxConstraints(maxHeight: 0, maxWidth: 0));
    return firstChild!;
  }

  SliverGeometry _geometry(double scrollExtent) => SliverGeometry(
    scrollExtent: scrollExtent,
    paintExtent: calculatePaintOffset(constraints, from: 0, to: double.infinity),
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
      PhotolineAction.opening || PhotolineAction.closing || PhotolineAction.upload => _performWidth(),
    };
  }

  void _performWidth() {
    final constraints = this.constraints;

    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset;
    final count = _count;

    RenderBox prev = _firstChild();

    for (var index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

      final p = photoline.positionWidth[index];
      final offset = p.offset.current + scrollOffset;
      final width = p.width.current;

      final c = constraints.asBoxConstraints(minExtent: width, maxExtent: width);
      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = offset;
      prev = child;
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

    RenderBox prev = _firstChild();

    for (var index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

      var itemWidth = widthOpen;
      double itemOffset = index * widthOpen;

      if (_controller.useOpenSideResize) {
        final double itemViewOffset = itemOffset - scrollOffset;
        final firstIndex = controller.getPagerIndexOffset > 0 ? 1 : 0;
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

      final c = constraints.asBoxConstraints(minExtent: itemWidth, maxExtent: itemWidth);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = itemOffset;

      prev = child;
    }

    geometry = _geometry(widthOpen * count);
    childManager.didFinishLayout();
  }

  void _performClose() {
    final constraints = this.constraints;
    childManager
      ..didStartLayout()
      ..setDidUnderflow(false);

    final vw = constraints.viewportMainAxisExtent;
    final wc = vw * _controller.closeRatio;
    final count = _controller.getPhotoCount();
    final mod = _controller.mod;

    double offset = 0;
    double width = 0;

    RenderBox? prev = _firstChild();

    _controller.getViewCount(vw);

    for (var index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev!);
      offset = offset + width;
      width = index < mod.length && mod[index] != null ? mod[index]!.t * wc : wc;
      final c = constraints.asBoxConstraints(minExtent: width, maxExtent: width);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = offset;
      prev = child;
    }

    geometry = _geometry(offset + width);
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

    RenderBox prev = _firstChild();

    for (var index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

      double offset = controller.positionDrag[index].offset;
      if (index == controller.pageDragInitial) {
        offset = offset.clamp(0, constraints.viewportMainAxisExtent - size.close);
      }

      offset += scrollOffset;
      final width = size.close;

      final c = constraints.asBoxConstraints(minExtent: width, maxExtent: width);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset = offset;

      prev = child;
    }

    //scrollExtent: widthOpen * count,
    geometry = _geometry(double.infinity);
    childManager.didFinishLayout();
  }
}
