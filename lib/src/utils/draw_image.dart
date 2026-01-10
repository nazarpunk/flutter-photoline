import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Helper method to draw image with proper scaling and filtering
/// Handles NaN protection and web blur artifacts
void drawPhotolineImage({
  required Canvas canvas,
  required ui.Image image,
  required double width,
  required double height,
  required double dx,
  required double dy,
  required double opacity,
  ui.ImageFilter? filter,
}) {
  const offsetX = .5;
  const offsetY = .5;
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();

  // Защита от деления на ноль
  if (iw <= 0 || ih <= 0 || width <= 0 || height <= 0) return;

  // For web blur: expand image and clip to hide edge artifacts
  const bool hasBlur = kIsWeb;
  const double blurExpand = hasBlur ? 20 : 0; // Expand by blur radius * 2

  final double renderWidth = width + blurExpand * 2;
  final double renderHeight = height + blurExpand * 2;
  final double renderDx = dx - blurExpand;
  final double renderDy = dy - blurExpand;

  final r = math.min(renderWidth / iw, renderHeight / ih);

  double nw = iw * r, nh = ih * r, ar = 1;
  if (nw < renderWidth && nw > 0) ar = renderWidth / nw;
  if ((ar - 1).abs() < 1e-14 && nh < renderHeight && nh > 0) ar = renderHeight / nh;

  nw *= ar;
  nh *= ar;

  // Дополнительная проверка после применения ar
  if (nw <= 0 || nh <= 0) return;

  final double cw = math.min(iw / (nw / renderWidth), iw);
  final double ch = math.min(ih / (nh / renderHeight), ih);

  // Проверка на валидность результатов
  if (cw <= 0 || ch <= 0 || !cw.isFinite || !ch.isFinite) return;

  final double cx = math.max((iw - cw) * offsetX, 0);
  final double cy = math.max((ih - ch) * offsetY, 0);

  final scale = renderWidth / cw;

  // Финальная проверка перед отрисовкой
  if (!scale.isFinite || !cx.isFinite || !cy.isFinite) return;

  // Clip to original rect to hide blur artifacts on edges
  if (hasBlur) {
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(dx, dy, width, height));
  }

  canvas.drawAtlas(
    image,
    [
      RSTransform.fromComponents(
        rotation: 0,
        scale: scale,
        anchorX: cw * .5,
        anchorY: ch * .5,
        translateX: renderDx + renderWidth * .5,
        translateY: renderDy + renderHeight * .5,
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
      ..filterQuality = FilterQuality.high
      ..color = Color.fromRGBO(0, 0, 0, opacity)
      ..imageFilter = filter,
  );

  if (hasBlur) {
    canvas.restore();
  }
}
