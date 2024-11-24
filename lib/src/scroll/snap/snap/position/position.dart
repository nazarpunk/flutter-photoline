import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';
import 'package:photoline/src/scroll/snap/snap/physics.dart';

part 'override.dart';

/// [PageView], [ScrollPositionWithSingleContext]
class ScrollSnapPosition extends ScrollSnapPositionOverride {
  ScrollSnapPosition({
    required super.controller,
    required super.physics,
    required super.context,
    double? initialPixels = 0.0,
    super.oldPosition,
  }) {
    // If oldPosition is not null, the superclass will first call absorb(),
    // which may set _pixels and _activity.
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }
    if (activity == null) {
      goIdle();
    }
    assert(activity != null);
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions =
        hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);

    /// snap last photolines
    if (controller.snapPhotolines != null &&
        controller.boxConstraints != null &&
        physics is ScrollSnapPhysics) {
      final phs = physics as ScrollSnapPhysics;

      final double? oldPixels = hasPixels ? pixels : null;

      int i = -1;
      double newPixels = 0;

      final (heightClose, heightOpen) = phs.photolineHeights(this);

      for (final p in controller.snapPhotolines!()) {
        i++;
        if (i == 3) break;
        switch (p.action.value) {
          case PhotolineAction.open:
          case PhotolineAction.opening:
            newPixels += heightOpen;
          case PhotolineAction.drag:
          case PhotolineAction.closing:
          case PhotolineAction.close:
          case PhotolineAction.upload:
            newPixels += heightClose + p.bottomHeightAddition();
        }
        newPixels += controller.photolineGap;
      }

      print('$oldPixels | $newPixels');
      if (newPixels != oldPixels) {
        //correctPixels(newPixels);
        return false;
      }
    }
    return result;
  }

  @override
  bool correctForNewDimensions(
      ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    return true;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    /// snapLast box
    if (controller.snap) {
      if (controller.box.isNotEmpty) {
        final box = SplayTreeMap<int, ScrollSnapBox>.from(
            controller.box, (a, b) => b.compareTo(a));
        if (controller.snapLast) {
          maxScrollExtent =
              math.max(maxScrollExtent, box.entries.first.value.scrollOffset);
        } else {
          double h = 0;
          double so = box.entries.first.value.scrollOffset;

          for (final b in box.entries) {
            final v = b.value;
            h += v.height;
            if (h >= viewportDimension) {
              maxScrollExtent = math.max(maxScrollExtent, so);
              break;
            }
            so = v.scrollOffset;
          }
        }
      }
    }

    /// cage
    if (controller.snapCage != null) {
      final boxes = SplayTreeMap<int, ScrollSnapBox>.from(
          controller.box, (a, b) => a.compareTo(b));

      ScrollSnapBox? box;
      for (final e in boxes.entries) {
        if (e.key == controller.snapCage) {
          box = e.value;
          break;
        }
      }

      if (box != null) {
        maxScrollExtent = box.scrollOffset;
        for (final e in boxes.entries) {
          if (e.key > controller.snapCage!) break;
          final diff = box.scrollOffset - e.value.scrollOffset;
          if (diff + box.height < viewportDimension) {
            minScrollExtent = e.value.scrollOffset;
            break;
          }
        }
      }
    }

    /// snap last photolines
    if (controller.snapPhotolines != null &&
        controller.boxConstraints != null &&
        physics is ScrollSnapPhysics) {
      final p = physics as ScrollSnapPhysics;
      double so = 0;

      final (heightClose, heightOpen) = p.photolineHeights(this);
      final list = controller.snapPhotolines!();

      for (int i = 0; i < list.length - 1; i++) {
        final p = list[i];
        switch (p.action.value) {
          case PhotolineAction.open:
          case PhotolineAction.opening:
            so += heightOpen;
          case PhotolineAction.drag:
          case PhotolineAction.closing:
          case PhotolineAction.close:
          case PhotolineAction.upload:
            so += heightClose + p.bottomHeightAddition();
        }
        so += controller.photolineGap;
      }
      maxScrollExtent = math.max(maxScrollExtent, so);
    }

    if (controller.headerHolder != null) {
      final h = controller.headerHolder!;
      final e = h.height.value;
      minScrollExtent -= e;
      //maxScrollExtent += e;
    }

    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation =
        physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      beginActivity(BallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        shouldIgnorePointer,
      ));
    } else {
      goIdle();
    }
  }

  @override
  double setPixels(double newPixels) {
    final delta = newPixels - pixels;
    if (delta == 0) return super.setPixels(newPixels);

    if (controller.headerHolder != null) {
      final holder = controller.headerHolder!;
      holder.height.value = clampDouble(
          holder.height.value - delta, holder.minHeight, holder.maxHeight);
    }

    assert(activity!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void applyNewDimensions() {
    //print('💩 applyNewDimensions');
    if (activity is BallisticScrollActivity) return;
    super.applyNewDimensions();
    context.setCanDrag(physics.shouldAcceptUserOffset(this));
  }

  @override
  void pointerScroll(double delta) {
    if (!kProfileMode) return;

    // If an update is made to pointer scrolling here, consider if the same
    // (or similar) change should be made in
    // _NestedScrollCoordinator.pointerScroll.
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final double targetPixels =
        math.min(math.max(pixels + delta, minScrollExtent), maxScrollExtent);
    if (targetPixels != pixels) {
      goIdle();
      updateUserScrollDirection(
        -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
      );
      final double oldPixels = pixels;
      // Set the notifier before calling force pixels.
      // This is set to false again after going ballistic below.
      isScrollingNotifier.value = true;
      forcePixels(targetPixels);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
      goBallistic(0.0);
    }
  }

  // ===========================================

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other is! ScrollSnapPosition) {
      goIdle();
      return;
    }
    activity!.updateDelegate(this);

    _userScrollDirection = other._userScrollDirection;
    assert(_currentDrag == null);
    if (other._currentDrag != null) {
      _currentDrag = other._currentDrag;
      _currentDrag!.updateDelegate(this);
      other._currentDrag = null;
    }
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    heldPreviousVelocity = 0.0;
    if (newActivity == null) {
      return;
    }
    assert(newActivity.delegate == this);
    super.beginActivity(newActivity);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!activity!.isScrolling) {
      updateUserScrollDirection(ScrollDirection.idle);
    }
  }

}
