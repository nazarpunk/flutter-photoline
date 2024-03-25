import 'package:flutter/material.dart';
import 'package:photoline_example/nested_scroll/header/delegate.dart';
import 'package:photoline_example/nested_scroll/header/render_object_element.dart';
import 'package:photoline_example/nested_scroll/header/render_sliver.dart';

class ScrollSnapSliverHeader extends RenderObjectWidget {
  const ScrollSnapSliverHeader({
    super.key,
    required this.delegate,
  });

  final ScrollSnapSliverHeaderDelegate delegate;

  @override
  ScrollSnapSliverHeaderRenderSliver createRenderObject(BuildContext context) {
    return ScrollSnapSliverHeaderRenderSliver();
  }

  @override
  void updateRenderObject(
      BuildContext context, ScrollSnapSliverHeaderRenderSliver renderObject) {
    //print("☢️update|$this");
  }

  @override
  ScrollSnapSliverHeaderRenderObjectElement createElement() =>
      ScrollSnapSliverHeaderRenderObjectElement(this);
}
