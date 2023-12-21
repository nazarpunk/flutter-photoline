import 'dart:math' as math;

double photolineTileIntersection(double topA, double heightA, double topB, double heightB) {
  final double bottomA = topA + heightA;
  final double bottomB = topB + heightB;

  if (topA <= bottomB && bottomA >= topB) {
    final double intersectionTop = math.max(topA, topB);
    final double intersectionBottom = math.min(bottomA, bottomB);

    final double intersectionLength = math.max(0, intersectionBottom - intersectionTop);
    return intersectionLength;
  }
  return 0.0;
}
