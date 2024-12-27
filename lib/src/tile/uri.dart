import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Map<Uri, PhotolineUri> _map = {};

int _now() => DateTime.now().millisecondsSinceEpoch;

int _count = 0;

class PhotolineUri {
  PhotolineUri({
    this.uri,
    this.color,
    this.width = 0,
    this.height = 0,
  });

  PhotolineUri get cached {
    if (uri == null) {
      return this;
    }
    final cur = _map[uri] ?? this;
    return cur
      ..color = color
      ..width = width
      ..height = height;
  }

  void spawn() {
    if (uri == null || _map[uri] != null) return;
    _ts = _now();
    _map[uri!] = this;
    _next();
  }

  final Uri? uri;
  ui.Image? image;
  bool _loading = false;
  int _ts = 0;
  int _attempt = -1;

  Color? color;

  int width = 0;
  int height = 0;

  static const double _mo = 50;
  double _opacity = 0;

  double get opacity => _opacity / _mo;

  set opacity(double value) {
    _opacity = value < 0 ? _mo : math.min(_mo, _opacity + value);
  }

  static void _next() {
    if (_count > 0) return;

    PhotolineUri? nxt;

    for (final cur in _map.values) {
      if (cur._loading || cur.image != null || cur._attempt > 10) continue;
      if (nxt == null || nxt._ts < (cur._ts - cur._attempt * -100)) {
        nxt = cur;
      }
    }

    if (nxt == null) return;
    unawaited(nxt._load());
  }

  Future<void> _load() async {
    if (uri == null) return;

    _attempt++;
    _loading = true;
    _count++;

    final im = await _getImage(uri!);
    if (im != null) {
      image = im;
    }

    _count--;
    _loading = false;
    _next();
  }
}

Future<Uint8List?> _getBytes(String uri) async {
  final response = await http.get(Uri.parse(uri));
  if (response.statusCode != 200) {
    return null;
  }

  return response.bodyBytes;
}

Future<ui.Image?> _getImage(Uri uri) async {
  final Uint8List? bytes = await compute(_getBytes, uri.toString());
  if (bytes == null) return null;

  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(bytes);

  final ui.ImageDescriptor descriptor =
      await ui.ImageDescriptor.encoded(buffer);

  buffer.dispose();
  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
