import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/library.dart';
import 'package:photoline_example/generated/assets.gen.dart';
import 'package:photoline_example/photoline/loader.dart';
import 'package:photoline_example/photoline/tile.dart';

class PhotolineWrap extends PhotolineController {
  PhotolineWrap({
    required List<Uri> photos,
  }) {
    loaders = photos
        .map((uri) => PhotoLoaderWrap(uri.toString()))
        .toList();
    _wrappers.add(this);
  }

  late final List<PhotoLoaderWrap> loaders;

  State? state;

  static final List<PhotolineWrap> _wrappers = [];

  static PhotolineWrap? _findByState(State s) {
    for (final w in _wrappers) {
      if (w.state == s) return w;
    }
    return null;
  }

  @override
  Widget Function(int index, bool show)? get getBackside => (index, show) {
        return PhotolineStripe(
          stripeColor: const Color.fromRGBO(10, 10, 10, .5),
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: PhotolineAlbumPhotoDummy(
              child: SizedBox(
                width: 500,
                height: 1,
                child: dummys[index % dummys.length],
              ),
            ),
          ),
        );
      };

  @override
  Widget Function(int index)? get getTile => (index) => PhotolineTileTest(
        key: ValueKey(Object.hash(loaders[index].uri, index)),
        photoline: this,
        index: index,
      );

  @override
  PhotolineLoader? Function(int index)? get getLoader => (index) => loaders[index];

  @override
  ValueGetter<int> get getPhotoCount => () => loaders.length;

  @override
  void Function(int index, Object data)? get onAdd => (index, data) {
        if (data is Uri) {
          loaders.insert(index, PhotoLoaderWrap(data.toString()));
        } else if (data is PhotoLoaderWrap) {
          loaders.insert(index, data);
        }
      };

  @override
  void Function(int index)? get onRemove => (index) {
        if (index < 0 || index >= loaders.length) return;
        loaders.removeAt(index);
      };

  @override
  void Function(int oldIndex, int newIndex)? get onReorder => (oldIndex, newIndex) {
        loaders.reorder(oldIndex, newIndex);
      };

  @override
  void Function(State from, int fi, State target, int ti)? get onTransfer => (from, fi, to, ti) {
        final fromController = _findByState(from);
        final toController = _findByState(to);
        if (fromController == null || toController == null) return;
        if (fi < 0 || fi >= fromController.loaders.length) return;

        final loader = fromController.loaders.removeAt(fi);
        fromController.photoline?.rebuild();

        toController.addItemPhotoline(ti, loader);

        if (kDebugMode) {
          print('Transfer: from=$fi to=$ti');
        }
      };

  @override
  State? Function()? get getTransferState => () => state;

  double Function(double p1, double p2, double p3) get wrapHeight => (w, h, t) {
        const double footer = 64;
        return ui.lerpDouble(w * .7 + footer, h, t)! + 20;
      };

  @override
  void dispose() {
    _wrappers.remove(this);
    super.dispose();
  }
}

final List<Widget> dummys = [
  Assets.svg.v2.carousel.dummy0.svg(),
  Assets.svg.v2.carousel.dummy1.svg(),
  Assets.svg.v2.carousel.dummy2.svg(),
];
