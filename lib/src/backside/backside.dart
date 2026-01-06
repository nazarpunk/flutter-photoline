import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoline/library.dart';
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

  late final PhotolineHolderState? _holder;

  @override
  void initState() {
    _holder = context.findAncestorStateOfType<PhotolineHolderState>();
    _holder?.active.addListener(rebuild);
    _photoline.animationPosition.addListener(rebuild);
    super.initState();
  }

  @override
  void dispose() {
    _photoline.animationPosition.removeListener(rebuild);
    _holder?.active.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drag = _holder?.active.value ?? false;

    return LayoutBuilder(builder: (context, contstraints) {
      final List<Widget> child = [];
      final count = _controller.count;
      final viewCount = _controller.getViewCount(contstraints.maxWidth);
      final close = contstraints.maxWidth * _controller.closeRatio;

      final List<double> w = [];
      final List<double> o = [];

      for (var i = 0; i < viewCount; i++) {
        w.add(0);
        o.add(0);
      }

      switch (_controller.action.value) {
        case PhotolineAction.close:
        case PhotolineAction.drag:
        case PhotolineAction.upload:
          for (var i = 0; i < viewCount; i++) {
            //if (i < count) continue;
            w[i] = close;
            o[i] = i * close;
          }
        case PhotolineAction.opening:
        case PhotolineAction.closing:
          final List<PhotolinePosition> po = _photoline.positionWidth;
          if (count > po.length || po.isEmpty) break;
          final f = po[count - 1];
          final fo = f.offset.current + f.width.current;
          for (var i = count; i < viewCount; i++) {
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

      for (var i = 0; i < viewCount; i++) {
        if (w[i] == 0 && o[i] == 0) continue;
        child.add(
          Positioned(
            key: ValueKey(i),
            top: 0,
            bottom: 0,
            left: math.max(o[i], 0),
            width: close,
            child: SizedBox(
              width: close,
              height: double.infinity,
              child:
                  _controller.getBackside?.call(i, !drag) ?? const SizedBox(),
            ),
          ),
        );
      }

      if (child.isEmpty) return const SizedBox();

      return Stack(
        fit: StackFit.expand,
        children: child,
      );
    });
  }
}
