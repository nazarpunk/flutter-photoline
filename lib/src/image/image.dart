import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photoline/src/image/loader.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';

part 'painter.dart';

class PhotolineImage extends StatefulWidget {
  const PhotolineImage(
    this.uri, {
    super.key,
    required this.foreground,
    required this.background,
  });

  final Uri uri;
  final Color foreground;
  final Color background;

  @override
  State<PhotolineImage> createState() => _PhotolineImageState();
}

class _PhotolineImageState extends State<PhotolineImage>
    with SingleTickerProviderStateMixin, StateRebuildMixin {
  Uri get _uri => widget.uri;

  late final AnimationController _animation;

  ui.Image? _image;

  final _notifier = PhotolineImageNotifier();

  void _imageListener() {
    if (_notifier.loader!.uri != _uri) return;
    _image = _notifier.loader!.image;
    _animation.forward(from: 0);
  }

  @override
  void initState() {
    final loader = PhotolineImageLoader.add(_uri);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );



    if (loader.image == null) {
      _animation
        ..value = 0
        ..addListener(rebuild);

      _notifier.addListener(_imageListener);
    } else {
      _animation.value = 1;
      _image = _notifier.image(_uri);
    }

    super.initState();
  }

  @override
  void dispose() {
    _notifier.removeListener(_imageListener);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Painter(
        image: _image,
        background: widget.background,
        foreground: Colors.transparent,
        opacity: Curves.easeIn.transform(_animation.value).clamp(0, 1),
        grayscale: false,
        gradient: false,
      ),
    );
  }
}
