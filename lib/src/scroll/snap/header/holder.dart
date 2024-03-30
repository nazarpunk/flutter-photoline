import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:photoline/photoline.dart';

class ScrollSnapHeaderHolder {
  double get minExtent => 200;

  double get maxExtent => 500;

  final extent = ValueNotifier<double>(400);

  final Map<String, ScrollSnapController> _controllers = {};

  set delta(double delta) {
    extent.value = clampDouble(extent.value - delta, minExtent, maxExtent);
  }

  ScrollSnapController controller(String key) {
    if (_controllers[key] != null) return _controllers[key]!;
    final c = ScrollSnapController(
      headerHolder: this,
    );

    _controllers[key] = c;
    return c;
  }
}
