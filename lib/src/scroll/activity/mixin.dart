import 'package:flutter/material.dart';

import '../position.dart';

mixin PhotolineActivityMixin on ScrollActivity {
  PhotolineScrollPosition get position => delegate as PhotolineScrollPosition;

  void forceExtent(double extent) {
    // ignore: invalid_use_of_protected_member
    position.correctPixels(position.pixels + extent);
  }
}
