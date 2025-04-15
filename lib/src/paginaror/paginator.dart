import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/paginaror/item.dart';

class PhotolinePager extends StatefulWidget {
  const PhotolinePager({
    super.key,
    required this.photoline,
  });

  static const double starHeight = 40;
  final PhotolineState photoline;

  @override
  State<PhotolinePager> createState() => PhotolinePagerState();
}

class PhotolinePagerState extends State<PhotolinePager> {
  final List<Widget> children = [];

  PhotolineController get _controller => widget.photoline.controller;

  @override
  void initState() {
    for (var i = 0; i < 100; i++) {
      children.add(PhotolinePaginatorItem(
        index: i,
        photoline: widget.photoline,
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final h = _controller.getPagerSize?.call() ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: double.infinity,
        color: _controller.getPagerColor(),
        height: h,
        child: PhotolineScrollExtentView(
          axisDirection: AxisDirection.right,
          itemExtent: constraints.maxWidth / (constraints.maxWidth ~/ h),
          children: children,
        ),
      ),
    );
  }
}
