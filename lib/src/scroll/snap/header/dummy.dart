import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/scroll/snap/header/holder.dart';

class ScrollSnapHeaderDummy extends RenderObjectWidget {
  const ScrollSnapHeaderDummy({
    super.key,
    required this.holder,
  });

  final SliverHeaderHolder holder;

  @override
  ScrollSnapHeaderDummyObject createRenderObject(BuildContext context) =>
      ScrollSnapHeaderDummyObject(holder: holder);

  @override
  void updateRenderObject(
      BuildContext context, ScrollSnapHeaderDummyObject renderObject) {}

  @override
  ScrollSnapHeaderDummyElement createElement() =>
      ScrollSnapHeaderDummyElement(this);
}

class ScrollSnapHeaderDummyElement extends RenderObjectElement {
  ScrollSnapHeaderDummyElement(ScrollSnapHeaderDummy super.widget);

  @override
  ScrollSnapHeaderDummyObject get renderObject =>
      super.renderObject as ScrollSnapHeaderDummyObject;

  Element? child;

  @override
  void forgetChild(Element child) {
    assert(child == this.child);
    this.child = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, Object? slot) {
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveRenderObjectChild(
      covariant RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(covariant RenderObject child, Object? slot) {
    renderObject.child = null;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (child != null) visitor(child!);
  }
}

class ScrollSnapHeaderDummyObject extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  ScrollSnapHeaderDummyObject({
    RenderBox? child,
    required this.holder,
  }) {
    this.child = child;
  }

  SliverHeaderHolder holder;

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return 0;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  void attach(PipelineOwner owner) {
    holder.extent.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    holder.extent.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    geometry = SliverGeometry(
      scrollExtent: holder.maxExtent,
      paintExtent: holder.extent.value,
      layoutExtent: holder.extent.value,
      maxPaintExtent: holder.extent.value,
      maxScrollObstructionExtent: holder.minExtent,
    );
  }
}
