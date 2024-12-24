import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final Map<Uri, PhotolineImageLoader> _map = {};

class PhotolineImageNotifier extends ChangeNotifier {
  factory PhotolineImageNotifier() => _instance;

  PhotolineImageNotifier._();

  static final PhotolineImageNotifier _instance = PhotolineImageNotifier._();

  PhotolineImageLoader? loader;

  ui.Image image(Uri uri) => _map[uri]!.image!;

  void update(PhotolineImageLoader loader) {
    this.loader = loader;
    notifyListeners();
  }
}

class PhotolineImageLoader {
  PhotolineImageLoader(this.uri, this.ts);

  factory PhotolineImageLoader.add(Uri uri) {
    if (_map[uri] != null) {
      return _map[uri]!..ts = DateTime.now().millisecondsSinceEpoch;
    }
    final l = PhotolineImageLoader(uri, DateTime.now().millisecondsSinceEpoch);
    _map[uri] = l;
    _next();
    return l;
  }

  static PhotolineImageLoader? loaded(Uri? uri) {
    if (uri == null || _map[uri] == null) return null;
    final l = _map[uri]!;
    return l.image == null ? null : l;
  }

  static void _next() {
    //if (kDebugMode) return;

    if (_map.isEmpty) return;

    int i = 0;
    for (final l in _map.values) {
      if (l._attempt > 10) continue;
      if (l._loading) {
        i += 1;
      }
    }

    PhotolineImageLoader? loader;
    for (final l in _map.values) {
      if (l._attempt > 10 || l.image != null || l._loading) continue;
      if (loader == null || (l.ts + l._attempt) < loader.ts) loader = l;
    }

    if (loader == null) return;

    if (i < 1) {
      unawaited(loader._load());
    }
  }

  ui.Image? image;

  final Uri uri;

  int ts;

  int _attempt = 0;

  bool _loading = false;

  Future<void> _reload() async {
    _attempt++;
    _loading = false;
    _next();
  }

  Future<void> _load1() async {
    _loading = true;
    _attempt++;
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return _reload();
    }

    final data = response.bodyBytes;
//    image = await decodeImageFromList(data);

    //image = await _decodeImageFromList(data);
    /*
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      image = frame.image;
       */
    _loading = false;
    _next();
    PhotolineImageNotifier().update(this);
  }

  Future<void> _load() async {
    _loading = true;
    _attempt++;

    //
    //final im = await compute(_getImage, uri);

    late final ui.Image? im;
    im = await _getImage(uri);

    if (im == null) {
      return _reload();
    }

    image = im;

    _loading = false;
    _next();
    PhotolineImageNotifier().update(this);
  }
}

Future<ui.Image?> _getImage(Uri uri) async {
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    return null;
  }

  final bytes = response.bodyBytes;
  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(bytes);

  final ui.ImageDescriptor descriptor =
      await ui.ImageDescriptor.encoded(buffer);

  final ui.TargetImageSize targetSize =
      ui.TargetImageSize(width: descriptor.width, height: descriptor.height);

  final ui.Codec codec = await descriptor.instantiateCodec(
    targetWidth: targetSize.width,
    targetHeight: targetSize.height,
  );
  buffer.dispose();

  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
