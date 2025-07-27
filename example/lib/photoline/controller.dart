import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/generated/assets.gen.dart';

class PhotolineWrap extends PhotolineController {
  PhotolineWrap({
    required this.photos,
    required super.rebuilder,
  });

  List<Uri> photos;

  @override
  PhotolineUri getUri(index) => PhotolineUri(
        uri: photos[index],
        stripe: const Color.fromRGBO(10, 10, 10, .5),
      );

  @override
  Key getKey(index) => ValueKey(photos[index]);

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
  List<Widget> Function(PhotolineTileData data)? get getPersistentWidgets => (data) {
        //if (kDebugMode) return [];

        final List<Widget> out = [
          ColoredBox(
            color: Color.lerp(Colors.transparent, const Color.fromRGBO(0, 0, 0, .7), 1 - data.closeDw)!,
            child: const SizedBox.expand(),
          ),
          Center(
            child: ColoredBox(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${data.index}| ${data.closeDw.toStringAsFixed(2)}'),
              ),
            ),
          )
        ];

        if (data.dragging) {
          out.add(const Placeholder());
        }

        return out;
      };

  @override
  ValueGetter<int> get getPhotoCount => () => photos.length;

  @override
  void Function(int index, Object data)? get onAdd => (index, data) {
        photos.insert(index, data as Uri);
      };

  @override
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
