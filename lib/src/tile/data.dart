import 'package:flutter/cupertino.dart';
import 'package:photoline/photoline.dart';

@immutable
class PhotolineTileData {
  const PhotolineTileData({
    required this.index,
    required this.uri,
    required this.closeDw,
    required this.openDw,
    required this.dragging,
    required this.isRemove,
  });

  final int index;
  final PhotolineUri uri;
  final double closeDw;
  final double openDw;
  final bool dragging;
  final bool isRemove;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotolineTileData &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          uri == other.uri &&
          closeDw == other.closeDw &&
          openDw == other.openDw &&
          dragging == other.dragging &&
          isRemove == other.isRemove;

  @override
  int get hashCode =>
      Object.hash(index, closeDw, openDw, dragging, isRemove, uri);
}
