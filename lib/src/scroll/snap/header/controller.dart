import 'dart:ui';

import 'package:flutter/cupertino.dart';

class ScrollSnapHeaderController {
  double get minHeight => 200;

  double get maxHeight => 400;

  late final height = ValueNotifier<double>(maxHeight);

  set delta(double delta) {
    height.value = clampDouble(height.value - delta, minHeight, maxHeight);
  }
}
