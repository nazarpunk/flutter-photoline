import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/tile/loader.dart';
import 'package:photoline/src/tile/painter/blur.dart';
import 'package:photoline/src/tile/painter/image.dart';

class PhotolineBlurPhoto extends StatefulWidget {
  const PhotolineBlurPhoto({
    super.key,
    required this.uri,
    required this.blur,
    this.preload,
  });

  final Uri? uri;
  final Uint8List? blur;
  final Widget? preload;

  @override
  State<PhotolineBlurPhoto> createState() => PhotolineBlurPhotoState();
}

class PhotolineBlurPhotoState extends State<PhotolineBlurPhoto>
    with StateRebuildMixin, TickerProviderStateMixin {
  ui.Image? _blur;

  void _reblur() {
    final blist = widget.blur;
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
  void didUpdateWidget(covariant PhotolineBlurPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != null && widget.uri != oldWidget.uri) {
      _reimage(PhotolineImageLoader.add(widget.uri!));
    }
  }

  @override
  void initState() {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              imageOpacity:
                  Curves.easeIn.transform(_animationImage.value).clamp(0, 1),
              grayOpacity: 0,
            ),
          ),
        ),
        if (widget.preload != null && _animationImage.value < 1)
          Positioned.fill(
            child: Opacity(
              opacity: (1 - _animationImage.value).clamp(0, 1),
              child: widget.preload,
            ),
          )
      ],
    );
  }
}
