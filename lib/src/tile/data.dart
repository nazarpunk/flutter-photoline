import 'package:flutter/cupertino.dart';

@immutable
class PhotolineTileData {
  const PhotolineTileData({
    required this.index,
    required this.loading,
    required this.closeDw,
    required this.openDw,
    required this.dragging,
    required this.dragCurrent,
    required this.isRemove,
  });

  final int index;
  final double loading;
  final double closeDw;
  final double openDw;
  final bool dragging;
  final double dragCurrent;
  final bool isRemove;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotolineTileData &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          loading == other.loading &&
          closeDw == other.closeDw &&
          openDw == other.openDw &&
          dragging == other.dragging &&
          dragCurrent == other.dragCurrent &&
          isRemove == other.isRemove;

  @override
  int get hashCode => Object.hash(
      index, loading, closeDw, openDw, dragging, dragCurrent, isRemove);
}
