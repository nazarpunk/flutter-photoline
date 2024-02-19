import 'package:flutter/rendering.dart';
import 'package:photoline/src/scroll/snap/controller.dart';
import 'package:photoline/src/scroll/snap/snap/box.dart';

class RenderSliverSnapList extends RenderSliverList {
  RenderSliverSnapList({
    required this.controller,
    required super.childManager,
  });

  final ScrollSnapController controller;

  @override
  void performLayout() {
    super.performLayout();

    final SliverConstraints constraints = this.constraints;
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;

    if (firstChild != null) {
      RenderBox? child = firstChild;
      while (true) {
        final SliverMultiBoxAdaptorParentData childParentData = child!.parentData! as SliverMultiBoxAdaptorParentData;
        final so = childScrollOffset(child);
        if (so != null) {
          final int i = indexOf(child);
          controller.box[i] = ScrollSnapBox(
            index: indexOf(child),
            width: child.size.width,
            height: child.size.height,
            scrollOffset: so,
            viewportScrollOffset: scrollOffset,
          );
        }
        if (child == lastChild) break;
        child = childParentData.nextSibling;
      }
    }
  }
}
