import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';

class ScrollSnapController extends ScrollController {
  ScrollSnapController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
    this.snapLast = false,

    this.headerHolder,
    this.onRefresh,

    this.snapBuilder,

    //@deprecated
    this.photolineGap = 20,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    double initital = 0;

    if (headerHolder != null) {
      initital = -headerHolder!.height.value;
    }

    return ScrollSnapPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initital,
      oldPosition: oldPosition,
    );
  }

  BoxConstraints? boxConstraints;

  final bool snapLast;

  final ItemExtentBuilder? snapBuilder;

  //@deprecated
  final double photolineGap;

  final RefreshCallback? onRefresh;
  final isUserDrag = ValueNotifier<bool>(false);

  final ScrollSnapHeaderController? headerHolder;

  ScrollSnapSpringSimulation? simulation;
  int? snapTargetIndex;

  ScrollSnapPosition get pos => position as ScrollSnapPosition;
}
