import 'package:flutter/material.dart';
import 'package:photoline_example/nested_scroll/header/holder.dart';

class ScrollSnapSliverHeaderDelegate {
  ScrollSnapSliverHeaderDelegate({
    required this.title,
    required this.holder,
  });

  final Widget? title;
  final SliverHeaderHolder holder;

  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final Widget? effectiveTitle = title;

    return ColoredBox(
      color: Colors.redAccent.withOpacity(.3),
      child: Placeholder(
        child: Center(child: effectiveTitle),
      ),
    );
  }

  bool shouldRebuild(covariant ScrollSnapSliverHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}
