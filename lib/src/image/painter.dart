part of 'image.dart';

class _Painter extends CustomPainter {
  _Painter({
    this.image,
    this.background,
    this.foreground,
    required this.opacity,
    required this.grayscale,
    required this.gradient,
  });

  final ui.Image? image;
  final Color? background;
  final Color? foreground;
  final double opacity;
  final bool grayscale;
  final bool gradient;

  void _draw(Canvas canvas, Size size, Paint paint, ui.Image? image) {
    final w = size.width, h = size.height;

    if (image == null) return;

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

    final double cw = math.min(iw / (nw / w), iw), ch = math.min(ih / (nh / h), ih), cx = math.max((iw - cw) * offsetX, 0), cy = math.max((ih - ch) * offsetY, 0);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(cx, cy, cw, ch),
      Rect.fromLTWH(0, 0, w, h),
      paint,
    );
  }

  /// [Image], [LinearGradient]
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final c = Color.fromRGBO(0, 0, 0, opacity);
    final r = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..isAntiAlias = false
      ..color = c
      ..filterQuality = FilterQuality.medium;

    if (grayscale) {
      paint.colorFilter = const ColorFilter.matrix([
        ...[.2126, .7152, .0722, 0, 0],
        ...[.2126, .7152, .0722, 0, 0],
        ...[.2126, .7152, .0722, 0, 0],
        ...[0, 0, 0, 1, 0]
      ]);
    }

    if (background != null) {
      canvas.drawRect(r, paint..color = background!);
    }

    if (!grayscale && foreground != null) {
      paint.colorFilter = ColorFilter.mode(
        Color.lerp(Colors.transparent, foreground, opacity)!,
        BlendMode.multiply,
      );
    }

    _draw(canvas, size, paint..color = Color.fromRGBO(0, 0, 0, opacity), image);

    /*
    if (gradient) {
      paint
        ..color = C.app
        ..shader = ui.Gradient.linear(
          Offset(size.width * .5, 0),
          Offset(size.width * .5, size.height),
          C.top100add,
        );

      canvas.drawRect(r, paint);
    }

     */
  }

  @override
  bool shouldRepaint(_Painter o) =>
      image != o.image || //
      background != o.background || //
      opacity != o.opacity || //
      grayscale != o.grayscale || //
      foreground != o.foreground;
}
