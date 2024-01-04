import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/scroll/activity/ballistic.dart';
import 'package:photoline/src/scroll/activity/drag.dart';
import 'package:photoline/src/scroll/activity/idle.dart';
import 'package:photoline/src/scroll/activity/mixin.dart';
import 'package:photoline/src/scroll/metrics.dart';
import 'package:photoline/src/utils/action.dart';

class PhotolineScrollPosition extends ScrollPosition
    implements ScrollActivityDelegate, PhotolineScrollMetrics {
  PhotolineScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    this.initialPage = 0,
    super.oldPosition,
  }) : _pageToUseOnStartup = initialPage.toDouble() {
    if (activity == null) goIdle();
    assert(activity != null);
  }

  final int initialPage;
  double _pageToUseOnStartup;

  double? cachedPage;
  final PhotolineController controller;

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

  double getPixelsFromPage(double page) {
    final vd = viewportDimension;

    if (controller.action.value == PhotolineAction.close) {
      final base = vd * controller.closeRatio;
      return base * page;
    }

    final open = vd * controller.openRatio;

    final skipFirst = controller.getPagerIndexOffset() > 0 && page == 1;
    if (skipFirst) return page * open;

    final side = (vd - open) * .5;
    if (page < 1) return page * (open - side);
    if (page == pageLast) return page * open - side * 2;
    return page * open - side;
  }

  @override
  double? get page {
    assert(!hasPixels || hasContentDimensions,
        'Page value is only available after content dimensions are established.');
    return !hasPixels || !hasContentDimensions
        ? null
        : cachedPage ??
            getPageFromPixels(
                clampDouble(pixels, minScrollExtent, maxScrollExtent),
                viewportDimension);
  }

  double get pageOpen {
    return _getPageFromPixelsOpen(pixels);
  }

  @override
  void saveScrollOffset() {
    PageStorage.maybeOf(context.storageContext)?.writeState(
        context.storageContext, cachedPage ?? getPageFromPixels(pixels));
  }

  @override
  void restoreScrollOffset() {
    if (!hasPixels) {
      final double? value = PageStorage.maybeOf(context.storageContext)
          ?.readState(context.storageContext) as double?;
      if (value != null) _pageToUseOnStartup = value;
    }
  }

  @override
  void saveOffset() {
    context.saveOffset(cachedPage ?? getPageFromPixels(pixels));
  }

  @override
  void restoreOffset(double offset, {bool initialRestore = false}) {
    if (initialRestore) {
      _pageToUseOnStartup = offset;
    } else {
      jumpTo(getPixelsFromPage(offset));
    }
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions =
        hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    double page;
    if (oldPixels == null) {
      page = _pageToUseOnStartup;
    } else if (oldViewportDimensions == 0.0) {
      page = cachedPage!;
    } else {
      page = getPageFromPixels(oldPixels, oldViewportDimensions);
    }
    final double newPixels = getPixelsFromPage(page);

    cachedPage = (viewportDimension == 0.0) ? page : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    assert(cachedPage == null);

    if (other is! PhotolineScrollPosition) return;

    if (other.cachedPage != null) cachedPage = other.cachedPage;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
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

    return super.applyContentDimensions(
        minScrollExtent, math.max(minScrollExtent, maxScrollExtent));
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
    return super.setPixels(newPixels);
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
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
    if (cachedPage != null) {
      cachedPage = page;
      return;
    }

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
    if (cachedPage != null) {
      cachedPage = target;
      return;
    }

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
  void jumpToWithoutSettling(double value) {}

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
}
