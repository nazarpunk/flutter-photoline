import 'package:flutter/material.dart';

import '../scroll/controller.dart';

export 'package:flutter/rendering.dart' show SliverGridDelegate, SliverGridDelegateWithFixedCrossAxisCount, SliverGridDelegateWithMaxCrossAxisExtent;

class _SaltedValueKey extends ValueKey<Key> {
  const _SaltedValueKey(super.value);
}

typedef ChildIndexGetter = int? Function(Key key);

class PhotolineSliverChildBuilderDelegate extends SliverChildDelegate {
  const PhotolineSliverChildBuilderDelegate(
    this.builder, {
    required this.controller,
    this.findChildIndexCallback,
  });

  final PhotolineController controller;
  final NullableIndexedWidgetBuilder builder;

  final ChildIndexGetter? findChildIndexCallback;

  @override
  int? findIndexByKey(Key key) {
    if (findChildIndexCallback == null) return null;
    final Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return findChildIndexCallback!(childKey);
  }

  @override
  Widget? build(BuildContext context, int index) {
    if (index < 0 || (index >= estimatedChildCount!)) return null;

    Widget? child = builder(context, index);

    if (child == null) return null;
    final Key? key = child.key != null ? _SaltedValueKey(child.key!) : null;

    child = RepaintBoundary(child: child);

    return KeyedSubtree(
      key: key,
      child: child,
    );
  }

  @override
  int? get estimatedChildCount => controller.count;

  @override
  bool shouldRebuild(covariant PhotolineSliverChildBuilderDelegate oldDelegate) => true;
}
