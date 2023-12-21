import 'dart:core';
import 'dart:ui';

class PhotolinePosition {
  PhotolinePosition(
    double width,
    double offset,
  )   : width = PhotolinePositionValue(width),
        offset = PhotolinePositionValue(offset);

  late final PhotolinePositionValue width;
  late final PhotolinePositionValue offset;

  void lerp(double t) {
    width.lerp(t);
    offset.lerp(t);
  }

  void end(double width, double offset) {
    this.width.end = width;
    this.offset.end = offset;
  }

  double? offsetL;
  double? offsetR;

  @override
  String toString() => '$width | $offset';
}

class PhotolinePositionValue {
  PhotolinePositionValue(this.current)
      : start = current,
        end = current;

  double start;
  double current;
  double end;

  set begin(double value) {
    start = value;
    current = value;
  }

  set all(double value) {
    start = value;
    current = value;
    end = value;
  }

  void lerp(double t) {
    current = lerpDouble(start, end, t)!;
  }

  @override
  String toString() =>
      '${start.toStringAsFixed(2)}->${current.toStringAsFixed(2)}<-${end.toStringAsFixed(2)}';
}
