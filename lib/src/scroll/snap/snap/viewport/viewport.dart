import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'render.dart';

class ScrollSnapViewport extends MultiChildRenderObjectWidget implements Viewport {
  const ScrollSnapViewport({
    super.key,
    required this.offset,
    this.scrollCacheExtent,
    super.children,
  });

  @override
  final ViewportOffset offset;

  @override
  final ScrollCacheExtent? scrollCacheExtent;

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderViewportPhotoline(
      crossAxisDirection: AxisDirection.right,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    renderObject
      ..offset = offset
      ..scrollCacheExtent = scrollCacheExtent
      ..clipBehavior = clipBehavior;
  }

  @override
  MultiChildRenderObjectElement createElement() => _ViewportElement(this);

  @override
  AxisDirection get axisDirection => AxisDirection.down;

  @override
  AxisDirection? get crossAxisDirection => null;

  @override
  double get anchor => 0;

  @override
  Key? get center => null;

  @override
  Clip get clipBehavior => Clip.hardEdge;

  @override
  SliverPaintOrder get paintOrder => SliverPaintOrder.lastIsTop;

  @Deprecated('Use scrollCacheExtent instead. This feature was deprecated after v3.41.0-0.0.pre.')
  @override
  double? get cacheExtent => scrollCacheExtent?.value;

  @Deprecated('Use scrollCacheExtent instead. This feature was deprecated after v3.41.0-0.0.pre.')
  @override
  CacheExtentStyle get cacheExtentStyle => scrollCacheExtent?.style ?? CacheExtentStyle.pixel;
}

class _ViewportElement extends MultiChildRenderObjectElement with NotifiableElementMixin, ViewportElementMixin {
  _ViewportElement(ScrollSnapViewport super.widget);

  bool _doingMountOrUpdate = false;
  int? _centerSlotIndex;

  @override
  RenderViewport get renderObject => super.renderObject as RenderViewport;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.mount(parent, newSlot);
    _updateCenter();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.update(newWidget);
    _updateCenter();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  void _updateCenter() {
    final viewport = widget as Viewport;
    if (viewport.center != null) {
      var elementIndex = 0;
      for (final Element e in children) {
        if (e.widget.key == viewport.center) {
          renderObject.center = e.renderObject as RenderSliver?;
          break;
        }
        elementIndex++;
      }
      assert(elementIndex < children.length);
      _centerSlotIndex = elementIndex;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject as RenderSliver?;
      _centerSlotIndex = 0;
    } else {
      renderObject.center = null;
      _centerSlotIndex = null;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, IndexedSlot<Element?> slot) {
    super.insertRenderObjectChild(child, slot);
    if (!_doingMountOrUpdate && slot.index == _centerSlotIndex) {
      renderObject.center = child as RenderSliver?;
    }
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    IndexedSlot<Element?> oldSlot,
    IndexedSlot<Element?> newSlot,
  ) {
    super.moveRenderObjectChild(child, oldSlot, newSlot);
    assert(_doingMountOrUpdate);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    super.removeRenderObjectChild(child, slot);
    if (!_doingMountOrUpdate && renderObject.center == child) {
      renderObject.center = null;
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children
        .where((e) {
          final renderSliver = e.renderObject! as RenderSliver;
          return renderSliver.geometry!.visible;
        })
        .forEach(visitor);
  }
}
