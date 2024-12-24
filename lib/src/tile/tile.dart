import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/tile/data.dart';
import 'package:photoline/src/tile/painter/blur.dart';
import 'package:photoline/src/tile/painter/image.dart';
import 'package:photoline/src/utils/stripe.dart';

class PhotolineTile extends StatefulWidget {
  const PhotolineTile({
    super.key,
    required this.index,
    required this.controller,
    required this.photoline,
  });

  final int index;
  final PhotolineController controller;
  final PhotolineState photoline;

  @override
  State<PhotolineTile> createState() => PhotolineTileState();
}

class PhotolineTileState extends State<PhotolineTile>
    with TickerProviderStateMixin, StateRebuildMixin {
  double _opacity = 0;
  double _opacityCurrent = 0;

  int get _index => widget.index;

  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => widget.controller;

  AnimationController get _animation => widget.photoline.animationOpacity;

  late final AnimationController _animationImage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..addListener(_animationListener);

  void _listenerOpacity(double ax) {
    double no = _opacity;
    final pa = _controller.pageActivePaginator.value;

    no = pa < 0 ? 0 : (no + ax).clamp(0, 1);

    if (pa < 0) no = 0;

    if (no == _opacity) return;
    _opacity = no;
    _opacityCurrent = ui.lerpDouble(
        0, _index == pa ? .5 : .8, Curves.easeOutQuad.transform(_opacity))!;
    rebuild();
  }

  void _animationListener() {
    final double ax = _animation.velocity.abs();
    _listenerOpacity(ax);
  }

  @override
  void initState() {
    //print('init: ${widget.index}');
/*
    _notifier.addListener(_imageListener);
    _controller
      ..pageActiveOpenComplete.addListener(rebuild)
      ..canPaintNotifier.addListener(_canPaintListener);

 */

    //_controller.paintedNotifier(widget.index).addListener(_reimage);
    /*
    final loader = PhotolineImageLoader.loaded(widget.uri);
    if (loader == null) {
      _reimage();
      _reblur();
    } else {
      _animationImage.value = 1;
      if (widget.uri != null) _image = _notifier.image(widget.uri!);
    }

     */
    super.initState();
  }

  @override
  void dispose() {
    //print('dispose: ${widget.index}');
    //_animationImage.dispose();
    //_animation.dispose();
    //_notifier.removeListener(_imageListener);
    /*
    _controller
      ..pageActiveOpenComplete.removeListener(_rebuild)
      ..canPaintNotifier.removeListener(_canPaintListener);

     */

    super.dispose();
  }

  PhotolineHolderDragController? get _drag =>
      _controller.photoline?.holder?.dragController;

  /// [LongPressEndDetails]
  /// [ReorderableDelayedDragStartListener]
  @override
  Widget build(BuildContext context) {
    if (!kProfileMode) {
      return GestureDetector(
        onTap: () => _photoline.toPage(_index),
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(),
      );
    }

    if (!kProfileMode) {
      return GestureDetector(
        onTap: () => _photoline.toPage(_index),
        behavior: HitTestBehavior.opaque,
        child: Placeholder(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ImagePainter(
                imageOpacity: 1,
                grayOpacity: 0,
                //imageOpacity: Curves.easeIn.transform(_animationImage.value).clamp(0, 1),
                //grayOpacity: _controller.isTileOpenGray? _opacityCurrent.clamp(0, 1): 0,
              ),
            ),
          ),
        ),
      );
    }

    //_data = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _controller.size;

        final (double, double) limit = size.close > size.side2
            ? (size.side2, size.close)
            : (size.close, size.side2);
        final double cdwa =
            constraints.maxWidth.clamp(limit.$1, limit.$2) - size.side2;

        final data = PhotolineTileData(
          index: _index,
          loading: _animationImage.value,
          closeDw: (cdwa / (size.close - size.side2)).clamp(0, 1),
          openDw: (constraints.maxWidth - size.close) /
              (size.open - size.close).clamp(-1, 1),
          dragging:
              (_drag?.isDrag ?? false) && _controller.pageDragInitial == _index,
          isRemove: _drag?.isRemove ?? false,
        );

        final List<Widget>? persistent =
            _controller.getPersistentWidgets?.call(data);

        Widget child = Stack(
          children: [
            if (_animationImage.value < 1 && kProfileMode)
              Positioned.fill(
                key: const ValueKey('blur'),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BlurPainter(
                      color: _controller.getBlur?.call(_index) == null
                          ? _controller.getColor?.call(_index)
                          : Colors.transparent,
                      blur: null,
                      imageOpacity: _animationImage.value,
                      sigma: 30,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              key: const ValueKey('image'),
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ImagePainter(
                    imageOpacity: 1,
                    //imageOpacity: Curves.easeIn.transform(_animationImage.value).clamp(0, 1),
                    grayOpacity: _controller.isTileOpenGray
                        ? _opacityCurrent.clamp(0, 1)
                        : 0,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              key: const ValueKey('widget'),
              child: _controller.pageActiveOpenComplete.value == _index
                  ? _controller.getWidget(_index)
                  : const SizedBox(),
            ),
            if (persistent != null) ...persistent,
          ],
        );

        if (_controller.canDrag &&
            _photoline.holder?.dragController != null &&
            _controller.getPhotoCount() > _index) {
          child = Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _controller.onPointerDown(this, event),
            child: child,
          );
        }

        return GestureDetector(
          onTap: () => _photoline.toPage(_index),
          behavior: HitTestBehavior.opaque,
          child: PhotolineStripe(
            stripeColor: _photoline.widget.photoStripeColor,
            child: child,
          ),
        );
      },
    );
  }
}
