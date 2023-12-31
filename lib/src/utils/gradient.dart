import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PhotolineGradient extends SingleChildRenderObjectWidget {
  const PhotolineGradient({
    super.key,
    super.child,
  });

  @override
  GradientRenderProxyBox createRenderObject(BuildContext context) =>
      GradientRenderProxyBox();
}

class GradientRenderProxyBox extends RenderProxyBox {
  GradientRenderProxyBox() : super();

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (size.width > 0) {
      context.canvas.drawRect(
        offset & Size(size.width, size.height),
        Paint()
          ..color = Colors.black
          ..shader = ui.Gradient.linear(
            Offset(size.width * .5, 0),
            Offset(size.width * .5, size.height),
            [
              const Color.fromRGBO(40, 200, 250, .4),
              const Color.fromRGBO(180, 30, 250, .4),
            ],
          ),
      );
    }
  }
}
