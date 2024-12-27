import 'dart:math' as math;
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

  @override
  void attach(PipelineOwner owner) {
    _controller.photoline?.animationRepaint.addListener(_repaintListener);
    super.attach(owner);
  }

  @override
  void detach() {
    _controller.photoline?.animationRepaint.removeListener(_repaintListener);
    super.detach();
  }

  void _repaintListener() {
    markNeedsLayout();
  }

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
      final double cdx = childMainAxisPosition(child);
      final double cdy = childCrossAxisPosition(child);
      final Offset childOffset = Offset(
        offset.dx + cdx,
        offset.dy + cdy,
      );

      bool canPaint = true;

      switch (controller.action.value) {
        case PhotolineAction.close:
          if (childOffset.dx + child.size.width <= precisionErrorTolerance ||
              childOffset.dx > vp - precisionErrorTolerance) {
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
          canPaint = cdx < constraints.remainingPaintExtent &&
              cdx + paintExtentOf(child) > 0;
        case PhotolineAction.upload:
      }
      if (child.size.width == 0) canPaint = false;

      final velocity = _controller.photoline?.animationRepaint.velocity ?? 0;
      final uri = _controller.getUri(index).cached;
      if (canPaint) {
        uri.spawn();

        if (uri.image != null) {
          uri.opacity = velocity;
        }
        final double opacity = uri.opacity;

        final canvas = context.canvas;
        final size = child.size;
        final w = size.width;
        final h = size.height;

        if (uri.color != null) {
          canvas.drawRect(
            Rect.fromLTWH(childOffset.dx, childOffset.dy, w, h),
            Paint()
              ..color = uri.color!.withValues(alpha: 1 - opacity)
              ..style = PaintingStyle.fill,
          );
        }

        if (uri.image != null) {
          const offsetX = .5;
          const offsetY = .5;

          final image = uri.image!;
          final iw = image.width.toDouble();
          final ih = image.height.toDouble();

          final r = math.min(w / iw, h / ih);

          double nw = iw * r, nh = ih * r, ar = 1;
          if (nw < w) ar = w / nw;
          if ((ar - 1).abs() < 1e-14 && nh < h) ar = h / nh;

          nw *= ar;
          nh *= ar;

          final double cw = math.min(iw / (nw / w), iw);
          final double ch = math.min(ih / (nh / h), ih);
          final double cx = math.max((iw - cw) * offsetX, 0);
          final double cy = math.max((ih - ch) * offsetY, 0);

          canvas.drawAtlas(
            image,
            [
              RSTransform.fromComponents(
                rotation: 0,
                scale: w / cw,
                anchorX: cw * .5,
                anchorY: ch * .5,
                translateX: cdx + w * .5,
                translateY: cdy + h * .5,
              ),
            ],
            [
              Rect.fromLTWH(cx, cy, cw, ch),
            ],
            null,
            BlendMode.srcOver,
            null,
            Paint()
              ..isAntiAlias = true
              ..filterQuality = FilterQuality.medium
              ..color = Color.fromRGBO(0, 0, 0, opacity),
          );
        }

        context.paintChild(child, childOffset);
      } else {
        if (uri.image != null) {
          uri.opacity = -1;
        }
      }

      //controller.canPaint(index, canPaint);
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

    RenderBox prev = _firstChild();

    for (int index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

      final p = photoline.positionWidth[index];
      final offset = p.offset.current + scrollOffset;
      final width = p.width.current;

      final c =
          constraints.asBoxConstraints(minExtent: width, maxExtent: width);
      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          offset;
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

    for (int index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

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

      final c = constraints.asBoxConstraints(
          minExtent: itemWidth, maxExtent: itemWidth);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          itemOffset;

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

    //final ts = DateTime.now().millisecondsSinceEpoch;

    for (int index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev!);
      offset = offset + width;
      width =
          index < mod.length && mod[index] != null ? mod[index]!.t * wc : wc;
      final c =
          constraints.asBoxConstraints(minExtent: width, maxExtent: width);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          offset;
      prev = child;
    }

    //print("${DateTime.now().millisecondsSinceEpoch - ts}");

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

    for (int index = 0; index < count; index++) {
      RenderBox? child = childAfter(prev);

      double offset = controller.positionDrag[index].offset;
      if (index == controller.pageDragInitial) {
        offset =
            offset.clamp(0, constraints.viewportMainAxisExtent - size.close);
      }

      offset += scrollOffset;
      final width = size.close;

      final c =
          constraints.asBoxConstraints(minExtent: width, maxExtent: width);

      if (child == null || indexOf(child) != index - 1) {
        child = insertAndLayoutChild(c, after: prev);
      } else {
        child.layout(c);
      }
      (child!.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
          offset;

      prev = child;
    }

    //scrollExtent: widthOpen * count,
    geometry = _geometry(double.infinity);
    childManager.didFinishLayout();
  }
}
