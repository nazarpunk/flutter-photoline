import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:photoline/photoline.dart';

class SliverHeaderHolder {
  double get minExtent => 200;

  double get maxExtent => 500;

  final delta = ValueNotifier<double>(0);

  final extent = ValueNotifier<double>(400);

  final Map<String, ScrollSnapController> _controllers = {};

  ScrollSnapController controller(String key) {
    if (_controllers[key] != null) return _controllers[key]!;
    final c = ScrollSnapController();

    _controllers[key] = c;

    c.delta.addListener(() {
      delta.value = c.delta.value;
      extent.value =
          clampDouble(extent.value - delta.value, minExtent, maxExtent);
    });

    return c;
  }
}
