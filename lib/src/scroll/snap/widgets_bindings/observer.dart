import 'dart:ui';

import 'package:flutter/material.dart';

class WidgetsBindingObserverEx extends WidgetsBindingObserver {
  final notifier = ValueNotifier<bool>(false);

  FlutterView? view;
  double viB = 0;

  @override
  void didChangeMetrics() {
    view = WidgetsBinding.instance.platformDispatcher.views.first;
    viB = view!.viewInsets.bottom / view!.devicePixelRatio;

    print('$viB');

    notifier.value = !notifier.value;
    super.didChangeMetrics();
  }

  void dispose() {
    notifier.dispose();
  }
}
