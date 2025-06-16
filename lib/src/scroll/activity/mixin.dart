import 'package:flutter/material.dart';

import 'package:photoline/src/scroll/photoline/position.dart';

mixin PhotolineActivityMixin on ScrollActivity {
  PhotolineScrollPosition get position => delegate as PhotolineScrollPosition;

  void forceExtent(double extent) {
    position.correctPixels(position.pixels + extent);
  }
}
