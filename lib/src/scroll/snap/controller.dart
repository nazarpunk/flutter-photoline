import 'package:flutter/material.dart';
import 'package:photoline/src/scroll/snap/simulation/spring.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';

class ScrollSnapController extends ScrollController {
  ScrollSnapController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
    this.snap = false,
    this.snapLast = false,
    this.onRefresh,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return ScrollSnapPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  final Map<int, ScrollSnapBox> box = {};

  final bool snap;
  final bool snapLast;
  final RefreshCallback? onRefresh;
  final isUserDrag = ValueNotifier<bool>(false);

  ScrollSnapSpringSimulation? simulation;
  int? snapTargetIndex;
}
