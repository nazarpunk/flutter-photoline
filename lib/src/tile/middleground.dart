import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class PhotolineTileMiddleGroundPaint extends CustomPainter {
  PhotolineTileMiddleGroundPaint({
    required this.photoline,
    required this.opacity,
  });

  final double opacity;
  final PhotolineState photoline;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final c = Color.fromRGBO(0, 0, 0, opacity);

    final paint = Paint()
      ..isAntiAlias = false
      ..color = c
      ..filterQuality = FilterQuality.medium;

    final w = size.width, h = size.height;

    if (opacity > 0) canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    final sw = math.min(photoline.widget.photoStripeWidth, size.width);
    paint.colorFilter = null;
    if (sw > 0) canvas.drawRect(Rect.fromLTWH(0, 0, sw, size.height), paint..color = photoline.widget.photoStripeColor);
  }

  @override
  bool shouldRepaint(PhotolineTileMiddleGroundPaint oldDelegate) => opacity != oldDelegate.opacity;
}
