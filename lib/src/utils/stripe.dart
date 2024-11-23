import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PhotolineStripe extends SingleChildRenderObjectWidget {
  const PhotolineStripe({
    super.key,
    super.child,
    required this.stripeColor,
  });

  final Color stripeColor;

  @override
  StripeRenderProxyBox createRenderObject(BuildContext context) =>
      StripeRenderProxyBox(stripeColor);
}

class StripeRenderProxyBox extends RenderProxyBox {
  StripeRenderProxyBox(this.stripeColor) : super();

  final Color stripeColor;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (size.width > 0) {
      context.canvas.drawRect(
        offset & Size(math.min(size.width, 10), size.height),
        Paint()
          ..color = stripeColor
          ..style = PaintingStyle.fill,
      );
    }
  }
}
