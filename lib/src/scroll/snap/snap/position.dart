import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';
import 'package:photoline/src/scroll/snap/snap/physics.dart';

class ScrollSnapPosition extends ScrollPositionWithSingleContext {
  ScrollSnapPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  final ScrollSnapController controller;

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
        physics is ScrollSnapPhysics &&
        kProfileMode) {
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

  void scrollNextPhotoline(int direction) {
    final photolines = controller.snapPhotolines;
    if (photolines == null) return;

    double dist = double.infinity;
    double so = 0;
    int current = -1;
    final List<double> offsets = [];

    final (heightClose, heightOpen) =
        (physics as ScrollSnapPhysics).photolineHeights(this);

    for (final p in photolines()) {
      final d = so - pixels;
      offsets.add(so);
      if (dist.isInfinite || d.abs() < dist.abs()) {
        dist = d;
        current = offsets.length - 1;
      }
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

    current += direction;

    if (current < 0 || current >= offsets.length) return;

    //unawaited(animateTo(offsets[current],duration: const Duration(milliseconds: 300), curve: Curves.linear));
    beginActivity(BallisticScrollActivity(
      this,
      ScrollSpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1.2,
          stiffness: 80.0,
          ratio: 1.2,
        ),
        pixels,
        offsets[current],
        0,
        tolerance: physics.toleranceFor(this),
      ),
      context.vsync,
      activity?.shouldIgnorePointer ?? true,
    ));
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

    return super.setPixels(newPixels);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void didUpdateScrollPositionBy(double delta) {
    //controller.delta = delta;
    super.didUpdateScrollPositionBy(delta);
  }

  @override
  void applyNewDimensions() {
    if (activity is BallisticScrollActivity) return;
    super.applyNewDimensions();
  }

  @override
  ScrollActivity? get activity => super.activity;

  @override
  void pointerScroll(double delta) {
    return;
  }
}
