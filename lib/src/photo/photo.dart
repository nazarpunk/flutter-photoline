import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/tile/uri.dart';

part 'render.dart';

part 'paint.dart';

class PhotolinePhoto extends StatefulWidget {
  const PhotolinePhoto({
    super.key,
    required this.uri,
  });

  final PhotolineUri? uri;

  @override
  State<PhotolinePhoto> createState() => _PhotolinePhotoState();
}

class _PhotolinePhotoState extends State<PhotolinePhoto>
    with SingleTickerProviderStateMixin {
  late final _animationRepaint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _animationRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uri != null) {
      return _PhotolinePhotoRender(
        uri: widget.uri!,
        animation: _animationRepaint,
      );
    }
    return const SizedBox();
  }
}
