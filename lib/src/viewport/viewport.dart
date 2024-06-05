import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/viewport/render.dart';

export 'package:flutter/rendering.dart' show AxisDirection, GrowthDirection;

class PhotolineViewport extends MultiChildRenderObjectWidget {
  const PhotolineViewport({
    super.key,
    this.anchor = 0.0,
    required this.offset,
    required this.cacheExtent,
    List<Widget> slivers = const <Widget>[],
  }) : super(children: slivers);

  final double anchor;

  final ViewportOffset offset;

  final double cacheExtent;

  @override
  PhotolineRenderViewport createRenderObject(BuildContext context) {
    return PhotolineRenderViewport(
      offset: offset,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, PhotolineRenderViewport renderObject) {
    renderObject
      ..offset = offset
      ..cacheExtent = cacheExtent;
  }

  @override
  MultiChildRenderObjectElement createElement() => _ViewportElement(this);
}

class _ViewportElement extends MultiChildRenderObjectElement
    with NotifiableElementMixin, ViewportElementMixin {
  _ViewportElement(PhotolineViewport super.widget);

  bool _doingMountOrUpdate = false;

  @override
  PhotolineRenderViewport get renderObject =>
      super.renderObject as PhotolineRenderViewport;

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
    if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject as RenderSliver?;
    } else {
      renderObject.center = null;
    }
  }

  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element?> oldSlot,
      IndexedSlot<Element?> newSlot) {
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
    children.where((e) {
      final RenderSliver renderSliver = e.renderObject! as RenderSliver;
      return renderSliver.geometry!.visible;
    }).forEach(visitor);
  }
}
