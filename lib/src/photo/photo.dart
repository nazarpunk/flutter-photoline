import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline/tile/uri.dart';

part 'render.dart';

part 'paint.dart';

class PhotolinePhoto extends StatefulWidget {
  const PhotolinePhoto({
    super.key,
    required this.uri,
    required this.sigma,
    this.mainImageBlur,
  });

  final PhotolineUri? uri;
  final double sigma;

  /// Optional blur sigma for the main image.
  /// If provided and returns > 0, the main image will be blurred.
  final double? Function()? mainImageBlur;

  @override
  State<PhotolinePhoto> createState() => _PhotolinePhotoState();
}

class _PhotolinePhotoState extends State<PhotolinePhoto> with SingleTickerProviderStateMixin, StateRebuildMixin {
  late final _animationRepaint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didUpdateWidget(covariant PhotolinePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri) {
      rebuild();
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_animationRepaint.repeat());
    _animationRepaint.addListener(rebuild);
  }

  @override
  void dispose() {
    _animationRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uri != null) {
      return RepaintBoundary(
        child: _PhotolinePhotoRender(
          uri: widget.uri!,
          animation: _animationRepaint,
          sigma: widget.sigma,
          mainImageBlur: widget.mainImageBlur,
        ),
      );
    }
    return const SizedBox();
  }
}
