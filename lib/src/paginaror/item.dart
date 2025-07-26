import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';

import 'package:photoline/src/mixin/state/rebuild.dart';

class PhotolinePaginatorItem extends StatefulWidget {
  const PhotolinePaginatorItem({
    super.key,
    required this.index,
    required this.photoline,
  });

  final int index;
  final PhotolineState photoline;

  @override
  State<PhotolinePaginatorItem> createState() => _PhotolinePaginatorItemState();
}

class _PhotolinePaginatorItemState extends State<PhotolinePaginatorItem>
    with TickerProviderStateMixin, StateRebuildMixin {
  late final AnimationController _starAnim;
  late final AnimationController _triAnim;

  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => widget.photoline.widget.controller;

  int get _index => widget.index;

  int get _indexOffset => _controller.getPagerIndexOffset();

  int get _indexView => _index + 1;

  int get _indexTrigger => _index + _indexOffset;

  Color get _color => widget.index >= _controller.getPhotoCount() - _indexOffset
      ? const Color.fromRGBO(200, 200, 200, 1)
      : Color.lerp(const Color.fromRGBO(120, 120, 130, 1),
          const Color.fromRGBO(0, 0, 0, 1), _starAnim.value)!;

  void _triLis() {
    final double value =
        _controller.pageActivePaginator.value == _indexTrigger ? 1 : 0;

    rebuild();

    if (value == _triAnim.value && !_triAnim.isAnimating) return;
    if (value > 0) {
      unawaited(_triAnim.forward(from: _triAnim.value));
    } else {
      unawaited(_triAnim.reverse(from: _triAnim.value));
    }
  }

  void _starLis() {
    final pto = _controller.pageActivePaginator.value;

    double value = pto == _indexTrigger ? 1 : 0;
    switch (_controller.action.value) {
      case PhotolineAction.closing:
      case PhotolineAction.close:
      case PhotolineAction.upload:
        value = 0;
      case PhotolineAction.open:
      case PhotolineAction.opening:
      case PhotolineAction.drag:
        break;
    }

    //if (value == _starAnim.value && !_starAnim.isAnimating) return;
    if (value > 0) {
      unawaited(_starAnim.forward(from: _starAnim.value));
    } else {
      unawaited(_starAnim.reverse(from: _starAnim.value));
    }
  }

  @override
  void initState() {
    final double v =
        _controller.pageActivePaginator.value == _indexTrigger ? 1 : 0;

    _starAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )
      ..value = v
      ..addListener(rebuild);
    _controller.pageActivePaginator.addListener(_starLis);
    _controller.action.addListener(_starLis);

    _triAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )
      ..value = v
      ..addListener(rebuild);
    _controller.pageActivePaginator.addListener(_triLis);

    super.initState();
  }

  @override
  void dispose() {
    _controller.pageActivePaginator.removeListener(_triLis);
    _controller.pageActivePaginator.removeListener(_starLis);
    _controller.action.removeListener(_starLis);
    _starAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double sz = 40;
    return _StarTriangle(
      height: lerpDouble(0, 10, _triAnim.value)!,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._controller.getPagerItem!(_indexView, _color),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _photoline.toPage(_indexTrigger),
            child: const SizedBox.expand(),
          ),
          if (kDebugMode && kProfileMode)
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black,
                child: Text(
                  '$_indexTrigger - ${_controller.pageActivePaginator.value}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          const MouseRegion(
            cursor: SystemMouseCursors.click,
            opaque: false,
            child: SizedBox(width: sz, height: sz),
          )
        ],
      ),
    );
  }
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
