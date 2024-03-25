import 'package:flutter/material.dart';
import 'package:photoline_example/nested_scroll/header/delegate.dart';
import 'package:photoline_example/nested_scroll/header/header.dart';
import 'package:photoline_example/nested_scroll/header/render_sliver.dart';

class ScrollSnapSliverHeaderRenderObjectElement extends RenderObjectElement {
  ScrollSnapSliverHeaderRenderObjectElement(ScrollSnapSliverHeader super.widget);

  @override
  ScrollSnapSliverHeaderRenderSliver get renderObject =>
      super.renderObject as ScrollSnapSliverHeaderRenderSliver;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    renderObject.mixinElement = this;
  }

  @override
  void unmount() {
    renderObject.mixinElement = null;
    super.unmount();
  }

  @override
  void update(ScrollSnapSliverHeader newWidget) {
    final ScrollSnapSliverHeader oldWidget = widget as ScrollSnapSliverHeader;
    super.update(newWidget);
    final ScrollSnapSliverHeaderDelegate newDelegate = newWidget.delegate;
    final ScrollSnapSliverHeaderDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) {
      renderObject.triggerRebuild();
    }
  }

  @override
  void performRebuild() {
    super.performRebuild();
    renderObject.triggerRebuild();
  }

  Element? child;

  void buildEx(double shrinkOffset, bool overlapsContent) {
    owner!.buildScope(this, () {
      final ScrollSnapSliverHeader sliverPersistentHeaderRenderObjectWidget =
      widget as ScrollSnapSliverHeader;
      child = updateChild(
        child,
        sliverPersistentHeaderRenderObjectWidget.delegate
            .build(this, shrinkOffset, overlapsContent),
        null,
      );
    });
  }

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
