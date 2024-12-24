import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Map<Uri, PhotolineUri> _map = {};

int _now() => DateTime.now().millisecondsSinceEpoch;

int _count = 0;

class PhotolineUri {
  PhotolineUri._(this.uri);

  factory PhotolineUri.spawn(Uri uri) {
    var cur = _map[uri];
    if (cur != null) return cur.._ts = _now();
    _map[uri] = cur = PhotolineUri._(uri).._ts = _now();
    _next();
    return cur;
  }

  final Uri uri;
  ui.Image? image;
  bool _loading = false;
  int _ts = 0;
  int _attempt = -1;

  static void _next() {
    if (_count > 0) return;

    PhotolineUri? nxt;

    for (final cur in _map.values) {
      if (cur._loading || cur.image != null || cur._attempt > 10) continue;
      if (nxt == null || (cur._ts - cur._attempt * 100) > nxt._ts) {
        nxt = cur;
      }
    }

    if (nxt == null) return;
    unawaited(nxt._load());
  }

  Future<void> _load() async {
    _attempt++;
    _loading = true;
    _count++;

    final im = await _getImage(uri);
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

  int a = _now();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  print('frameInfo [${descriptor.width}|${descriptor.height}]: ${_now() - a}');
  return frameInfo.image;
}
