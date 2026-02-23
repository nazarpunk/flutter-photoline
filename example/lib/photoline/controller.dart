import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/library.dart';
import 'package:photoline_example/generated/assets.gen.dart';

class PhotolineWrap extends PhotolineController {
  PhotolineWrap({
    required this.photos,
  });

  List<Uri> photos;

  @override
  Widget Function(int index, bool show)? get getBackside => (index, show) {
        if (kDebugMode) return const SizedBox();

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
  ValueGetter<int> get getPhotoCount => () => photos.length;

  @override
  void Function(int index, Object data)? get onAdd => (index, data) {
        photos.insert(index, data as Uri);
      };

  double Function(double p1, double p2, double p3) get wrapHeight => (w, h, t) {
        const double footer = 64;
        return ui.lerpDouble(w * .7 + footer, h, t)! + 20;
      };
}

final List<Widget> dummys = [
  Assets.svg.v2.carousel.dummy0.svg(),
  Assets.svg.v2.carousel.dummy1.svg(),
  Assets.svg.v2.carousel.dummy2.svg(),
];
