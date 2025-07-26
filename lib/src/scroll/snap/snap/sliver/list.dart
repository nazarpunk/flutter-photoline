import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';

part 'render.dart';

class SliverSnapList extends SliverMultiBoxAdaptorWidget {
  SliverSnapList({
    required this.controller,
    required this.builder,
    super.key,
    required int childCount,
  }) : super(delegate: _Delegate(builder, childCount: childCount));

  final NullableIndexedWidgetBuilder builder;

  final ScrollSnapController controller;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) => RenderSliverSnapMultiBoxAdaptor(
    childManager: context as SliverMultiBoxAdaptorElement,
    controller: controller,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverSnapMultiBoxAdaptor renderObject,
  ) {
    renderObject.controller = controller;
  }
}

class _Delegate extends SliverChildDelegate {
  const _Delegate(this.builder, {required this.childCount});

  final NullableIndexedWidgetBuilder builder;
  final int childCount;

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= childCount) return null;
    return builder(context, index);
  }

  @override
  int? get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant _Delegate oldDelegate) => true;
}
