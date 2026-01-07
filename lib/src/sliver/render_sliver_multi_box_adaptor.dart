import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/photoline/controller.dart';
import 'package:photoline/src/photoline/photoline.dart';
import 'package:photoline/src/utils/action.dart';

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
    //_controller.photoline?.animationRepaint.addListener(markNeedsPaint);
    //_controller.photoline?.animationPosition.addListener(markNeedsPaint);
    super.attach(owner);
  }

  @override
  void detach() {
    //_controller.photoline?.animationRepaint.removeListener(markNeedsPaint);
    //_controller.photoline?.animationPosition.removeListener(markNeedsPaint);
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

  void paintLoader(PaintingContext context, Offset offset) {
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

        void img({
          required ui.Image image,
          required double opacity,
          ui.ImageFilter? filter,
        }) {
          const offsetX = .5;
          const offsetY = .5;
          final iw = image.width.toDouble();
          final ih = image.height.toDouble();

          // Защита от деления на ноль
          if (iw <= 0 || ih <= 0 || w <= 0 || h <= 0) return;

          final r = math.min(w / iw, h / ih);

          double nw = iw * r, nh = ih * r, ar = 1;
          if (nw < w && nw > 0) ar = w / nw;
          if ((ar - 1).abs() < 1e-14 && nh < h && nh > 0) ar = h / nh;

          nw *= ar;
          nh *= ar;

          // Дополнительная проверка после применения ar
          if (nw <= 0 || nh <= 0) return;

          final double cw = math.min(iw / (nw / w), iw);
          final double ch = math.min(ih / (nh / h), ih);

          // Проверка на валидность результатов
          if (cw <= 0 || ch <= 0 || !cw.isFinite || !ch.isFinite) return;

          final double cx = math.max((iw - cw) * offsetX, 0);
          final double cy = math.max((ih - ch) * offsetY, 0);

          final scale = w / cw;

          // Финальная проверка перед отрисовкой
          if (!scale.isFinite || !cx.isFinite || !cy.isFinite) return;

          canvas.drawAtlas(
            image,
            [
              RSTransform.fromComponents(
                rotation: 0,
                scale: scale,
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
              ..color = Color.fromRGBO(0, 0, 0, opacity)
              ..imageFilter = filter,
          );
        }

        final double opacity = loader.opacity;

        // Draw blur with inverse opacity
        if (loader.blur != null && opacity < 1) {
          img(
            image: loader.blur!,
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
          img(
            image: loader.image!,
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

  /// --- paint
  @override
  void paint(PaintingContext context, Offset offset) {
    if (controller.getLoader != null) {
      return paintLoader(context, offset);
    }

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

      final uri = _controller.getUri(index)?.cached;

      if (canPaint && uri != null) {
        uri.spawn();

        final canvas = context.canvas;
        final size = child.size;
        final w = size.width;
        final h = size.height;
        final imrect = Rect.fromLTWH(childOffset.dx, childOffset.dy, w, h);

        canvas
          ..save()
          ..clipRect(imrect);

        void img({
          required ui.Image image,
          required double opacity,
          ui.ImageFilter? filter,
        }) {
          const offsetX = .5;
          const offsetY = .5;
          final iw = image.width.toDouble();
          final ih = image.height.toDouble();

          // Защита от деления на ноль
          if (iw <= 0 || ih <= 0 || w <= 0 || h <= 0) return;

          final r = math.min(w / iw, h / ih);

          double nw = iw * r, nh = ih * r, ar = 1;
          if (nw < w && nw > 0) ar = w / nw;
          if ((ar - 1).abs() < 1e-14 && nh < h && nh > 0) ar = h / nh;

          nw *= ar;
          nh *= ar;

          // Дополнительная проверка после применения ar
          if (nw <= 0 || nh <= 0) return;

          final double cw = math.min(iw / (nw / w), iw);
          final double ch = math.min(ih / (nh / h), ih);

          // Проверка на валидность результатов
          if (cw <= 0 || ch <= 0 || !cw.isFinite || !ch.isFinite) return;

          final double cx = math.max((iw - cw) * offsetX, 0);
          final double cy = math.max((ih - ch) * offsetY, 0);

          final scale = w / cw;

          // Финальная проверка перед отрисовкой
          if (!scale.isFinite || !cx.isFinite || !cy.isFinite) return;

          canvas.drawAtlas(
            image,
            [
              RSTransform.fromComponents(
                rotation: 0,
                scale: scale,
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
              ..color = Color.fromRGBO(0, 0, 0, opacity)
              ..imageFilter = filter,
          );
        }

        if (uri.image != null) {
          if (uri.imageLoaded) {
            if (uri.opacity < 1) {
              uri.opacity = 1;
            }
          } else {
            uri.opacity = 1;
          }
        }

        final double opacity = uri.opacity;
        final double opacityback = 1 - opacity;

        // Show blur/placeholder with fading opacity while image fades in
        if (opacity < 1) {
          if (uri.blur != null) {
            img(
              image: uri.blur!,
              opacity: 1,
              filter: ui.ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
                tileMode: TileMode.mirror,
              ),
            );
          } else {
            if (uri.color != null) {
              canvas.drawRect(
                imrect,
                Paint()
                  ..color = uri.color!.withValues(alpha: opacityback)
                  ..style = PaintingStyle.fill,
              );
            }
          }
        }

        if (uri.image == null) {
          final im = _controller.getImage.call(index);
          if (im != null) {
            img(
              image: im,
              opacity: 1,
              filter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0, 0, 0, 1, 0,
              ]),
            );
          }
        } else {
          img(
            image: uri.image!,
            opacity: Curves.easeOut.transform(opacity),
          );
        }

        if (uri.stripe != null) {
          context.canvas.drawRect(
            Rect.fromLTWH(cdx, cdy, math.min(w, 10), h),
            Paint()
              ..color = uri.stripe!
              ..style = PaintingStyle.fill,
          );
        }

        canvas.restore();

        context.paintChild(child, childOffset);
      } else {
        if (uri?.image != null) {
          uri!.opacity = -1;
        }
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
