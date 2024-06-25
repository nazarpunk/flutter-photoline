import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/viewport/render.dart';

export 'package:flutter/rendering.dart' show AxisDirection, GrowthDirection;

class PhotolineViewport extends MultiChildRenderObjectWidget {
  const PhotolineViewport({
    super.key,
    required this.offset,
    List<Widget> slivers = const <Widget>[],
  }) : super(children: slivers);

  final ViewportOffset offset;

  @override
  PhotolineRenderViewport createRenderObject(BuildContext context) {
    return PhotolineRenderViewport(
      offset: offset,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, PhotolineRenderViewport renderObject) {
    renderObject.offset = offset;
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
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.update(newWidget);
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element?> oldSlot,
      IndexedSlot<Element?> newSlot) {
    super.moveRenderObjectChild(child, oldSlot, newSlot);
    assert(_doingMountOrUpdate);
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where((e) {
      final RenderSliver renderSliver = e.renderObject! as RenderSliver;
      return renderSliver.geometry!.visible;
    }).forEach(visitor);
  }
}
