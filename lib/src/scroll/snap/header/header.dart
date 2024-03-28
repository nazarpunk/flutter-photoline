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
    required this.media,
  }) : super(children: [content, header]);

  final Widget header;
  final Widget content;
  final MediaQueryData media;

  final SliverHeaderHolder holder;

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
    holder.delta.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    holder.delta.removeListener(markNeedsLayout);
    super.detach();
  }

  SliverHeaderHolder holder;

  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  @override
  void performLayout() {
    _headerBox.layout(constraints.copyWith(maxHeight: holder.extent.value),
        parentUsesSize: true);
    _contentBox.layout(constraints, parentUsesSize: true);

    final width = constraints.constrainWidth(
      math.max(constraints.minWidth, _contentBox.size.width),
    );
    final height = constraints.constrainHeight(
      math.max(constraints.minHeight, _contentBox.size.height),
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
