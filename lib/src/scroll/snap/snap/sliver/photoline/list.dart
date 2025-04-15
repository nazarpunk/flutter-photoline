import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'render.dart';

class SliverPhotolineList extends SliverMultiBoxAdaptorWidget {
  SliverPhotolineList(
    this.builder, {
    super.key,
    required this.itemExtentBuilder,
    required int childCount,
  }) : super(
          delegate: _Delegate(builder, childCount: childCount),
        );

  final NullableIndexedWidgetBuilder builder;

  final ItemExtentBuilder itemExtentBuilder;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) {
    final element =
        context as SliverMultiBoxAdaptorElement;
    return PhotolineRenderSliverMultiBoxAdaptor(
      childManager: element,
      itemExtentBuilder: itemExtentBuilder,
    );
  }

  @override
  void updateRenderObject(BuildContext context, PhotolineRenderSliverMultiBoxAdaptor renderObject) {
    renderObject.itemExtentBuilder = itemExtentBuilder;
  }
}

class _Delegate extends SliverChildDelegate {
  const _Delegate(
    this.builder, {
    required this.childCount,
  });

  final NullableIndexedWidgetBuilder builder;

  final int childCount;

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= estimatedChildCount!) return null;
    return builder(context, index);
  }

  @override
  int? get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant _Delegate oldDelegate) => true;
}
