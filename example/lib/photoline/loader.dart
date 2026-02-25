import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

/// Simple PhotolineLoader implementation for testing.
/// Wraps a URI and delegates image loading to the base class.
class PhotoLoaderWrap extends PhotolineLoader {
  PhotoLoaderWrap(this._uri, {int width = 0, int height = 0})
      : _width = width,
        _height = height;

  final String _uri;

  @override
  String? get uri => _uri;

  final int _width;

  @override
  int get width => _width;

  final int _height;

  @override
  int get height => _height;

  @override
  Color? get stripe => const Color.fromRGBO(10, 10, 10, .5);
}
