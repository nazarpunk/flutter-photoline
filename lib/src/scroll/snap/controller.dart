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
    this.rebuild,
    this.snapLastMax = false,
    this.snapLastMin = false,
    this.headerHolder,
    this.onRefresh,
    this.snapCan,
    this.snapBuilder,
    this.snapTop = true,
    this.snapArea = false,
    this.freeMaxExtend = false,
    this.snapGap = 0,
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

  final bool snapLastMin;
  final bool snapLastMax;

  final double snapGap;
  final bool snapArea;
  final bool snapTop;

  final bool freeMaxExtend;

  final ItemExtentBuilder? snapBuilder;
  final bool? Function(int index, SliverLayoutDimensions dimensions)? snapCan;

  final void Function()? rebuild;
  final RefreshCallback? onRefresh;
  final isUserDrag = ValueNotifier<bool>(false);

  final ScrollSnapHeaderController? headerHolder;

  ScrollSnapSpringSimulation? simulation;

  @override
  ScrollSnapPosition get position => super.position as ScrollSnapPosition;


  double keyboardOverlap = 0;
}
