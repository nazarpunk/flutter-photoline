import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PhotolinePointerScrollNotification extends ScrollNotification {
  PhotolinePointerScrollNotification({
    required this.event,
    required super.metrics,
    required super.context,
  });

  final PointerScrollEvent event;
}
