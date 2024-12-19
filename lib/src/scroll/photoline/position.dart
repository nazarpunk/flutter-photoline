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

class PhotolineScrollPosition extends ScrollPosition
    implements ScrollActivityDelegate, PhotolineScrollMetrics {
  PhotolineScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.oldPosition,
  }) {
    if (activity == null) goIdle();
    assert(activity != null);
  }

  double get pageLast {
    final double ratio = controller.action.value == PhotolineAction.close
        ? controller.closeRatio
        : controller.openRatio;
    return (maxScrollExtent + viewportDimension) / (viewportDimension * ratio) -
        1;
  }

  double? _cachedPage;

  double _preciesse(double actual) {
    final double round = actual.roundToDouble();
    return (actual - round).abs() < precisionErrorTolerance ? round : actual;
  }

  void forceExtent(double extent) {
    if (activity is PhotolineActivityMixin) {
      (activity! as PhotolineActivityMixin).forceExtent(extent);
    }
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
        case PhotolineAction.upload:
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
      case PhotolineAction.upload:
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
      case PhotolineAction.upload:
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
    (other as PhotolineScrollPosition)._activity = null;
    if (other.runtimeType != runtimeType) {
      activity!.resetActivity();
    }
    context.setIgnorePointer(activity!.shouldIgnorePointer);
    isScrollingNotifier.value = activity!.isScrolling;

    assert(_cachedPage == null);
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

  // ================================================ override 0
  @override
  void beginActivity(ScrollActivity? newActivity) {
    _heldPreviousVelocity = 0.0;
    if (newActivity == null) return;
    assert(newActivity.delegate == this);
    _beginActivity1(newActivity);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!activity!.isScrolling) updateUserScrollDirection(ScrollDirection.idle);
  }

  void _beginActivity1(ScrollActivity? newActivity) {
    if (newActivity == null) return;
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity!.shouldIgnorePointer;
      wasScrolling = _activity!.isScrolling;
      if (wasScrolling && !newActivity.isScrolling) {
        // Notifies and then saves the scroll offset.
        didEndScroll();
      }
      _activity!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    if (oldIgnorePointer != activity!.shouldIgnorePointer) {
      context.setIgnorePointer(activity!.shouldIgnorePointer);
    }
    isScrollingNotifier.value = activity!.isScrolling;
    if (!wasScrolling && _activity!.isScrolling) {
      didStartScroll();
    }
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
  double setPixels(double newPixels) {
    //assert(activity!.isScrolling);
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

  double _heldPreviousVelocity = 0.0;

  @override
  AxisDirection get axisDirection => context.axisDirection;

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
    activity?.dispose();
    _activity = null;
    isScrollingNotifier.dispose();
  }

  @override
  void jumpToWithoutSettling(double value) {}

  // ================================================ override
  final PhotolineController controller;

  @override
  double get minScrollExtent => _minScrollExtent!;
  double? _minScrollExtent;

  @override
  double get maxScrollExtent => _maxScrollExtent!;
  double? _maxScrollExtent;

  @override
  bool get hasContentDimensions =>
      _minScrollExtent != null && _maxScrollExtent != null;

  /// The additional velocity added for a [forcePixels] change in a single
  /// frame.
  ///
  /// This value is used by [recommendDeferredLoading] in addition to the
  /// [activity]'s [ScrollActivity.velocity] to ask the [physics] whether or
  /// not to defer loading. It accounts for the fact that a [forcePixels] call
  /// may involve a [ScrollActivity] with 0 velocity, but the scrollable is
  /// still instantaneously moving from its current position to a potentially
  /// very far position, and which is of interest to callers of
  /// [recommendDeferredLoading].
  ///
  /// For example, if a scrollable is currently at 5000 pixels, and we [jumpTo]
  /// 0 to get back to the top of the list, we would have an implied velocity of
  /// -5000 and an `activity.velocity` of 0. The jump may be going past a
  /// number of resource intensive widgets which should avoid doing work if the
  /// position jumps past them.
  double _impliedVelocity = 0;

  @override
  double get pixels => _pixels!;
  double? _pixels;

  @override
  bool get hasPixels => _pixels != null;

  @override
  double get viewportDimension => _viewportDimension!;
  double? _viewportDimension;

  @override
  bool get hasViewportDimension => _viewportDimension != null;

  /// Whether [viewportDimension], [minScrollExtent], [maxScrollExtent],
  /// [outOfRange], and [atEdge] are available.
  ///
  /// Set to true just before the first time [applyNewDimensions] is called.
  @override
  bool get haveDimensions => _haveDimensions;
  bool _haveDimensions = false;

  @override
  double get devicePixelRatio => context.devicePixelRatio;

  /// Change the value of [pixels] to the new value, without notifying any
  /// customers.
  ///
  /// This is used to adjust the position while doing layout. In particular,
  /// this is typically called as a response to [applyViewportDimension] or
  /// [applyContentDimensions] (in both cases, if this method is called, those
  /// methods should then return false to indicate that the position has been
  /// adjusted).
  ///
  /// Calling this is rarely correct in other contexts. It will not immediately
  /// cause the rendering to change, since it does not notify the widgets or
  /// render objects that might be listening to this object: they will only
  /// change when they next read the value, which could be arbitrarily later. It
  /// is generally only appropriate in the very specific case of the value being
  /// corrected during layout (since then the value is immediately read), in the
  /// specific case of a [ScrollPosition] with a single viewport customer.
  ///
  /// To cause the position to jump or animate to a new value, consider [jumpTo]
  /// or [animateTo], which will honor the normal conventions for changing the
  /// scroll offset.
  ///
  /// To force the [pixels] to a particular value without honoring the normal
  /// conventions for changing the scroll offset, consider [forcePixels]. (But
  /// see the discussion there for why that might still be a bad idea.)
  ///
  /// See also:
  ///
  ///  * [correctBy], which is a method of [ViewportOffset] used
  ///    by viewport render objects to correct the offset during layout
  ///    without notifying its listeners.
  ///  * [jumpTo], for making changes to position while not in the
  ///    middle of layout and applying the new position immediately.
  ///  * [animateTo], which is like [jumpTo] but animating to the
  ///    destination offset.
  // ignore: use_setters_to_change_properties, (API is intended to discourage setting value)
  @override
  void correctPixels(double value) {
    _pixels = value;
  }

  /// Apply a layout-time correction to the scroll offset.
  ///
  /// This method should change the [pixels] value by `correction`, but without
  /// calling [notifyListeners]. It is called during layout by the
  /// [RenderViewport], before [applyContentDimensions]. After this method is
  /// called, the layout will be recomputed and that may result in this method
  /// being called again, though this should be very rare.
  ///
  /// See also:
  ///
  ///  * [jumpTo], for also changing the scroll position when not in layout.
  ///    [jumpTo] applies the change immediately and notifies its listeners.
  ///  * [correctPixels], which is used by the [ScrollPosition] itself to
  ///    set the offset initially during construction or after
  ///    [applyViewportDimension] or [applyContentDimensions] is called.
  @override
  void correctBy(double correction) {
    assert(
      hasPixels,
      'An initial pixels value must exist by calling correctPixels on the ScrollPosition',
    );
    _pixels = _pixels! + correction;
    _didChangeViewportDimensionOrReceiveCorrection = true;
  }

  /// Change the value of [pixels] to the new value, and notify any customers,
  /// but without honoring normal conventions for changing the scroll offset.
  ///
  /// This is used to implement [jumpTo]. It can also be used adjust the
  /// position when the dimensions of the viewport change. It should only be
  /// used when manually implementing the logic for honoring the relevant
  /// conventions of the class. For example, [ScrollPositionWithSingleContext]
  /// introduces [ScrollActivity] objects and uses [forcePixels] in conjunction
  /// with adjusting the activity, e.g. by calling
  /// [ScrollPositionWithSingleContext.goIdle], so that the activity does
  /// not immediately set the value back. (Consider, for instance, a case where
  /// one is using a [DrivenScrollActivity]. That object will ignore any calls
  /// to [forcePixels], which would result in the rendering stuttering: changing
  /// in response to [forcePixels], and then changing back to the next value
  /// derived from the animation.)
  ///
  /// To cause the position to jump or animate to a new value, consider [jumpTo]
  /// or [animateTo].
  ///
  /// This should not be called during layout (e.g. when setting the initial
  /// scroll offset). Consider [correctPixels] if you find you need to adjust
  /// the position during layout.
  @override
  @protected
  void forcePixels(double value) {
    assert(hasPixels);
    _impliedVelocity = value - pixels;
    _pixels = value;
    notifyListeners();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _impliedVelocity = 0;
    }, debugLabel: 'ScrollPosition.resetVelocity');
  }

  /// Returns the overscroll by applying the boundary conditions.
  ///
  /// If the given value is in bounds, returns 0.0. Otherwise, returns the
  /// amount of value that cannot be applied to [pixels] as a result of the
  /// boundary conditions. If the [physics] allow out-of-bounds scrolling, this
  /// method always returns 0.0.
  ///
  /// The default implementation defers to the [physics] object's
  /// [ScrollPhysics.applyBoundaryConditions].
  @override
  double applyBoundaryConditions(double value) {
    final double result = physics.applyBoundaryConditions(this, value);
    assert(() {
      final double delta = value - pixels;
      if (result.abs() > delta.abs()) {
        throw FlutterError(
          '${physics.runtimeType}.applyBoundaryConditions returned invalid overscroll value.\n'
          'The method was called to consider a change from $pixels to $value, which is a '
          'delta of ${delta.toStringAsFixed(1)} units. However, it returned an overscroll of '
          '${result.toStringAsFixed(1)} units, which has a greater magnitude than the delta. '
          'The applyBoundaryConditions method is only supposed to reduce the possible range '
          'of movement, not increase it.\n'
          'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
          'viewport dimension is $viewportDimension.',
        );
      }
      return true;
    }());
    return result;
  }

  bool _didChangeViewportDimensionOrReceiveCorrection = true;

  bool _pendingDimensions = false;
  ScrollMetrics? _lastMetrics;

  // True indicates that there is a ScrollMetrics update notification pending.
  bool _haveScheduledUpdateNotification = false;
  Axis? _lastAxis;

  bool _isMetricsChanged() {
    assert(haveDimensions);
    final ScrollMetrics currentMetrics = copyWith();

    return _lastMetrics == null ||
        !(currentMetrics.extentBefore == _lastMetrics!.extentBefore &&
            currentMetrics.extentInside == _lastMetrics!.extentInside &&
            currentMetrics.extentAfter == _lastMetrics!.extentAfter &&
            currentMetrics.axisDirection == _lastMetrics!.axisDirection);
  }

  Set<SemanticsAction>? _semanticActions;

  /// Called whenever the scroll position or the dimensions of the scroll view
  /// change to schedule an update of the available semantics actions. The
  /// actual update will be performed in the next frame. If non is pending
  /// a frame will be scheduled.
  ///
  /// For example: If the scroll view has been scrolled all the way to the top,
  /// the action to scroll further up needs to be removed as the scroll view
  /// cannot be scrolled in that direction anymore.
  ///
  /// This method is potentially called twice per frame (if scroll position and
  /// scroll view dimensions both change) and therefore shouldn't do anything
  /// expensive.
  void _updateSemanticActions() {
    final (SemanticsAction forward, SemanticsAction backward) =
        switch (axisDirection) {
      AxisDirection.up => (
          SemanticsAction.scrollDown,
          SemanticsAction.scrollUp
        ),
      AxisDirection.down => (
          SemanticsAction.scrollUp,
          SemanticsAction.scrollDown
        ),
      AxisDirection.left => (
          SemanticsAction.scrollRight,
          SemanticsAction.scrollLeft
        ),
      AxisDirection.right => (
          SemanticsAction.scrollLeft,
          SemanticsAction.scrollRight
        ),
    };

    final Set<SemanticsAction> actions = <SemanticsAction>{};
    if (pixels > minScrollExtent) {
      actions.add(backward);
    }
    if (pixels < maxScrollExtent) {
      actions.add(forward);
    }

    if (setEquals<SemanticsAction>(actions, _semanticActions)) {
      return;
    }

    _semanticActions = actions;
    context.setSemanticsActions(_semanticActions!);
  }

  ScrollPositionAlignmentPolicy _maybeFlipAlignment(
      ScrollPositionAlignmentPolicy alignmentPolicy) {
    return switch (alignmentPolicy) {
      // Don't flip when explicit.
      ScrollPositionAlignmentPolicy.explicit => alignmentPolicy,
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd =>
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart =>
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    };
  }

  ScrollPositionAlignmentPolicy _applyAxisDirectionToAlignmentPolicy(
      ScrollPositionAlignmentPolicy alignmentPolicy) {
    return switch (axisDirection) {
      // Start and end alignments must account for axis direction.
      // When focus is requested for example, it knows the directionality of the
      // keyboard keys initiating traversal, but not the direction of the
      // Scrollable.
      AxisDirection.up ||
      AxisDirection.left =>
        _maybeFlipAlignment(alignmentPolicy),
      AxisDirection.down || AxisDirection.right => alignmentPolicy,
    };
  }

  @override
  Future<void> ensureVisible(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
  }) async {
    assert(object.attached);
    final RenderAbstractViewport? viewport =
        RenderAbstractViewport.maybeOf(object);
    // If no viewport is found, return.
    if (viewport == null) {
      return;
    }

    Rect? targetRect;
    if (targetRenderObject != null && targetRenderObject != object) {
      targetRect = MatrixUtils.transformRect(
        targetRenderObject.getTransformTo(object),
        object.paintBounds.intersect(targetRenderObject.paintBounds),
      );
    }

    double target;
    switch (_applyAxisDirectionToAlignmentPolicy(alignmentPolicy)) {
      case ScrollPositionAlignmentPolicy.explicit:
        target = viewport
            .getOffsetToReveal(
              object,
              alignment,
              rect: targetRect,
              axis: axis,
            )
            .offset;
        target = clampDouble(target, minScrollExtent, maxScrollExtent);
      case ScrollPositionAlignmentPolicy.keepVisibleAtEnd:
        target = viewport
            .getOffsetToReveal(
              object,
              1.0, // Aligns to end
              rect: targetRect,
              axis: axis,
            )
            .offset;
        target = clampDouble(target, minScrollExtent, maxScrollExtent);
        if (target < pixels) {
          target = pixels;
        }
      case ScrollPositionAlignmentPolicy.keepVisibleAtStart:
        target = viewport
            .getOffsetToReveal(
              object,
              0.0, // Aligns to start
              rect: targetRect,
              axis: axis,
            )
            .offset;
        target = clampDouble(target, minScrollExtent, maxScrollExtent);
        if (target > pixels) {
          target = pixels;
        }
    }

    if (target == pixels) {
      return;
    }

    if (duration == Duration.zero) {
      jumpTo(target);
      return;
    }

    return animateTo(target, duration: duration, curve: curve);
  }

  @override
  Future<void> moveTo(
    double to, {
    Duration? duration,
    Curve? curve,
    bool? clamp = true,
  }) {
    assert(clamp != null);

    if (clamp!) {
      to = clampDouble(to, minScrollExtent, maxScrollExtent);
    }

    return super.moveTo(to, duration: duration, curve: curve);
  }

  @override
  bool get allowImplicitScrolling => physics.allowImplicitScrolling;

  /// The currently operative [ScrollActivity].
  ///
  /// If the scroll position is not performing any more specific activity, the
  /// activity will be an [IdleScrollActivity]. To determine whether the scroll
  /// position is idle, check the [isScrollingNotifier].
  ///
  /// Call [beginActivity] to change the current activity.
  @override
  ScrollActivity? get activity => _activity;
  ScrollActivity? _activity;

  // NOTIFICATION DISPATCH

  /// Called by [beginActivity] to report when an activity has started.
  @override
  void didStartScroll() {
    activity!.dispatchScrollStartNotification(
        copyWith(), context.notificationContext);
  }

  /// Called by [setPixels] to report a change to the [pixels] position.
  @override
  void didUpdateScrollPositionBy(double delta) {
    activity?.dispatchScrollUpdateNotification(
        copyWith(), context.notificationContext!, delta);
  }

  /// Called by [beginActivity] to report when an activity has ended.
  ///
  /// This also saves the scroll offset using [saveScrollOffset].
  @override
  void didEndScroll() {
    activity!.dispatchScrollEndNotification(
        copyWith(), context.notificationContext!);
    saveOffset();
    if (keepScrollOffset) {
      saveScrollOffset();
    }
  }

  /// Called by [setPixels] to report overscroll when an attempt is made to
  /// change the [pixels] position. Overscroll is the amount of change that was
  /// not applied to the [pixels] value.
  @override
  void didOverscrollBy(double value) {
    assert(activity!.isScrolling);
    activity!.dispatchOverscrollNotification(
        copyWith(), context.notificationContext!, value);
  }

  /// Dispatches a notification that the [userScrollDirection] has changed.
  ///
  /// Subclasses should call this function when they change [userScrollDirection].
  @override
  void didUpdateScrollDirection(ScrollDirection direction) {
    UserScrollNotification(
            metrics: copyWith(),
            context: context.notificationContext!,
            direction: direction)
        .dispatch(context.notificationContext);
  }

  /// Dispatches a notification that the [ScrollMetrics] have changed.
  @override
  void didUpdateScrollMetrics() {
    assert(SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks);
    assert(_haveScheduledUpdateNotification);
    _haveScheduledUpdateNotification = false;
    if (context.notificationContext != null) {
      ScrollMetricsNotification(
              metrics: copyWith(), context: context.notificationContext!)
          .dispatch(context.notificationContext);
    }
  }

  /// Provides a heuristic to determine if expensive frame-bound tasks should be
  /// deferred.
  ///
  /// The actual work of this is delegated to the [physics] via
  /// [ScrollPhysics.recommendDeferredLoading] called with the current
  /// [activity]'s [ScrollActivity.velocity].
  ///
  /// Returning true from this method indicates that the [ScrollPhysics]
  /// evaluate the current scroll velocity to be great enough that expensive
  /// operations impacting the UI should be deferred.
  @override
  bool recommendDeferredLoading(BuildContext context) {
    assert(activity != null);
    return physics.recommendDeferredLoading(
      activity!.velocity + _impliedVelocity,
      copyWith(),
      context,
    );
  }

  @override
  void notifyListeners() {
    _updateSemanticActions();
    super.notifyListeners();
  }

  @override
  void saveScrollOffset() {}

  @override
  void restoreScrollOffset() {}

  @override
  void restoreOffset(double offset, {bool initialRestore = false}) {}

  @override
  void saveOffset() {}
}
