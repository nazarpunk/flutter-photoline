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

  SliverPhotolineList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtentBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            findChildIndexCallback: findChildIndexCallback,
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
        );

  SliverPhotolineList.list({
    super.key,
    required List<Widget> children,
    required this.itemExtentBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(
            delegate: SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        ));

  final ItemExtentBuilder itemExtentBuilder;

  @override
  _Render createRenderObject(BuildContext context) {
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
