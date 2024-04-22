import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final _dio = Dio();

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

    if (i < 3) {
      unawaited(loader._load());
    }
  }

  ui.Image? image;

  final Uri uri;

  int ts;

  final cancel = CancelToken();

  int _attempt = 0;

  bool _loading = false;

  Future<void> _reload() async {
    _attempt++;
    _loading = false;
    _next();
  }

  Future<void> _load() async {
    _attempt++;
    late final Response<Uint8List> r;
    try {
      _loading = true;
      r = await _dio.get(
        uri.toString(),
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        print('⚠️ $e');
      }
      return _reload();
    }

    if (r.statusCode != 200) {
      if (kDebugMode) {
        print('⚠️ status');
      }
      return _reload();
    }

    if (r.data == null) {
      if (kDebugMode) {
        print('⚠️ data');
      }
      return _reload();
    }

    if (kIsWeb) {
      image = await decodeImageFromList(r.data!);
    } else {
      final codec = await ui.instantiateImageCodec(r.data!);
      final frame = await codec.getNextFrame();
      image = frame.image;
    }

    _loading = false;
    _next();

    PhotolineImageNotifier().update(this);
  }
}
