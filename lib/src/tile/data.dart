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
}
