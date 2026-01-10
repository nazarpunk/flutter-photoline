import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline/loader.dart';
import 'package:photoline/src/utils/draw_image.dart';

part 'render.dart';

part 'paint.dart';

class PhotolineImage extends StatefulWidget {
  const PhotolineImage({
    super.key,
    required this.loader,
    required this.sigma,
  });

  final PhotolineLoader? loader;
  final double sigma;

  @override
  State<PhotolineImage> createState() => _PhotolineImageState();
}

class _PhotolineImageState extends State<PhotolineImage> with SingleTickerProviderStateMixin, StateRebuildMixin {
  late final _animationRepaint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didUpdateWidget(covariant PhotolineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loader != oldWidget.loader) {
      rebuild();
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_animationRepaint.repeat());
    _animationRepaint.addListener(rebuild);
    PhotolineLoaderNotifier.instance.addListener(rebuild);
  }

  @override
  void dispose() {
    _animationRepaint.dispose();
    PhotolineLoaderNotifier.instance.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loader != null) {
      return RepaintBoundary(
        child: _PhotolineImageRender(
          loader: widget.loader!,
          animation: _animationRepaint,
          sigma: widget.sigma,
        ),
      );
    }
    return const SizedBox();
  }
}
