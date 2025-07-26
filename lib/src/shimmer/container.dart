import 'dart:async';

import 'package:flutter/material.dart';

class PhotolineShimmerContainer extends StatefulWidget {
  const PhotolineShimmerContainer({
    super.key,
    this.child,
  });

  static PhotolineShimmerContainerState? of(BuildContext context) => context.findAncestorStateOfType<PhotolineShimmerContainerState>();

  final Widget? child;

  @override
  PhotolineShimmerContainerState createState() => PhotolineShimmerContainerState();
}

class PhotolineShimmerContainerState extends State<PhotolineShimmerContainer> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController.unbounded(vsync: this);
    unawaited(
      controller.repeat(
        min: -1,
        max: 1,
        period: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isSized => (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject()! as RenderBox).size;

  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject()! as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  Listenable get shimmerChanges => controller;

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();
}
