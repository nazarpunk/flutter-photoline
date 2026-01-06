import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Map<Uri, PhotolineUri> _map = {};

int _count = 0;

int _counter = 0;

class PhotolineUriNotifier extends ChangeNotifier {
  PhotolineUriNotifier._();

  static PhotolineUriNotifier? _instance;

  static PhotolineUriNotifier get instance => _instance ??= PhotolineUriNotifier._();

  Uri uri = Uri();

  set notify(Uri? uri) {
    if (uri == null || uri == this.uri) return;
    this.uri = uri;
    notifyListeners();
  }
}

class PhotolineUri {
  PhotolineUri({this.uri, this.blur, this.color, this.width = 0, this.height = 0, this.stripe, double? opacity}) {
    if (opacity != null) _opacity = opacity * _mo;
  }

  PhotolineUri get cached {
    if (uri == null) {
      return this;
    }
    final cur = _map[uri];
    if (cur == null) {
      return this;
    }
    // Return cached instance directly - it has accumulated opacity
    // Don't transfer opacity to new instance
    return cur
      ..color = color
      ..width = width
      ..height = height;
  }

  bool get loaded => uri != null && _map[uri]?.image != null;

  void spawn() {
    if (uri == null || _map[uri] != null) return;
    _index = ++_counter;
    _map[uri!] = this;
    _next();
  }

  final Uri? uri;
  ui.Image? image;
  ui.Image? blur;

  bool _loading = false;
  bool _imageLoaded = false;
  int _index = 0;
  int _attempt = -1;

  Color? color;
  Color? stripe;

  int width = 0;
  int height = 0;

  static const double _mo = 100;
  double _opacity = 0;

  double get opacity => _opacity / _mo;

  set opacity(double value) {
    _opacity = value < 0 ? _mo : math.min(_mo, _opacity + value);
  }

  /// Returns true if image is fully loaded
  bool get imageLoaded => _imageLoaded;

  static void _next() {
    if (_count > 0) return;
    PhotolineUri? nxt;

    for (final cur in _map.values) {
      if (cur._loading || cur.image != null) continue;
      if (nxt == null || cur._index < nxt._index) {
        nxt = cur;
      }
    }

    if (nxt == null) return;
    unawaited(nxt._load());
  }

  Future<void> _load() async {
    if (uri == null) return;

    _loading = true;
    _attempt++;
    _index = ++_counter + 10;
    _count++;
    ui.Image? im;

    if (_attempt > 1) await Future.delayed(const Duration(milliseconds: 200));
    try {
      im = await _getImage(uri!);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️PhotolineUri($uri): $e');
      }
    }

    if (im != null) {
      image = im;
      _imageLoaded = true;
      PhotolineUriNotifier.instance.notify = uri;
    }

    _count--;
    _loading = false;
    _next();
  }
}

Future<Uint8List?> _getBytes(String uri) async {
  http.Response? response;

  try {
    response = await http
        .get(Uri.parse(uri))
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return http.Response('Error', 408);
          },
        );
  } catch (e) {
    if (kDebugMode) {
      print('⚠️PhotolineUri: $e');
    }
  }

  if (response == null) return null;
  if (response.statusCode != 200) {
    return null;
  }

  return response.bodyBytes;
}

Future<ui.Image?> _getImage(Uri uri) async {
  final Uint8List? bytes = await compute(_getBytes, uri.toString());
  if (bytes == null) return null;

  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

  final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);

  buffer.dispose();
  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
