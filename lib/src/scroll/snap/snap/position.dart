import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photoline/src/scroll/snap/controller.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';

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

    if (controller.headerHolder != null) {
      final h = controller.headerHolder!;
      final e = h.extent.value;
      minScrollExtent -= e;
      maxScrollExtent += e;
    }

    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  double setPixels(double newPixels) {
    final delta = newPixels - pixels;
    if (delta == 0) return super.setPixels(newPixels);

    if (controller.headerHolder != null) {
      final holder = controller.headerHolder!;
      double h = holder.extent.value;

      if (delta > 0) {
        // scroll up
        final dt = holder.minExtent - h - delta;
        print(dt);
      }

      // extent.value = clampDouble(extent.value - delta, minExtent, maxExtent);
      //  headerHolder?.delta = delta;
    }

    return super.setPixels(newPixels);
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
