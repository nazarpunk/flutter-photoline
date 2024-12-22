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

  Future<void> _load() async {
    _loading = true;
    _attempt++;
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return _reload();
    }

    final data = response.bodyBytes;
    if (kIsWeb) {
      image = await decodeImageFromList(data);
    } else {
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      image = frame.image;
    }

    _loading = false;
    _next();

    PhotolineImageNotifier().update(this);
  }
}
