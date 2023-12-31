import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PhotolineStripe extends SingleChildRenderObjectWidget {
  const PhotolineStripe({
    super.key,
    super.child,
  });

  @override
  StripeRenderProxyBox createRenderObject(BuildContext context) =>
      StripeRenderProxyBox();
}

class StripeRenderProxyBox extends RenderProxyBox {
  StripeRenderProxyBox() : super();

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (size.width > 0) {
      context.canvas.drawRect(
        offset & Size(math.min(size.width, 10), size.height),
        Paint()
          ..color = const Color.fromRGBO(255, 255, 255, .1)
          ..style = PaintingStyle.fill,
      );
    }
  }
}
