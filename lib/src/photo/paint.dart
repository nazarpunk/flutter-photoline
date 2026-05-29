part of 'photo.dart';

class _PhotolinePhotoPaint extends RenderProxyBox {
  _PhotolinePhotoPaint({
    required AnimationController animation,
    required PhotolineLoader loader,
    required this.sigma,
  }) {
    _animation = animation;
    _loader = loader;
  }

  late AnimationController _animation;

  AnimationController get animation => _animation;

  final double sigma;

  set animation(AnimationController value) {
    if (_animation == value) return;
    _animation.removeListener(markNeedsPaint);
    _animation = value;
    _animation.addListener(markNeedsPaint);
  }

  late PhotolineLoader _loader;

  PhotolineLoader get loader => _loader;

  set loader(PhotolineLoader value) {
    if (_loader == value) return;
    _loader = value;
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

    if (w == 0 || h == 0) return;

    final imrect = Rect.fromLTWH(offset.dx, offset.dy, w, h);

    _loader.spawn();
    canvas
      ..save()
      ..clipRect(imrect);

    void img({
      required ui.Image image,
      required double opacity,
      ui.ImageFilter? filter,
    }) {
      const offsetX = .5;
      const offsetY = .5;
      final iw = image.width.toDouble();
      final ih = image.height.toDouble();

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

      canvas.drawAtlas(
        image,
        [
          RSTransform.fromComponents(
            rotation: 0,
            scale: w / cw,
            anchorX: cw * .5,
            anchorY: ch * .5,
            translateX: cdx + w * .5,
            translateY: cdy + h * .5,
          ),
        ],
        [Rect.fromLTWH(cx, cy, cw, ch)],
        null,
        BlendMode.srcOver,
        null,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, opacity)
          ..imageFilter = filter,
      );
    }

    final velocity = _animation.velocity;
    final double opacity = _loader.opacity;

    if (_loader.image != null && opacity < 1) {
      _loader.opacity = math.min(1.0, opacity + velocity);
    }

    final double opacityback = 1 - opacity;

    if (opacity < 1) {
      if (_loader.blur != null) {
        img(
          image: _loader.blur!,
          opacity: 1,
          filter: ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.mirror,
          ),
        );
      } else if (_loader.color != null) {
        canvas.drawRect(
          imrect,
          Paint()
            ..color = _loader.color!.withValues(alpha: opacityback)
            ..style = PaintingStyle.fill,
        );
      }
    }

    if (_loader.image != null) {
      img(
        image: _loader.image!,
        opacity: Curves.easeOut.transform(opacity),
      );
    }

    if (_loader.stripe != null) {
      canvas.drawRect(
        Rect.fromLTWH(cdx, cdy, math.min(w, 10), h),
        Paint()
          ..color = _loader.stripe!
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }
}
