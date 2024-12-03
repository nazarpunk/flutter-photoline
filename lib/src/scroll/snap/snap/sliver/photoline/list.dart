import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'render.dart';

class SliverPhotolineList extends SliverMultiBoxAdaptorWidget {
  const SliverPhotolineList({
    super.key,
    required super.delegate,
    required this.itemExtentBuilder,
  });

  final ItemExtentBuilder itemExtentBuilder;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return _Render(
      childManager: element,
      itemExtentBuilder: itemExtentBuilder,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverVariedExtentList renderObject) {
    renderObject.itemExtentBuilder = itemExtentBuilder;
  }
}
