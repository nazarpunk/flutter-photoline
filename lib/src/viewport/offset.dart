import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PhotolineViewportRevealedOffset {
  const PhotolineViewportRevealedOffset({
    required this.offset,
    required this.rect,
  });

  final double offset;

  final Rect rect;

  static PhotolineViewportRevealedOffset? clampOffset({
    required PhotolineViewportRevealedOffset leadingEdgeOffset,
    required PhotolineViewportRevealedOffset trailingEdgeOffset,
    required double currentOffset,
  }) {
    final bool inverted = leadingEdgeOffset.offset < trailingEdgeOffset.offset;
    final PhotolineViewportRevealedOffset smaller;
    final PhotolineViewportRevealedOffset larger;
    (smaller, larger) = inverted
        ? (leadingEdgeOffset, trailingEdgeOffset)
        : (trailingEdgeOffset, leadingEdgeOffset);
    if (currentOffset > larger.offset) {
      return larger;
    } else if (currentOffset < smaller.offset) {
      return smaller;
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RevealedOffset')}(offset: $offset, rect: $rect)';
  }
}
