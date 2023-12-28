import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/image/image.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/tile/middleground.dart';
import 'package:photoline/src/utils/action.dart';

class PhotolineTile extends StatefulWidget {
  const PhotolineTile({
    super.key,
    required this.index,
    required this.uri,
    required this.background,
    required this.controller,
    required this.photoline,
  });

  final int index;
  final Uri? uri;
  final Color background;
  final PhotolineController controller;
  final PhotolineState photoline;

  @override
  State<PhotolineTile> createState() => PhotolineTileState();
}

class PhotolineTileState extends State<PhotolineTile> with StateRebuildMixin {
  double _opacity = 0;
  double _opacityCurrent = 0;
  double _dragCurrent = 0;

  int get _index => widget.index;

  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => widget.controller;

  AnimationController get _animation => widget.photoline.animationOpacity;

  void _listenerOpacity(double ax) {
    double no = _opacity;
    final pa = _photoline.pageActive.value;

    no = pa < 0 ? 0 : (no + ax).clamp(0, 1);

    if (pa < 0) no = 0;

    if (no == _opacity) return;
    _opacity = no;
    _opacityCurrent = lerpDouble(0, _index == pa ? .5 : .8, Curves.easeOutQuad.transform(_opacity))!;
    rebuild();
  }

  void _listenerDrag(double ax) {
    final dc = _dragCurrent;
    final dcx = _controller.pageDragInitial == _index && _controller.action == PhotolineAction.drag ? 1 : -1;

    _dragCurrent = (_dragCurrent + ax * dcx).clamp(0, 1);

    if (dc == _dragCurrent) return;
    rebuild();
  }

  void _listener() {
    final double ax = _animation.velocity.abs();
    _listenerOpacity(ax);
    _listenerDrag(ax);
  }

  @override
  void initState() {
    _animation.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    _animation.removeListener(_listener);
    super.dispose();
  }

  /// [LongPressEndDetails]
  /// [ReorderableDelayedDragStartListener]
  @override
  Widget build(BuildContext context) {
    final Color sortColor = Color.lerp(Colors.transparent, const Color.fromRGBO(0, 0, 200, .4), _dragCurrent)!;
    final List<Widget>? persistent = _controller.getPersistentWidgets?.call(_index);

    final double rdx = _controller.photoline?.holder?.dragController?.removeDx ?? 0;

    Widget child = Stack(
      children: [
        Positioned.fill(
          child: PhotolineImage(
            uri: widget.uri,
            background: widget.background,
            foreground: const Color.fromRGBO(0, 0, 0, 0),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: PhotolineTileMiddleGroundPaint(
              photoline: _photoline,
              opacity: _controller.isTileOpenGray ? _opacityCurrent.clamp(0, 1) : 0,
            ),
          ),
        ),
        Positioned.fill(
          child: _photoline.pageActive.value == _index ? _controller.getWidget(_index) : const SizedBox(),
        ),
        if (persistent != null) ...persistent,
        if (_dragCurrent > 0)
          Positioned.fill(
              child: ColoredBox(
            color: Color.lerp(sortColor, const Color.fromRGBO(200, 0, 0, .4), rdx)!,
          )),
        if (kDebugMode) Positioned.fill(child: Center(child: Text(_index.toString())))
      ],
    );

    if (_controller.canDrag && _photoline.holder?.dragController != null) {
      child = Listener(
        onPointerDown: (event) => _controller.onPointerDown(this, event),
        child: child,
      );
    }

    return GestureDetector(
      onTap: () => _photoline.toPage(_index),
      child: _SingleChildRenderObjectWidget(
        photoline: _photoline,
        child: child,
      ),
    );
  }
}

class _SingleChildRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _SingleChildRenderObjectWidget({
    super.child,
    required this.photoline,
  });

  final PhotolineState photoline;

  @override
  _RenderProxyBox createRenderObject(BuildContext context) => _RenderProxyBox(photoline: photoline);
}

class _RenderProxyBox extends RenderProxyBox {
  _RenderProxyBox({
    required this.photoline,
  }) : super();

  final PhotolineState photoline;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (size.width > 0) {
      context.canvas.drawRect(
        offset & Size(math.min(size.width, photoline.widget.photoStripeWidth), size.height),
        Paint()
          ..color = photoline.widget.photoStripeColor
          ..style = PaintingStyle.fill,
      );
    }
  }
}
