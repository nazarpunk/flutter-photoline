import 'package:flutter/cupertino.dart';

@immutable
class ScrollSnapBox {
  const ScrollSnapBox({
    required this.index,
    required this.width,
    required this.height,
    required this.scrollOffset,
    required this.viewportScrollOffset,
  });

  final int index;

  final double width;
  final double height;

  final double scrollOffset;
  final double viewportScrollOffset;

  @override
  String toString() {
    return '${width}x$height|$scrollOffset';
  }
}
