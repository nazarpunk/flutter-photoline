import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

/// Whether the header starts fully expanded or collapsed.
enum ScrollSnapHeaderInitialState {
  /// Header starts at [ScrollSnapHeaderController.maxHeight].
  expanded,

  /// Header starts at [ScrollSnapHeaderController.minHeight].
  collapsed,
}

class ScrollSnapHeaderController {
  ScrollSnapHeaderController({
    this.initialState = ScrollSnapHeaderInitialState.expanded,
  });

  final ScrollSnapHeaderInitialState initialState;

  double get minHeight => 200;

  double get maxHeight => 400;

  late final height = ValueNotifier<double>(
    initialState == ScrollSnapHeaderInitialState.expanded
        ? maxHeight
        : minHeight,
  );

  set delta(double delta) {
    height.value = clampDouble(height.value - delta, minHeight, maxHeight);
  }

  /// The currently active [ScrollController] whose position receives
  /// vertical drag events started on the header area.
  ScrollController? activeScrollController;
}
