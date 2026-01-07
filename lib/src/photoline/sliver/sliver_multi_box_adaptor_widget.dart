import 'package:flutter/material.dart';
import 'package:photoline/src/photoline/controller.dart';
import 'package:photoline/src/photoline/photoline.dart';
import 'package:photoline/src/photoline/sliver/render_sliver_multi_box_adaptor.dart';

class PhotolineSliverMultiBoxAdaptorWidget extends SliverMultiBoxAdaptorWidget {
  PhotolineSliverMultiBoxAdaptorWidget({
    super.key,
    required this.controller,
    required this.photoline,
    required this.builder,
  }) : super(
         delegate: _PhotolineDelegate(
           controller: controller,
           builder: builder,
         ),
       );

  final PhotolineController controller;
  final PhotolineState photoline;
  final Widget? Function(BuildContext context, int index) builder;

  @override
  PhotolineRenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) => PhotolineRenderSliverMultiBoxAdaptor(
    childManager: context as SliverMultiBoxAdaptorElement,
    controller: controller,
    photoline: photoline,
  );

  @override
  void updateRenderObject(BuildContext context, PhotolineRenderSliverMultiBoxAdaptor renderObject) {
    renderObject
      ..controller = controller
      ..photoline = photoline;
  }
}

class _PhotolineDelegate extends SliverChildDelegate {
  const _PhotolineDelegate({
    required this.controller,
    required this.builder,
  });

  final PhotolineController controller;
  final Widget? Function(BuildContext context, int index) builder;

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || (index >= estimatedChildCount!)) return null;
    if (index == 0) return const SizedBox();

    final Widget? child = builder(context, index - 1);
    if (child == null) return null;
    return RepaintBoundary(child: child);
  }

  @override
  int? get estimatedChildCount => controller.count + 1;

  @override
  bool shouldRebuild(covariant _PhotolineDelegate oldDelegate) => true;
}
