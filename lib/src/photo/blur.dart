import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/tile/painter/blur.dart';
import 'package:photoline/src/tile/painter/image.dart';

class PhotolineBlurPhoto extends StatefulWidget {
  const PhotolineBlurPhoto({
    super.key,
    required this.uri,
    required this.blur,
    required this.color,
    this.preload,
    required this.width,
    required this.height,
    this.sigma = 30,
  });

  final Uri? uri;
  final Uint8List? blur;
  final Color? color;
  final Widget? preload;
  final int width;
  final int height;
  final double sigma;

  @override
  State<PhotolineBlurPhoto> createState() => PhotolineBlurPhotoState();
}

class PhotolineBlurPhotoState extends State<PhotolineBlurPhoto>
    with StateRebuildMixin, TickerProviderStateMixin {
  ui.Image? _blur;

  Color? get _color => widget.color;

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

  @override
  void didUpdateWidget(covariant PhotolineBlurPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != null && widget.uri != oldWidget.uri) {
      /*
      _reimage(PhotolineImageLoader.add(widget.uri!));

       */
    }
  }

  @override
  void initState() {
    _animationImage = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    /*
    _reimage(widget.uri == null ? null : PhotolineImageLoader.add(widget.uri!));

     */
    _reblur();
    super.initState();
  }

  @override
  void dispose() {
    _animationImage.dispose();
    super.dispose();
  }

  ui.Image? _image;
  late final AnimationController _animationImage;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.width / widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BlurPainter(
                color: _color,
                blur: _blur,
                imageOpacity: _animationImage.value,
                sigma: widget.sigma,
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
            ),
        ],
      ),
    );
  }
}
