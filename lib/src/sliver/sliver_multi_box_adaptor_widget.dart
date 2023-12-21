import 'package:flutter/material.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/sliver/render_sliver_multi_box_adaptor.dart';

class PhotolineSliverMultiBoxAdaptorWidget extends SliverMultiBoxAdaptorWidget {
  const PhotolineSliverMultiBoxAdaptorWidget({
    super.key,
    required super.delegate,
    required this.controller,
    required this.photoline,
    required this.updater,
  });

  final PhotolineController controller;
  final PhotolineState photoline;
  final bool updater;

  @override
  PhotolineRenderSliverMultiBoxAdaptor createRenderObject(
          BuildContext context) =>
      PhotolineRenderSliverMultiBoxAdaptor(
        childManager: context as SliverMultiBoxAdaptorElement,
        controller: controller,
        photoline: photoline,
        updater: updater,
      );

  @override
  void updateRenderObject(
      BuildContext context, PhotolineRenderSliverMultiBoxAdaptor renderObject) {
    renderObject
      ..controller = controller
      ..photoline = photoline
      ..updater = updater;
  }
}
