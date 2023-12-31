import 'package:flutter/cupertino.dart';

@immutable
class PhotolineTileData {
  const PhotolineTileData({
    required this.index,
    required this.loading,
    required this.closeDw,
  });

  final int index;
  final double loading;
  final double closeDw;
}
