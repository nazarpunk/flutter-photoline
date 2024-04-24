import 'package:flutter/material.dart';

class SliverChildBuilderDelegateWithGap extends SliverChildDelegate {
  const SliverChildBuilderDelegateWithGap(
    this.builder, {
    required this.childCount,
    this.gap = 20,
  });

  final NullableIndexedWidgetBuilder builder;

  final int childCount;
  final int gap;

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || index >= childCount) return null;
    if (index.isEven) {
      return builder(context, index ~/ 2);
    } else {
      return const SizedBox(height: 20);
    }
  }

  @override
  int? get estimatedChildCount => childCount + (childCount - 1);

  @override
  bool shouldRebuild(covariant SliverChildBuilderDelegateWithGap oldDelegate) =>
      true;
}
