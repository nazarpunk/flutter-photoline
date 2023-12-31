import 'package:flutter/cupertino.dart';

import 'package:photoline/src/controller.dart';

@immutable
class PhotolineSize {
  PhotolineSize(PhotolineController controller) {
    final p = controller.position;

    viewCount = controller.getViewCount(controller.photolineWidth);
    viewport = p.viewportDimension;
    close = viewport * controller.closeRatio;
    open = viewport * controller.openRatio;
    side2 = viewport - open;
    side = side2 * .5;
    pixels = p.pixels;
  }

  late final int viewCount;
  late final double viewport;
  late final double close;
  late final double side;
  late final double side2;
  late final double open;
  late final double pixels;
}
