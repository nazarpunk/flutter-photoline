import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';

double _photolineHeight(double width) => width * .7 + 64;

class ScrollSnapController extends ScrollController {
  ScrollSnapController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
    this.snap = false,
    this.snapLast = false,
    this.snapPhotolines,
    this.headerHolder,
    this.onRefresh,
    this.photolineGap = 20,
    this.photolineHeight = _photolineHeight,
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

  final Map<int, ScrollSnapBox> box = {};
  BoxConstraints? boxConstraints;
  int? snapCage;

  final bool snap;
  final bool snapLast;
  final List<PhotolineController> Function()? snapPhotolines;
  final double photolineGap;
  final double Function(double) photolineHeight;

  final RefreshCallback? onRefresh;
  final isUserDrag = ValueNotifier<bool>(false);

  final ScrollSnapHeaderController? headerHolder;

  ScrollSnapSpringSimulation? simulation;
  int? snapTargetIndex;

  ScrollSnapPosition get pos => position as ScrollSnapPosition;
}
