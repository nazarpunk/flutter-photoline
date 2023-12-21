import 'package:flutter/material.dart';

import 'package:photoline/src/paginaror/scroll/physics.dart';

class ScrollExtentView extends StatefulWidget {
  const ScrollExtentView({
    super.key,
    this.controller,
    required this.children,
    required this.itemExtent,
    this.axisDirection = AxisDirection.down,
    this.sliverPadding = EdgeInsets.zero,
  });

  final ScrollController? controller;
  final List<Widget> children;
  final double itemExtent;
  final EdgeInsets sliverPadding;

  final AxisDirection axisDirection;

  @override
  State<ScrollExtentView> createState() => ScrollExtentViewState();
}

class ScrollExtentViewState extends State<ScrollExtentView> {
  @override
  Widget build(BuildContext context) => Scrollable(
        controller: widget.controller,
        axisDirection: widget.axisDirection,
        physics: const ScrollExtentPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        viewportBuilder: (context, offset) => Viewport(
          axisDirection: widget.axisDirection,
          offset: offset,
          slivers: [
            SliverPadding(
              padding: widget.sliverPadding,
              sliver: SliverFixedExtentList(
                delegate: SliverChildListDelegate(widget.children),
                itemExtent: widget.itemExtent,
              ),
            )
          ],
        ),
      );
}
