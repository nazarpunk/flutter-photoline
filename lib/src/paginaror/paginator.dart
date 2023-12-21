import 'package:flutter/material.dart';
import 'package:photoline/src/paginaror/item.dart';
import 'package:photoline/src/paginaror/scroll/view.dart';
import 'package:photoline/src/photoline.dart';

class PhotolinePager extends StatefulWidget {
  const PhotolinePager({
    super.key,
    required this.photoline,
  });

  static const double height = 60;
  static const double starHeight = 40;
  final PhotolineState photoline;

  @override
  State<PhotolinePager> createState() => PhotolinePagerState();
}

class PhotolinePagerState extends State<PhotolinePager> {
  final List<Widget> children = [];

  @override
  void initState() {
    for (int i = 0; i < 100; i++) {
      children.add(PhotolinePaginatorItem(
        index: i,
        photoline: widget.photoline,
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          width: double.infinity,
          color: Colors.white,
          height: PhotolinePager.height,
          child: ScrollExtentView(
            axisDirection: AxisDirection.right,
            itemExtent: constraints.maxWidth / (constraints.maxWidth ~/ PhotolinePager.height),
            children: children,
          ),
        ),
      );
}
