import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/photoline.dart';

@deprecated
class PhotolineConstrainted extends MultiChildRenderObjectWidget {
  @deprecated
  PhotolineConstrainted({
    super.key,
    required this.header,
    required this.footer,
    required this.controller,
    required this.constraints,
  }) : super(children: [header, footer]);

  final Widget header;
  final Widget footer;

  final PhotolineController controller;
  final BoxConstraints constraints;

  @override
  PhotolineConstraintedRenderBox createRenderObject(BuildContext context) =>
      PhotolineConstraintedRenderBox(
        controller: controller,
        boxConstraints: constraints,
      );

  @override
  void updateRenderObject(
      BuildContext context, PhotolineConstraintedRenderBox renderObject) {
    renderObject
      ..controller = controller
      ..boxConstraints = constraints;
  }

  static double lerpConstraintsNew(double width, double height, double t,
          [double footer = 64]) =>
      ui.lerpDouble(
        width * .7 + footer,
        height,
        t,
      )!;

  @deprecated
  static double lerpConstraints(BoxConstraints constraints, double t,
          [double footer = 64]) =>
      ui.lerpDouble(
        constraints.maxWidth * .7 + footer,
        constraints.maxHeight,
        t,
      )!;
}

class PhotolineConstraintedRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  PhotolineConstraintedRenderBox({
    required PhotolineController controller,
    required BoxConstraints boxConstraints,
  })  : _controller = controller,
        _boxConstraints = boxConstraints;

  // -- controller
  PhotolineController _controller;

  PhotolineController get controller => _controller;

  set controller(PhotolineController value) {
    if (_controller == value) return;
    _controller = value;
    markNeedsLayout();
  }

  // -- constraints
  BoxConstraints _boxConstraints;

  BoxConstraints get boxConstraints => _boxConstraints;

  set boxConstraints(BoxConstraints value) {
    if (_boxConstraints == value) return;
    _boxConstraints = value;
    markNeedsLayout();
  }

  // ---

  @override
  void attach(PipelineOwner owner) {
    controller.fullScreenExpander.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    controller.fullScreenExpander.removeListener(markNeedsLayout);
    super.detach();
  }

  RenderBox get _headerBox => firstChild!;

  RenderBox get _footerBox => lastChild!;

  @override
  void performLayout() {
    final c = constraints.loosen();

    const double fh = 64;

    final double h = PhotolineConstrainted.lerpConstraints(
        _boxConstraints, _controller.fullScreenExpander.value);

    final hh = h - fh;
    _headerBox.layout(c.copyWith(maxHeight: hh), parentUsesSize: true);
    _footerBox.layout(c.copyWith(maxHeight: fh), parentUsesSize: true);

    size = Size(constraints.minWidth, h);

    (_headerBox.parentData! as MultiChildLayoutParentData).offset = Offset.zero;
    (_footerBox.parentData! as MultiChildLayoutParentData).offset =
        Offset(0, hh);
  }

  @override
  void setupParentData(RenderObject child) {
    super.setupParentData(child);
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _headerBox.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _headerBox.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _headerBox.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _headerBox.getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result as BoxHitTestResult, position: position);

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
