part of 'image.dart';

class _PhotolineImagePaint extends RenderProxyBox {
  _PhotolineImagePaint({
    required AnimationController animation,
    required PhotolineLoader loader,
    required double sigma,
  }) {
    _animation = animation;
    _loader = loader;
    _sigma = sigma;
  }

  late AnimationController _animation;

  AnimationController get animation => _animation;

  set animation(AnimationController value) {
    if (_animation == value) {
      return;
    }
    _animation.removeListener(markNeedsPaint);
    _animation = value;
    _animation.addListener(markNeedsPaint);
  }

  late PhotolineLoader _loader;

  PhotolineLoader get loader => _loader;

  set loader(PhotolineLoader value) {
    if (_loader == value) {
      return;
    }
    _loader = value;
    markNeedsPaint();
  }

  late double _sigma;

  double get sigma => _sigma;

  set sigma(double value) {
    if (_sigma == value) {
      return;
    }
    _sigma = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    _animation.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final w = size.width;
    final h = size.height;
    final cdx = offset.dx;
    final cdy = offset.dy;

    final imrect = Rect.fromLTWH(offset.dx, offset.dy, w, h);

    loader.spawn();
    canvas
      ..save()
      ..clipRect(imrect);

    final double opacity = loader.opacity;

    // Draw blur with inverse opacity
    if (loader.blur != null && opacity < 1) {
      drawPhotolineImage(
        canvas: canvas,
        image: loader.blur!,
        width: w,
        height: h,
        dx: cdx,
        dy: cdy,
        opacity: 1,
        filter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.mirror,
        ),
      );
    } else if (loader.color != null && opacity < 1) {
      canvas.drawRect(
        imrect,
        Paint()
          ..color = loader.color!
          ..style = PaintingStyle.fill,
      );
    }

    // Draw image with opacity
    if (loader.image != null) {
      drawPhotolineImage(
        canvas: canvas,
        image: loader.image!,
        width: w,
        height: h,
        dx: cdx,
        dy: cdy,
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
  }
}
