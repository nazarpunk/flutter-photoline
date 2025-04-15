import 'package:flutter/cupertino.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/scroll/snap/controller.dart';
import 'package:photoline/src/scroll/snap/snap/sliver_list_render.dart';

class SliverSnapList extends SliverList {
  const SliverSnapList({
    super.key,
    required this.controller,
    required super.delegate,
  });

  final ScrollSnapController controller;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverSnapList createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverSnapList(
      childManager: element,
      controller: controller,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
  }
}
