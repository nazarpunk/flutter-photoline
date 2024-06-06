import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
    final pa = _controller.pageActivePaginator.value;

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
            _controller.action.value != PhotolineAction.drag
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

  void _reimage() {
    if (!mounted) return;
    if (!_controller.paintedNotifier(widget.index).value) return;
    if (widget.uri == null) return;
    final loader = PhotolineImageLoader.add(widget.uri!);
    if (loader.image == null) {
      _animationImage
        ..value = 0
        ..addListener(rebuild);
      _notifier.addListener(_imageListener);
    } else {
      _animationImage.value = 1;
      if (widget.uri != null) _image = _notifier.image(widget.uri!);
    }
  }

  void _reimageCallback() {
    SchedulerBinding.instance.addPostFrameCallback((d) => _reimage());
  }

  @override
  void didUpdateWidget(covariant PhotolineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != null && widget.uri != oldWidget.uri) {
      _reimage();
    }
  }

  @override
  void initState() {
    _animation.addListener(_listener);
    _controller.pageActiveOpenComplete.addListener(rebuild);
    _animationImage = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.paintedNotifier(widget.index).addListener(_reimageCallback);
    final loader = PhotolineImageLoader.loaded(widget.uri);
    if (loader == null) {
      _reimage();
      _reblur();
    } else {
      _animationImage.value = 1;
      if (widget.uri != null) _image = _notifier.image(widget.uri!);
    }
    super.initState();
  }

  @override
  void dispose() {
    _notifier.removeListener(_imageListener);
    _controller.pageActiveOpenComplete.removeListener(rebuild);
    _animationImage.dispose();
    _animation.removeListener(_listener);
    _controller.paintedNotifier(widget.index).removeListener(_reimageCallback);
    super.dispose();
  }

  ui.Image? _image;
  late final AnimationController _animationImage;
  final _notifier = PhotolineImageNotifier();

  bool get _visible {
    if (_data == null || !mounted) return false;
    final RenderObject? box = context.findRenderObject();
    if (box == null) return true;
    final g = (box as RenderBox).localToGlobal(Offset.zero);
    final s = _data!.size;

    // left
    if (g.dx + s.width < 0) return false;
    // top
    if (g.dy + s.height < 0) return false;
    // right
    if (g.dx > s.width) return false;
    // bottom
    if (g.dy > s.height) return false;
    return true;
  }

  MediaQueryData? _data;

  void _imageListener() {
    //if (kDebugMode) return;
    if (!mounted || _notifier.loader!.uri != widget.uri || _image != null) {
      return;
    }
    _image = _notifier.loader!.image;

    if (_visible) {
      _animationImage.forward(from: 0);
    } else {
      _animationImage.value = 1;
    }
  }

  PhotolineHolderDragController? get _drag =>
      _controller.photoline?.holder?.dragController;

  /// [LongPressEndDetails]
  /// [ReorderableDelayedDragStartListener]
  @override
  Widget build(BuildContext context) {
    _data = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sc =
            Color.fromRGBO(0, 0, 200, ui.lerpDouble(0, .4, _dragCurrent)!);
        final rc =
            Color.fromRGBO(200, 0, 0, ui.lerpDouble(0, .4, _dragCurrent)!);
        final cc = Color.lerp(sc, rc, _drag?.removeDx ?? 0)!;

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
        );

        final List<Widget>? persistent =
            _controller.getPersistentWidgets?.call(data);

        Widget child = Stack(
          children: [
            if (_animationImage.value < 1)
              Positioned.fill(
                key: const ValueKey('blur'),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BlurPainter(
                      color: _controller.getBlur?.call(_index) == null
                          ? _controller.getColor?.call(_index)
                          : Colors.transparent,
                      blur: _blur,
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
            ),
            Positioned.fill(
              key: const ValueKey('widget'),
              child: _controller.pageActiveOpenComplete.value == _index
                  ? _controller.getWidget(_index)
                  : const SizedBox(),
            ),
            if (persistent != null) ...persistent,
            if (_dragCurrent > 0) Positioned.fill(child: ColoredBox(color: cc)),
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
          behavior: HitTestBehavior.opaque,
          child: PhotolineStripe(
            child: child,
          ),
        );
      },
    );
  }
}
