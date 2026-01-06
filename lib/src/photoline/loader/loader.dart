import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Map<String, _PhotolineLoaderData> _map = {};

int _count = 0;
int _counter = 0;

class PhotolineLoaderNotifier extends ChangeNotifier {
  PhotolineLoaderNotifier._();

  static PhotolineLoaderNotifier? _instance;

  static PhotolineLoaderNotifier get instance => _instance ??= PhotolineLoaderNotifier._();

  String uri = '';

  set notify(String? uri) {
    if (uri == null || uri == this.uri) return;
    this.uri = uri;
    notifyListeners();
  }
}

class _PhotolineLoaderData {
  ui.Image? image;
  bool loading = false;
  int index = 0;
  int attempt = -1;
}

abstract class PhotolineLoader {
  String? get uri;

  ui.Image? blur;

  int get width;

  int get height;

  Color? get stripe;

  Color? color;

  bool initiallyLoaded = false;

  _PhotolineLoaderData get _data {
    final u = uri;
    if (u == null) return _PhotolineLoaderData();
    return _map[u] ??= _PhotolineLoaderData();
  }

  ui.Image? get image => _data.image;

  double opacity = 0;

  /// Called by Photoline render to signal that loading should start.
  /// Automatically handles deduplication by URI.
  void spawn() {
    final u = uri;
    if (u == null) return;

    final data = _data;

    // Already loading or loaded
    if (data.loading || data.image != null) return;

    data
      ..loading = true
      ..index = ++_counter;
    _next();
  }

  static void _next() {
    if (_count > 0) return;

    _PhotolineLoaderData? next;
    String? nextUri;

    for (final entry in _map.entries) {
      final data = entry.value;
      if (data.loading || data.image != null) continue;
      if (next == null || data.index < next.index) {
        next = data;
        nextUri = entry.key;
      }
    }

    if (next == null || nextUri == null) return;
    unawaited(_load(nextUri, next));
  }

  static Future<void> _load(String uri, _PhotolineLoaderData data) async {
    data.loading = true;
    data.attempt++;
    data.index = ++_counter + 10;
    _count++;

    ui.Image? img;

    if (data.attempt > 1) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      img = await _getImage(uri);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️PhotolineLoader($uri): $e');
      }
    }

    if (img != null) {
      data.image = img;
      PhotolineLoaderNotifier.instance.notify = uri;
    }

    _count--;
    data.loading = false;
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
          onTimeout: () => http.Response('Error', 408),
        );
  } catch (e) {
    if (kDebugMode) {
      print('⚠️PhotolineLoader: $e');
    }
  }

  if (response == null || response.statusCode != 200) return null;

  return response.bodyBytes;
}

Future<ui.Image?> _getImage(String uri) async {
  final Uint8List? bytes = await compute(_getBytes, uri);
  if (bytes == null) return null;

  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);

  buffer.dispose();

  final ui.Codec codec = await descriptor.instantiateCodec();
  final ui.FrameInfo frameInfo = await codec.getNextFrame();

  return frameInfo.image;
}
