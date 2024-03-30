import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
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
    this.headerHolder,
    this.onRefresh,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    double initital = 0;

    if (headerHolder != null) {
      initital = -headerHolder!.extent.value;
    }

    return ScrollSnapPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initital,
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

  final ScrollSnapHeaderHolder? headerHolder;

  ScrollSnapSpringSimulation? simulation;
  int? snapTargetIndex;

  ScrollSnapPosition get pos => position as ScrollSnapPosition;
}
