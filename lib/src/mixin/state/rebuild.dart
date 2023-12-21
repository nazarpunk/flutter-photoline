import 'package:flutter/material.dart';

mixin StateRebuildMixin<T extends StatefulWidget> on State<T> {
  void rebuild([_]) {
    if (mounted) setState(() {});
  }
}
