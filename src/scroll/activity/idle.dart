import 'package:flutter/material.dart';

import 'mixin.dart';

class PhotolineIdleScrollActivity extends ScrollActivity with PhotolineActivityMixin {
  PhotolineIdleScrollActivity(super._delegate);

  @override
  void applyNewDimensions() => delegate.goBallistic(0.0);

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;
}
