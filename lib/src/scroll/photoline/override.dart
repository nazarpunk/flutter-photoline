// ignore_for_file: must_call_super
// ignore_for_file: overridden_fields

part of 'position.dart';

abstract class PhotolineScrollPositionOverride extends ScrollPosition
    implements ScrollActivityDelegate, PhotolineScrollMetrics {
  PhotolineScrollPositionOverride({
    required this.controller,
    required super.physics,
    required super.context,
    super.oldPosition,
  });

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

  /// Verifies that the new content and viewport dimensions are acceptable.
  ///
  /// Called by [applyContentDimensions] to determine its return value.
  ///
  /// Should return true if the current scroll offset is correct given
  /// the new content and viewport dimensions.
  ///
  /// Otherwise, should call [correctPixels] to correct the scroll
  /// offset given the new dimensions, and then return false.
  ///
  /// This is only called when [haveDimensions] is true.
  ///
  /// The default implementation defers to [ScrollPhysics.adjustPositionForNewDimensions].
  @override
  @protected
  bool correctForNewDimensions(
      ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    final double newPixels = physics.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: activity!.isScrolling,
      velocity: activity!.velocity,
    );
    if (newPixels != pixels) {
      correctPixels(newPixels);
      return false;
    }
    return true;
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

  /// Animates the position such that the given object is as visible as possible
  /// by just scrolling this position.
  ///
  /// The optional `targetRenderObject` parameter is used to determine which area
  /// of that object should be as visible as possible. If `targetRenderObject`
  /// is null, the entire [RenderObject] (as defined by its
  /// [RenderObject.paintBounds]) will be as visible as possible. If
  /// `targetRenderObject` is provided, it must be a descendant of the object.
  ///
  /// See also:
  ///
  ///  * [ScrollPositionAlignmentPolicy] for the way in which `alignment` is
  ///    applied, and the way the given `object` is aligned.
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

  /// This notifier's value is true if a scroll is underway and false if the scroll
  /// position is idle.
  ///
  /// Listeners added by stateful widgets should be removed in the widget's
  /// [State.dispose] method.
  @override
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);

  /// Animates the position from its current value to the given value.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, or whenever another activity is started, or whenever the
  /// animation reaches the edge of the viewport and attempts to overscroll. (If
  /// the [ScrollPosition] does not overscroll but instead allows scrolling
  /// beyond the extents, then going beyond the extents will not interrupt the
  /// animation.)
  ///
  /// The animation is indifferent to changes to the viewport or content
  /// dimensions.
  ///
  /// Once the animation has completed, the scroll position will attempt to
  /// begin a ballistic activity in case its value is not stable (for example,
  /// if it is scrolled beyond the extents and in that situation the scroll
  /// position would normally bounce back).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  ///
  /// The animation is typically handled by an [DrivenScrollActivity].
  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  });

  /// Jumps the scroll position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// If this method changes the scroll position, a sequence of start/update/end
  /// scroll notifications will be dispatched. No overscroll notifications can
  /// be generated by this method.
  @override
  void jumpTo(double value);

  /// Changes the scrolling position based on a pointer signal from current
  /// value to delta without animation and without checking if new value is in
  /// range, taking min/max scroll extent into account.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// This method dispatches the start/update/end sequence of scrolling
  /// notifications.
  ///
  /// This method is very similar to [jumpTo], but [pointerScroll] will
  /// update the [ScrollDirection].
  @override
  void pointerScroll(double delta);

  /// Calls [jumpTo] if duration is null or [Duration.zero], otherwise
  /// [animateTo] is called.
  ///
  /// If [clamp] is true (the default) then [to] is adjusted to prevent over or
  /// underscroll.
  ///
  /// If [animateTo] is called then [curve] defaults to [Curves.ease].
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

  /// Change the current [activity], disposing of the old one and
  /// sending scroll notifications as necessary.
  ///
  /// If the argument is null, this method has no effect. This is convenient for
  /// cases where the new activity is obtained from another method, and that
  /// method might return null, since it means the caller does not have to
  /// explicitly null-check the argument.
  @override
  void beginActivity(ScrollActivity? newActivity) {
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
    activity!.dispatchScrollUpdateNotification(
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
  void dispose() {
    activity?.dispose();
    _activity = null;
    isScrollingNotifier.dispose();
    super.dispose();
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
