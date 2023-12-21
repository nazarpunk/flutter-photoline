import 'dart:math' as math;

import 'package:flutter/material.dart';

class PhotolineTileMiddleGround extends StatelessWidget {
  const PhotolineTileMiddleGround({
    super.key,
    required this.opacity,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _Painter(
          opacity: opacity,
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final c = Color.fromRGBO(0, 0, 0, opacity);

    final paint = Paint()
      ..isAntiAlias = false
      ..color = c
      ..filterQuality = FilterQuality.medium;

    final w = size.width, h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    final sw = math.min(10.0, size.width);
    paint.colorFilter = null;
    if (sw > 0) canvas.drawRect(Rect.fromLTWH(0, 0, sw, size.height), paint..color = Colors.red);

    //final sw = math.min(W.carouselStripe, size.width);
    //paint.colorFilter = null;
    //if (sw > 0) canvas.drawRect(Rect.fromLTWH(0, 0, sw, size.height), paint..color = C.carouselStripe);
  }

  @override
  bool shouldRepaint(_Painter o) => opacity != o.opacity;
}
