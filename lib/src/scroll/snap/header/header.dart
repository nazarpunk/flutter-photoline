import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/scroll/snap/header/holder.dart';

class ScrollSnapHeader extends MultiChildRenderObjectWidget {
  ScrollSnapHeader({
    super.key,
    required this.header,
    this.content = const SizedBox(height: double.infinity),
    required this.holder,
  }) : super(children: [content, header]);

  final Widget header;
  final Widget content;
  final ScrollSnapHeaderHolder holder;

  @override
  ScrollSnapScrollHeaderRenderBox createRenderObject(BuildContext context) =>
      ScrollSnapScrollHeaderRenderBox(holder: holder);

  @override
  void updateRenderObject(
      BuildContext context, ScrollSnapScrollHeaderRenderBox renderObject) {}
}

class ScrollSnapScrollHeaderRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  ScrollSnapScrollHeaderRenderBox({
    required this.holder,
  });

  @override
  void attach(PipelineOwner owner) {
    holder.extent.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    holder.extent.removeListener(markNeedsLayout);
    super.detach();
  }

  ScrollSnapHeaderHolder holder;

  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  @override
  void performLayout() {
    final c = constraints.loosen();

    _headerBox.layout(c.copyWith(maxHeight: holder.extent.value),
        parentUsesSize: true);
    _contentBox.layout(c, parentUsesSize: true);

    final width = c.constrainWidth(
      math.max(c.minWidth, _contentBox.size.width),
    );
    final height = c.constrainHeight(
      math.max(c.minHeight, _contentBox.size.height),
    );
    size = Size(width, height);

    (_contentBox.parentData! as MultiChildLayoutParentData).offset =
        Offset.zero;
    (_headerBox.parentData! as MultiChildLayoutParentData).offset = Offset.zero;
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
      _contentBox.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _contentBox.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _contentBox.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _contentBox.getMaxIntrinsicHeight(width);

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
