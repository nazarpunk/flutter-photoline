import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../mixin/state/rebuild.dart';
import '../photoline.dart';

class PhotolinePaginatorStar extends StatefulWidget {
  const PhotolinePaginatorStar({
    super.key,
    required this.index,
    required this.photoline,
    this.indexOffset = 0,
  });

  final int index;
  final PhotolineState photoline;
  final int indexOffset;

  @override
  State<PhotolinePaginatorStar> createState() => _PhotolinePaginatorStarState();
}

class _PhotolinePaginatorStarState extends State<PhotolinePaginatorStar> with SingleTickerProviderStateMixin, StateRebuildMixin {
  late AnimationController _animation;

  PhotolineState get _photoline => widget.photoline;

  //PhotolineController get _controller => widget.photoline.widget.controller;

  int get _indexOffset => widget.indexOffset;

  //Color get _color => widget.index >= _controller.getCount() - _indexOffset ? const Color.fromRGBO(200, 200, 200, 1) : Color.lerp(const Color.fromRGBO(120, 120, 130, 1), const Color.fromRGBO(0, 0, 0, 1), _animation.value)!;

  void listener() {
    final double value = _photoline.pageActive.value == (widget.index + _indexOffset) ? 1 : 0;

    rebuild();

    if (value == _animation.value && !_animation.isAnimating) {
      return;
    }
    if (value > 0) {
      _animation.forward(from: _animation.value);
    } else {
      _animation.reverse(from: _animation.value);
    }
  }

  @override
  void initState() {
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )
      ..value = _photoline.pageActive.value == widget.index ? 1 : 0
      ..addListener(rebuild);
    _photoline.pageActive.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    _photoline.pageActive.removeListener(listener);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StarTriangle(
        height: lerpDouble(0, 10, _animation.value)!,
        child: Stack(
          alignment: Alignment.center,
          children: [
            //Assets.svg.avatar.user.svg(width: PhotolinePaginator.starHeight, colorFilter: ColorFilter.mode(_color, BlendMode.srcIn)),
            Text(
              '${widget.index + 1}',
              style: const TextStyle(
                //fontFamily: FontFamily.sansitaOne,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _photoline.toPage(widget.index + _indexOffset),
            ),
            const MouseRegion(
              cursor: SystemMouseCursors.click,
              opaque: false,
              child: SizedBox(width: 40, height: 40),
            )
          ],
        ),
      );
}

class _StarTriangle extends SingleChildRenderObjectWidget {
  const _StarTriangle({
    super.child,
    required this.height,
  });

  final double height;

  @override
  void updateRenderObject(BuildContext context, _RenderProxyBox renderObject) {
    renderObject.height = height;
  }

  @override
  _RenderProxyBox createRenderObject(BuildContext context) => _RenderProxyBox(
        height: height,
      );
}

class _RenderProxyBox extends RenderProxyBox {
  _RenderProxyBox({
    RenderBox? child,
    required double height,
  })  : _height = height,
        super(child);

  double _height;

  double get bottomTriangleHeight => _height;

  set height(double value) {
    if (_height == value) return;
    _height = value;
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (_height > 0) {
      const double btw = 40;
      final double p = (size.width - btw) * .5;
      context.canvas.drawPath(
        Path()
          ..moveTo(size.width * .5, size.height - _height)
          ..lineTo(size.width - p, size.height)
          ..lineTo(p, size.height)
          ..close(),
        Paint()
          ..color = const Color.fromRGBO(0, 0, 0, 1)
          ..style = PaintingStyle.fill,
      );
    }
  }
}
