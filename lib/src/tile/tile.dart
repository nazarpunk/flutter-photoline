import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/tile/data.dart';
import 'package:photoline/src/tile/loader.dart';
import 'package:photoline/src/tile/painter/blur.dart';
import 'package:photoline/src/tile/painter/image.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/stripe.dart';

class PhotolineTile extends StatefulWidget {
  const PhotolineTile({
    super.key,
    required this.index,
    required this.uri,
    required this.controller,
    required this.photoline,
  });

  final int index;
  final Uri? uri;
  final PhotolineController controller;
  final PhotolineState photoline;

  @override
  State<PhotolineTile> createState() => PhotolineTileState();
}

class PhotolineTileState extends State<PhotolineTile>
    with StateRebuildMixin, TickerProviderStateMixin {
  double _opacity = 0;
  double _opacityCurrent = 0;
  double _dragCurrent = 0;

  int get _index => widget.index;

  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => widget.controller;

  AnimationController get _animation => widget.photoline.animationOpacity;

  ui.Image? _blur;

  void _listenerOpacity(double ax) {
    double no = _opacity;
    final pa = _controller.pageActive.value;

    no = pa < 0 ? 0 : (no + ax).clamp(0, 1);

    if (pa < 0) no = 0;

    if (no == _opacity) return;
    _opacity = no;
    _opacityCurrent = ui.lerpDouble(
        0, _index == pa ? .5 : .8, Curves.easeOutQuad.transform(_opacity))!;
    rebuild();
  }

  void _listenerDrag(double ax) {
    final bool cl = _drag?.isDragClose ?? true;
    final dcx = cl ||
            _controller.pageDragInitial != _index ||
            _controller.action != PhotolineAction.drag
        ? -1
        : 1;

    final double dc = (_dragCurrent + ax * dcx).clamp(0, 1);
    if (dc == _dragCurrent) return;
    _dragCurrent = dc;
    rebuild();
  }

  void _listener() {
    final double ax = _animation.velocity.abs();
    _listenerOpacity(ax);
    _listenerDrag(ax);
  }

  void _reblur() {
    final blist = _controller.getBlur?.call(_index);
    if (blist != null && blist.isNotEmpty) {
      ui.decodeImageFromList(blist, (result) {
        if (!mounted) return;
        _blur = result;
        rebuild();
      });
    }
  }

  void _reimage(PhotolineImageLoader? loader) {
    if (loader?.image == null) {
      _animationImage
        ..value = 0
        ..addListener(rebuild);

      _notifier.addListener(_imageListener);
    } else {
      _animationImage.value = 1;
      if (widget.uri != null) _image = _notifier.image(widget.uri!);
    }
  }

  @override
  void didUpdateWidget(covariant PhotolineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != null && widget.uri != oldWidget.uri) {
      _reimage(PhotolineImageLoader.add(widget.uri!));
    }
  }

  @override
  void initState() {
    _animation.addListener(_listener);
    _animationImage = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _reimage(widget.uri == null ? null : PhotolineImageLoader.add(widget.uri!));
    _reblur();
    super.initState();
  }

  @override
  void dispose() {
    _notifier.removeListener(_imageListener);
    _animationImage.dispose();
    _animation.removeListener(_listener);
    super.dispose();
  }

  ui.Image? _image;
  late final AnimationController _animationImage;
  final _notifier = PhotolineImageNotifier();

  void _imageListener() {
    if (_notifier.loader!.uri != widget.uri) return;
    _image = _notifier.loader!.image;
    _animationImage.forward(from: 0);
  }

  PhotolineHolderDragController? get _drag =>
      _controller.photoline?.holder?.dragController;

  /// [LongPressEndDetails]
  /// [ReorderableDelayedDragStartListener]
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sc =
            Color.fromRGBO(0, 0, 200, ui.lerpDouble(0, .4, _dragCurrent)!);
        final rc =
            Color.fromRGBO(200, 0, 0, ui.lerpDouble(0, .4, _dragCurrent)!);
        final cc = Color.lerp(sc, rc, _drag?.removeDx ?? 0)!;

        final size = _controller.size;

        final List<Widget>? persistent =
            _controller.getPersistentWidgets?.call(PhotolineTileData(
          index: _index,
          loading: _animationImage.value,
          closeDw: (constraints.maxWidth.clamp(size.side2, size.close) -
                  size.side2) /
              (size.close - size.side2),
        ));

        Widget child = Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BlurPainter(
                  blur: _blur,
                  imageOpacity: _animationImage.value,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: ImagePainter(
                  image: _image,
                  imageOpacity: Curves.easeIn
                      .transform(_animationImage.value)
                      .clamp(0, 1),
                  grayOpacity: _controller.isTileOpenGray
                      ? _opacityCurrent.clamp(0, 1)
                      : 0,
                ),
              ),
            ),
            Positioned.fill(
              child: _controller.pageActive.value == _index
                  ? _controller.getWidget(_index)
                  : const SizedBox(),
            ),
            if (persistent != null) ...persistent,
            if (_dragCurrent > 0) Positioned.fill(child: ColoredBox(color: cc)),
            if (kDebugMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_index'),
                      Text('${_controller.pageTargetOpen}'),
                    ],
                  ),
                ),
              )
          ],
        );

        if (_controller.canDrag &&
            _photoline.holder?.dragController != null &&
            _controller.getPhotoCount() > _index) {
          child = Listener(
            onPointerDown: (event) => _controller.onPointerDown(this, event),
            child: child,
          );
        }

        return GestureDetector(
          onTap: () => _photoline.toPage(_index),
          child: PhotolineStripe(
            child: child,
          ),
        );
      },
    );
  }
}
