import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline/loader.dart';

part 'render.dart';

part 'paint.dart';

class PhotolinePhoto extends StatefulWidget {
  const PhotolinePhoto({
    super.key,
    required this.loader,
    required this.sigma,
  });

  final PhotolineLoader? loader;
  final double sigma;

  @override
  State<PhotolinePhoto> createState() => _PhotolinePhotoState();
}

class _PhotolinePhotoState extends State<PhotolinePhoto> with SingleTickerProviderStateMixin, StateRebuildMixin {
  late final _animationRepaint = AnimationController(
    vsync: this,
    duration: PhotolineLoader.animationDuration,
  );

  @override
  void didUpdateWidget(covariant PhotolinePhoto oldWidget) {
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
        child: _PhotolinePhotoRender(
          loader: widget.loader!,
          animation: _animationRepaint,
          sigma: widget.sigma,
        ),
      );
    }
    return const SizedBox();
  }
}
