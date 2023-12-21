import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mixin.dart';

class PhotolineDragScrollActivity extends ScrollActivity with PhotolineActivityMixin {
  PhotolineDragScrollActivity(
    super._delegate,
    ScrollDragController controller,
  ) : _controller = controller;

  ScrollDragController? _controller;

  @override
  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext? context) {
    final dynamic lastDetails = _controller!.lastDetails;
    assert(lastDetails is DragStartDetails);
    ScrollStartNotification(metrics: metrics, context: context, dragDetails: lastDetails as DragStartDetails).dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    final dynamic lastDetails = _controller!.lastDetails;
    assert(lastDetails is DragUpdateDetails);
    ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta, dragDetails: lastDetails as DragUpdateDetails).dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    final dynamic lastDetails = _controller!.lastDetails;
    assert(lastDetails is DragUpdateDetails);
    OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, dragDetails: lastDetails as DragUpdateDetails).dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    // We might not have DragEndDetails yet if we're being called from beginActivity.
    final dynamic lastDetails = _controller!.lastDetails;
    ScrollEndNotification(
      metrics: metrics,
      context: context,
      dragDetails: lastDetails is DragEndDetails ? lastDetails : null,
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => false;

  //bool get shouldIgnorePointer => _controller?._kind != PointerDeviceKind.trackpad;

  @override
  bool get isScrolling => true;

  // DragScrollActivity is not independently changing velocity yet
  // until the drag is ended.
  @override
  double get velocity => 0.0;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  String toString() => '${describeIdentity(this)}($_controller)';
}
