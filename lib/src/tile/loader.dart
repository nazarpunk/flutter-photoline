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

  ui.Image image(Uri uri) {
    return _map[uri]!.image!;
  }

  void update(PhotolineImageLoader loader) {
    this.loader = loader;
    notifyListeners();
  }
}

class PhotolineImageLoader {
  PhotolineImageLoader(this.uri);

  factory PhotolineImageLoader.add(Uri uri) {
    print("💋 $uri");
    if (_map[uri] != null) return _map[uri]!;
    final l = PhotolineImageLoader(uri);
    _map[uri] = l;
    unawaited(l._load());
    return l;
  }

  ui.Image? image;

  final Uri uri;

  final cancel = CancelToken();

  int _attempt = 0;

  Future<void> _reload() async {
    _attempt++;
    await Future.delayed(Duration(seconds: _attempt));
    await _load();
  }

  Future<void> _load() async {
    _attempt++;
    late final Response<Uint8List> r;
    try {
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

    PhotolineImageNotifier().update(this);
  }
}
