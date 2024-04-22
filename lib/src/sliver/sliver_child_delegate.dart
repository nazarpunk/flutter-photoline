import 'package:flutter/material.dart';

import 'package:photoline/src/controller.dart';

export 'package:flutter/rendering.dart'
    show
        SliverGridDelegate,
        SliverGridDelegateWithFixedCrossAxisCount,
        SliverGridDelegateWithMaxCrossAxisExtent;

typedef ChildIndexGetter = int? Function(Key key);

class PhotolineSliverChildBuilderDelegate extends SliverChildDelegate {
  const PhotolineSliverChildBuilderDelegate(
    this.builder, {
    required this.controller,
    this.findChildIndexCallback,
  });

  final PhotolineController controller;
  final NullableIndexedWidgetBuilder builder;

  final ChildIndexGetter? findChildIndexCallback;

  @override
  int? findIndexByKey(Key key) {
    if (findChildIndexCallback == null) return null;
    return findChildIndexCallback!(key);
  }

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || (index >= estimatedChildCount!)) return null;

    final Widget? child = builder(context, index);
    if (child == null) return null;
    //child = RepaintBoundary(child: child);
    return child;
  }

  @override
  int? get estimatedChildCount => controller.count;

  @override
  bool shouldRebuild(
          covariant PhotolineSliverChildBuilderDelegate oldDelegate) =>
      true;
}
