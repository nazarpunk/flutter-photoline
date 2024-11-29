import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SliverVariedExtentList extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver that places box children with the same main axis extent
  /// in a linear array.
  const SliverVariedExtentList({
    super.key,
    required super.delegate,
    required this.itemExtentBuilder,
  });

  /// A sliver that places multiple box children in a linear array along the main
  /// axis.
  ///
  /// [SliverVariedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentBuilder] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor is appropriate for sliver lists with a large (or
  /// infinite) number of children whose extent is already determined.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [SliverGrid]
  /// to estimate the maximum scroll extent.
  SliverVariedExtentList.builder({
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
        ));

  /// A sliver that places multiple box children in a linear array along the main
  /// axis.
  ///
  /// [SliverVariedExtentList] places its children in a linear array along the main
  /// axis starting at offset zero and without gaps. Each child is forced to have
  /// the returned extent of [itemExtentBuilder] in the main axis and the
  /// [SliverConstraints.crossAxisExtent] in the cross axis.
  ///
  /// This constructor uses a list of [Widget]s to build the sliver.
  SliverVariedExtentList.list({
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

  /// The children extent builder.
  ///
  /// Should return null if asked to build an item extent with a greater index than
  /// exists.
  final ItemExtentBuilder itemExtentBuilder;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return RenderSliverVariedExtentList(
        childManager: element, itemExtentBuilder: itemExtentBuilder);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverVariedExtentList renderObject) {
    renderObject.itemExtentBuilder = itemExtentBuilder;
  }
}
