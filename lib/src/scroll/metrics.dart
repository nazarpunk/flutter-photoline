import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble, objectRuntimeType;
import 'package:flutter/material.dart';

/// [FixedScrollMetrics]
class PhotolineScrollMetrics with ScrollMetrics {
  PhotolineScrollMetrics({
    required double? minScrollExtent,
    required double? maxScrollExtent,
    required double? pixels,
    required double? viewportDimension,
    required this.axisDirection,
    required this.devicePixelRatio,
  })  : _minScrollExtent = minScrollExtent,
        _maxScrollExtent = maxScrollExtent,
        _pixels = pixels,
        _viewportDimension = viewportDimension;

  @override
  PhotolineScrollMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? devicePixelRatio,
  }) =>
      PhotolineScrollMetrics(
        minScrollExtent: minScrollExtent ??
            (hasContentDimensions ? this.minScrollExtent : null),
        maxScrollExtent: maxScrollExtent ??
            (hasContentDimensions ? this.maxScrollExtent : null),
        pixels: pixels ?? (hasPixels ? this.pixels : null),
        viewportDimension: viewportDimension ??
            (hasViewportDimension ? this.viewportDimension : null),
        axisDirection: axisDirection ?? this.axisDirection,
        devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      );

  double? get page =>
      math.max(0.0, clampDouble(pixels, minScrollExtent, maxScrollExtent)) /
      math.max(1.0, viewportDimension);

  // --- override
  @override
  double get minScrollExtent => _minScrollExtent!;
  final double? _minScrollExtent;

  @override
  double get maxScrollExtent => _maxScrollExtent!;
  final double? _maxScrollExtent;

  @override
  bool get hasContentDimensions =>
      _minScrollExtent != null && _maxScrollExtent != null;

  @override
  double get pixels => _pixels!;
  final double? _pixels;

  @override
  bool get hasPixels => _pixels != null;

  @override
  double get viewportDimension => _viewportDimension!;
  final double? _viewportDimension;

  @override
  bool get hasViewportDimension => _viewportDimension != null;

  @override
  final AxisDirection axisDirection;

  @override
  final double devicePixelRatio;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'FuckedScrollMetrics')}(${extentBefore.toStringAsFixed(1)}..[${extentInside.toStringAsFixed(1)}]..${extentAfter.toStringAsFixed(1)})';
  }
}
