import 'package:flutter/cupertino.dart';
import 'package:photoline/library.dart';

@immutable
class PhotolineTileData {
  const PhotolineTileData({
    required this.index,
    this.uri,
    this.loader,
    required this.closeDw,
    required this.openDw,
    required this.dragging,
    required this.isRemove,
  });

  final int index;
  final PhotolineUri? uri;
  final PhotolineLoader? loader;
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
          loader == other.loader &&
          closeDw == other.closeDw &&
          openDw == other.openDw &&
          dragging == other.dragging &&
          isRemove == other.isRemove;

  @override
  int get hashCode =>
      Object.hash(index, closeDw, openDw, dragging, isRemove, uri, loader);
}
