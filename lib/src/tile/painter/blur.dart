import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';

class BlurPainter extends CustomPainter {
  BlurPainter({
    required this.blur,
    required this.imageOpacity,
  });

  final ui.Image? blur;
  final double imageOpacity;

  /// [Image], [LinearGradient]
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || imageOpacity >= 10 || blur == null || blur!.width == 0 || blur!.height == 0) return;
    final w = size.width, h = size.height;

    const offsetX = .5;
    const offsetY = .5;

    final iw = blur!.width.toDouble();
    final ih = blur!.height.toDouble();

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

    final Rect ra = Rect.fromLTWH(cx, cy, cw, ch);
    final Rect rb = Rect.fromLTWH(0, 0, w, h);

    const double s = 20;

    canvas
      ..clipRect(rb)
      ..drawImageRect(
        blur!,
        ra,
        rb,
        Paint()
          ..color = const Color.fromRGBO(0, 0, 0, 1)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: s, sigmaY: s, tileMode: TileMode.mirror),
      );
  }

  @override
  bool shouldRepaint(BlurPainter oldDelegate) => blur != oldDelegate.blur;
}
