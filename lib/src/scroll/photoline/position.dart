// ignore_for_file: must_call_super

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/scroll/activity/ballistic.dart';
import 'package:photoline/src/scroll/activity/drag.dart';
import 'package:photoline/src/scroll/activity/idle.dart';
import 'package:photoline/src/scroll/activity/mixin.dart';
import 'package:photoline/src/scroll/metrics.dart';
import 'package:photoline/src/utils/action.dart';

part 'override.dart';

class PhotolineScrollPosition extends PhotolineScrollPositionOverride {
  PhotolineScrollPosition({
    required super.controller,
    required super.physics,
    required super.context,
    super.oldPosition,
  }) {
    if (activity == null) goIdle();
    assert(activity != null);
  }

  double? _cachedPage;

  @override
  Future<void> ensureVisible(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
  }) =>
      super.ensureVisible(
        object,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
      );

  void forceExtent(double extent) {
    if (activity is PhotolineActivityMixin) {
      (activity! as PhotolineActivityMixin).forceExtent(extent);
    }
  }

  double _preciesse(double actual) {
    final double round = actual.roundToDouble();
    return (actual - round).abs() < precisionErrorTolerance ? round : actual;
  }

  double get pageLast {
    final double ratio = controller.action.value == PhotolineAction.close
        ? controller.closeRatio
        : controller.openRatio;
    return (maxScrollExtent + viewportDimension) / (viewportDimension * ratio) -
        1;
  }

  double pageAdd(double add) =>
      ((page ?? 0) + add).clamp(0, pageLast).roundToDouble();

  double _getPageFromPixelsOpen(double pixels, [double? vd]) {
    vd ??= viewportDimension;
    final open = vd * controller.openRatio;
    final side = (vd - open) * .5;

    double page = pixels / (open - side);

    if (pixels >= open - side) {
      page = (pixels + side) / open;
      if (page > pageLast - 1) page = (pixels + side * 2) / open;
    }

    if (controller.getPagerIndexOffset() > 0 &&
        (pixels - open) < (open - side)) {
      page = pixels / open;
    }

    return _preciesse(page);
  }

  double getPageFromPixels(double pixels, [double? vd]) {
    vd ??= viewportDimension;
    if (controller.action.value == PhotolineAction.close) {
      final base = vd * controller.closeRatio;
      return pixels / base;
    }
    return _getPageFromPixelsOpen(pixels, vd);
  }

  double getPixelsFromPage(double page, [double? vd]) {
    vd ??= viewportDimension;

    if (controller.action.value == PhotolineAction.close) {
      final base = vd * controller.closeRatio;
      return base * page;
    }

    final open = vd * controller.openRatio;

    final skipFirst = controller.getPagerIndexOffset() > 0 && page == 1;
    if (skipFirst) return page * open;

    final side = (vd - open) * .5;
    if (page < 1) return page * (open - side);
    if (page == controller.getPhotoCount() - 1) return page * open - side * 2;
    return page * open - side;
  }

  @override
  double? get page {
    assert(!hasPixels || hasContentDimensions,
        'Page value is only available after content dimensions are established.');
    return !hasPixels || !hasContentDimensions
        ? null
        : getPageFromPixels(
            clampDouble(pixels, minScrollExtent, maxScrollExtent),
            viewportDimension);
  }

  double get pageOpen {
    return _getPageFromPixelsOpen(pixels);
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions =
        hasViewportDimension ? _viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }

    final double? oldPixels = hasPixels ? pixels : null;
    double page;

    final co = controller.getViewCount(_viewportDimension);
    final cn = controller.getViewCount(viewportDimension);

    if (oldPixels == null) {
      page = 0;
    } else if (oldViewportDimensions == 0.0) {
      page = _cachedPage!;
    } else {
      switch (controller.action.value) {
        case PhotolineAction.closing:
        case PhotolineAction.close:
          final base = _viewportDimension! / co;
          page = math.min((controller.getPhotoCount() - cn).toDouble(),
              (oldPixels / base).roundToDouble());
        case PhotolineAction.open:
        case PhotolineAction.opening:
          page = _getPageFromPixelsOpen(oldPixels, _viewportDimension)
              .roundToDouble();
        case PhotolineAction.drag:
          page =
              getPageFromPixels(oldPixels, _viewportDimension).roundToDouble();
      }
    }
    final double newPixels;

    switch (controller.action.value) {
      case PhotolineAction.closing:
      case PhotolineAction.close:
        newPixels = page * (viewportDimension / cn);
      case PhotolineAction.drag:
      case PhotolineAction.open:
      case PhotolineAction.opening:
        newPixels = getPixelsFromPage(page, viewportDimension);
    }

    if (_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
      _didChangeViewportDimensionOrReceiveCorrection = true;
    }

    _cachedPage = (viewportDimension == 0.0) ? page : null;

    if (newPixels != oldPixels) {
      _pixels = newPixels;
      return false;
    }
    return true;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    //print('🍒 applyContentDimensions $maxScrollExtent');

    switch (controller.action.value) {
      case PhotolineAction.open:
        if (controller.pageOpenInitial != 0 &&
            controller.getPagerIndexOffset() > 0) {
          minScrollExtent = viewportDimension * controller.openRatio;
        }
      case PhotolineAction.opening:
      case PhotolineAction.close:
      case PhotolineAction.closing:
      case PhotolineAction.drag:
    }

    assert(haveDimensions == (_lastMetrics != null));
    if (!nearEqual(_minScrollExtent, minScrollExtent,
            Tolerance.defaultTolerance.distance) ||
        !nearEqual(_maxScrollExtent, maxScrollExtent,
            Tolerance.defaultTolerance.distance) ||
        _didChangeViewportDimensionOrReceiveCorrection ||
        _lastAxis != axis) {
      assert(minScrollExtent <= maxScrollExtent);
      _minScrollExtent = minScrollExtent;
      _maxScrollExtent = maxScrollExtent;
      _lastAxis = axis;
      final ScrollMetrics? currentMetrics = haveDimensions ? copyWith() : null;
      _didChangeViewportDimensionOrReceiveCorrection = false;
      _pendingDimensions = true;
      if (haveDimensions &&
          !correctForNewDimensions(_lastMetrics!, currentMetrics!)) {
        return false;
      }
      _haveDimensions = true;
    }
    assert(haveDimensions);
    if (_pendingDimensions) {
      applyNewDimensions();
      _pendingDimensions = false;
    }
    assert(!_didChangeViewportDimensionOrReceiveCorrection,
        'Use correctForNewDimensions() (and return true) to change the scroll offset during applyContentDimensions().');

    if (_isMetricsChanged()) {
      if (!_haveScheduledUpdateNotification) {
        scheduleMicrotask(didUpdateScrollMetrics);
        _haveScheduledUpdateNotification = true;
      }
      _lastMetrics = copyWith();
    }
    return true;
  }

  @override
  void absorb(ScrollPosition other) {
    assert(other.context == context);
    assert(_pixels == null);
    if (other.hasContentDimensions) {
      _minScrollExtent = other.minScrollExtent;
      _maxScrollExtent = other.maxScrollExtent;
    }
    if (other.hasPixels) {
      _pixels = other.pixels;
    }
    if (other.hasViewportDimension) {
      _viewportDimension = other.viewportDimension;
    }

    assert(activity == null);
    assert(other.activity != null);
    _activity = other.activity;
    (other as PhotolineScrollPositionOverride)._activity = null;
    if (other.runtimeType != runtimeType) {
      activity!.resetActivity();
    }
    context.setIgnorePointer(activity!.shouldIgnorePointer);
    isScrollingNotifier.value = activity!.isScrolling;

    assert(_cachedPage == null);

    if (other is! PhotolineScrollPosition) return;
    if (other._cachedPage != null) {
      _cachedPage = other._cachedPage;
    }
  }

  @override
  bool correctForNewDimensions(
      ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    return true;
  }

  @override
  PhotolineScrollMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? viewportFraction,
    double? devicePixelRatio,
  }) =>
      PhotolineScrollMetrics(
        minScrollExtent: minScrollExtent ??
            (hasContentDimensions ? this.minScrollExtent : null),
        maxScrollExtent: maxScrollExtent ??
            (hasContentDimensions ? this.maxScrollExtent : null),
        pixels: pixels ?? (hasPixels ? this.pixels : null),
        viewportDimension: viewportDimension ??
            (hasViewportDimension ? this.viewportDimension : null),
        axisDirection: axisDirection ?? this.axisDirection,
        devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      );

  // ================================================ override
  double _heldPreviousVelocity = 0.0;

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  double setPixels(double newPixels) {
    assert(activity!.isScrolling);
    assert(hasPixels);
    assert(
        SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks,
        "A scrollable's position should not change during the build, layout, and paint phases, otherwise the rendering will be confused.");

    if (newPixels != pixels) {
      final double overscroll = applyBoundaryConditions(newPixels);

      assert(() {
        final double delta = newPixels - pixels;
        if (overscroll.abs() > delta.abs()) {
          throw FlutterError(
            '$runtimeType.applyBoundaryConditions returned invalid overscroll value.\n'
            'setPixels() was called to change the scroll offset from $pixels to $newPixels.\n'
            'That is a delta of $delta units.\n'
            '$runtimeType.applyBoundaryConditions reported an overscroll of $overscroll units.',
          );
        }
        return true;
      }());

      final double oldPixels = pixels;
      _pixels = newPixels - overscroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        didUpdateScrollPositionBy(pixels - oldPixels);
      }
      if (overscroll.abs() > precisionErrorTolerance) {
        didOverscrollBy(overscroll);
        return overscroll;
      }
    }
    return 0.0;
  }

  @override
  void applyNewDimensions() {
    assert(hasPixels);
    assert(_pendingDimensions);
    activity!.applyNewDimensions();
    _updateSemanticActions();
    context.setCanDrag(physics.shouldAcceptUserOffset(this));
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    _heldPreviousVelocity = 0.0;
    if (newActivity == null) return;
    assert(newActivity.delegate == this);
    super.beginActivity(newActivity);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!activity!.isScrolling) updateUserScrollDirection(ScrollDirection.idle);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void goIdle() => beginActivity(PhotolineIdleScrollActivity(this));

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation =
        physics.createBallisticSimulation(this, velocity);

    if (simulation != null) {
      beginActivity(PhotolineBallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        activity?.shouldIgnorePointer ?? true,
      ));
    } else {
      goIdle();
    }
  }

  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  @protected
  @visibleForTesting
  void updateUserScrollDirection(ScrollDirection value) {
    if (userScrollDirection == value) return;
    _userScrollDirection = value;
    didUpdateScrollDirection(value);
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (nearEqual(to, pixels, physics.toleranceFor(this).distance)) {
      jumpTo(to);
      return Future<void>.value();
    }

    final DrivenScrollActivity activity = DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  void jumpToPage(int page) {
    jumpTo(getPixelsFromPage(page.toDouble()));
  }

  @override
  void jumpTo(double value) {
    goIdle();
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
    goBallistic(0.0);
  }

  void toPageSlide(double current, double target) {
    forcePixels(getPixelsFromPage(current));

    beginActivity(BallisticScrollActivity(
      this,
      ScrollSpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1.2,
          stiffness: 80.0,
          ratio: 1.2,
        ),
        pixels,
        getPixelsFromPage(target),
        0,
        tolerance: physics.toleranceFor(this),
      ),
      context.vsync,
      activity?.shouldIgnorePointer ?? true,
    ));
  }

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final double targetPixels =
        math.min(math.max(pixels + delta, minScrollExtent), maxScrollExtent);
    if (targetPixels != pixels) {
      goIdle();
      updateUserScrollDirection(
          -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
      final double oldPixels = pixels;
      isScrollingNotifier.value = true;
      forcePixels(targetPixels);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
      goBallistic(0.0);
    }
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousVelocity = activity!.velocity;
    final HoldScrollActivity holdActivity = HoldScrollActivity(
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginActivity(holdActivity);
    _heldPreviousVelocity = previousVelocity;
    return holdActivity;
  }

  ScrollDragController? _currentDrag;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ScrollDragController drag = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
      carriedVelocity: physics.carriedMomentum(_heldPreviousVelocity),
      motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
    );
    beginActivity(PhotolineDragScrollActivity(this, drag));
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void dispose() {
    _currentDrag?.dispose();
    _currentDrag = null;
    super.dispose();
  }

  @override
  void jumpToWithoutSettling(double value) {}
}
