import 'package:flutter/material.dart';

import '../photoline.dart';
import 'scroll/view.dart';
import 'star.dart';

class PhotolinePaginator extends StatefulWidget {
  const PhotolinePaginator({
    super.key,
    required this.photoline,
  });

  static const double height = 60;
  static const double starHeight = 40;
  final PhotolineState photoline;

  @override
  State<PhotolinePaginator> createState() => PhotolinePaginatorState();
}

class PhotolinePaginatorState extends State<PhotolinePaginator> {
  final List<Widget> children = [];

  @override
  void initState() {
    for (int i = 0; i < 100; i++) {
      children.add(PhotolinePaginatorStar(index: i, photoline: widget.photoline));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          width: double.infinity,
          color: Colors.white,
          height: PhotolinePaginator.height,
          child: ScrollExtentView(
            axisDirection: AxisDirection.right,
            itemExtent: constraints.maxWidth / (constraints.maxWidth ~/ PhotolinePaginator.height),
            children: children,
          ),
        ),
      );
}
