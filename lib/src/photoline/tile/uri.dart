import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photoline/src/photoline/loader.dart';

@deprecated
class PhotolineUriNotifier extends ChangeNotifier {
  @deprecated
  PhotolineUriNotifier._();

  static PhotolineUriNotifier? _instance;

  static PhotolineUriNotifier get instance => _instance ??= PhotolineUriNotifier._();
}

@deprecated
class PhotolineUri extends PhotolineLoader {
  @deprecated
  PhotolineUri({
    Uri? uri,
    ui.Image? blur,
    Color? color,
    int width = 0,
    int height = 0,
    Color? stripe,
    double? opacity,
  }) : _uri = uri,
       _width = width,
       _height = height,
       _stripe = stripe {
    this.blur = blur;
    this.color = color;
    if (opacity != null) this.opacity = opacity;
  }

  final Uri? _uri;
  final int _width;
  final int _height;
  final Color? _stripe;

  @override
  String? get uri => _uri?.toString();

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  Color? get stripe => _stripe;

  // ignore: avoid_returning_this
  PhotolineUri get cached => this;

  bool get loaded => image != null;

  @override
  bool get imageLoaded => image != null;
}
