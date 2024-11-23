import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/utils/position.dart';

class PhotolineBackside extends StatefulWidget {
  const PhotolineBackside({
    super.key,
    required this.photoline,
  });

  final PhotolineState photoline;

  @override
  State<PhotolineBackside> createState() => _PhotolineBacksideState();
}

class _PhotolineBacksideState extends State<PhotolineBackside>
    with StateRebuildMixin {
  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => _photoline.controller;

  @override
  void initState() {
    _photoline.animationPosition.addListener(rebuild);
    super.initState();
  }

  @override
  void dispose() {
    _photoline.animationPosition.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, contstraints) {
      final List<Widget> child = [];
      final count = _controller.count;
      final viewCount = _controller.getViewCount(contstraints.maxWidth);
      final close = contstraints.maxWidth * _controller.closeRatio;

      final List<double> w = [];
      final List<double> o = [];

      for (int i = 0; i < viewCount; i++) {
        w.add(0);
        o.add(0);
      }

      switch (_controller.action.value) {
        case PhotolineAction.close:
        case PhotolineAction.drag:
          for (int i = 0; i < viewCount; i++) {
            if (i < count) continue;
            w[i] = close;
            o[i] = i * close;
          }
        case PhotolineAction.opening:
        case PhotolineAction.closing:
        case PhotolineAction.upload:
          final List<PhotolinePosition> po = _photoline.positionWidth;
          if (count > po.length || po.isEmpty) break;
          final f = po[count - 1];
          final fo = f.offset.current + f.width.current;
          for (int i = count; i < viewCount; i++) {
            w[i] = close;
            o[i] = fo + (i - count) * close;
          }
        case PhotolineAction.open:
          if (count != 1) break;
          final v = contstraints.maxWidth;
          w[1] = close;
          o[1] = v * _controller.openRatio;

        /*
        case PhotolineAction.drag:
          final List<PhotolineDrag> pd = _controller.positionDrag;
          final p = pd.isEmpty ? 0 : pd.first.page;
          for (int i = 0; i < viewCount; i++) {
            w[i] = close;
            o[i] = (p + i) * close;
          }

           */
      }

      for (int i = 0; i < viewCount; i++) {
        if (w[i] == 0 && o[i] == 0) continue;
        child.add(
          Positioned(
            key: ValueKey(i),
            top: 0,
            bottom: 0,
            left: o[i],
            width: close,
            child: _controller.getBackside?.call(i) ?? const SizedBox(),
          ),
        );
      }

      if (_controller.action.value == PhotolineAction.drag) {
        for (int i = 0; i < viewCount; i++) {
          child.add(
            Positioned(
              key: ValueKey('stripe$i'),
              top: 0,
              bottom: 0,
              left: close * i,
              width: close,
              child: PhotolineStripe(
                stripeColor: _controller.photoline?.widget.photoStripeColor ?? Colors.transparent,
              ),
            ),
          );
        }
      }

      if (child.isEmpty) return const SizedBox();

      return Stack(
        fit: StackFit.expand,
        children: child,
      );
    });
  }
}
