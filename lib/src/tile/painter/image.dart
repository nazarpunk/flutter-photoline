import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImagePainter extends CustomPainter {
  ImagePainter({
    this.image,
    required this.imageOpacity,
    required this.grayOpacity,
  });

  final ui.Image? image;
  final double imageOpacity;
  final double grayOpacity;

  /// [Image], [LinearGradient]
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final w = size.width, h = size.height;

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(0, 0, 0, imageOpacity);

    if (image != null) {
      const offsetX = .5;
      const offsetY = .5;

      final iw = image!.width.toDouble();
      final ih = image!.height.toDouble();

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

      //print("draw|$canvas");
      if (kProfileMode) {
        canvas.drawImageRect(image!, Rect.fromLTWH(cx, cy, cw, ch),
            Rect.fromLTWH(0, 0, w, h), paint);
      }
    }

    if (kProfileMode) {
      canvas.drawPath(
          Path()..addRRect(RRect.fromRectXY(Rect.fromLTWH(0, 0, w, h), 20, 20)),
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    if (grayOpacity > 0) {
      paint
        ..isAntiAlias = false
        //..color = Color.fromRGBO(0, 0, 0, grayOpacity)
        ..color = Colors.black
        ..filterQuality = FilterQuality.medium;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) =>
      image != oldDelegate.image || //
      imageOpacity != oldDelegate.imageOpacity || //
      grayOpacity != oldDelegate.grayOpacity;
}
