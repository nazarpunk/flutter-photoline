import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlurPainter extends CustomPainter {
  BlurPainter({
    required this.color,
    required this.blur,
    required this.imageOpacity,
    required this.sigma,
  });

  final Color? color;
  final ui.Image? blur;
  final double imageOpacity;
  final double sigma;

  /// [Image], [LinearGradient]
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || imageOpacity >= 1.0) return;

    if (blur == null || blur!.width == 0 || blur!.height == 0) {
      if (color != null) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = color!,
        );
      }
      return;
    }

    final w = size.width, h = size.height;

    const offsetX = .5;
    const offsetY = .5;
    const p = 1;

    final iw = (blur!.width - p * 2).toDouble();
    final ih = (blur!.height - p * 2).toDouble();

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

    final Rect ra = Rect.fromLTWH(cx + p, cy + p, cw, ch);
    final Rect rb = Rect.fromLTWH(0, 0, w, h);

    canvas
      ..clipRect(rb)
      ..drawImageRect(
        blur!,
        ra,
        rb,
        Paint()
          ..color = const Color.fromRGBO(0, 0, 0, 1)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.mirror),
      );
  }

  @override
  bool shouldRepaint(BlurPainter oldDelegate) => blur != oldDelegate.blur;
}
