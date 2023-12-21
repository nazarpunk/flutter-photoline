import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mixin.dart';

class PhotolineBallisticScrollActivity extends ScrollActivity with PhotolineActivityMixin {
  PhotolineBallisticScrollActivity(
    super._delegate,
    Simulation simulation,
    TickerProvider vsync,
    this.shouldIgnorePointer,
  ) {
    _controller = AnimationController.unbounded(vsync: vsync)
      ..addListener(_tick)
      // ignore: discarded_futures
      ..animateWith(simulation).whenComplete(_end); // won't trigger if we dispose _controller before it completes.
  }

  late AnimationController _controller;
  bool _isDisposed = false;

  @override
  void resetActivity() {
    delegate.goBallistic(velocity);
  }

  @override
  void applyNewDimensions() {
    delegate.goBallistic(velocity);
  }

  double _extent = 0;

  @override
  void forceExtent(double extent) => _extent += extent;

  void _tick() {
    if (!applyMoveTo(_controller.value + _extent)) delegate.goIdle();
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, returns true. If there was any
  /// overflow, returns false.
  ///
  /// The default implementation calls [ScrollActivityDelegate.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo(double value) => delegate.setPixels(value).abs() < precisionErrorTolerance;

  void _end() {
    // Check if the activity was disposed before going ballistic because _end might be called
    // if _controller is disposed just after completion.
    if (!_isDisposed) delegate.goBallistic(0.0);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, velocity: velocity).dispatch(context);
  }

  @override
  final bool shouldIgnorePointer;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _controller.velocity;

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() => '${describeIdentity(this)}($_controller)';
}
