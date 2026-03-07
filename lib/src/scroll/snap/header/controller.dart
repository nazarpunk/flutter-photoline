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

  /// Set to `true` by [ScrollSnapHeader] when [onRefresh] is provided.
  /// The scroll position uses this to block underscroll and redirect the
  /// delta into [refreshPull] instead.
  bool canRefresh = false;

  /// Current refresh pull distance in logical pixels. Driven by the scroll
  /// position when the user overscrolls past the fully-expanded header.
  final refreshPull = ValueNotifier<double>(0.0);

  /// How far the user must pull to arm the refresh. Set by [ScrollSnapHeader].
  double refreshTriggerExtent = 80.0;

  /// Whether the refresh is currently in progress (loading). While true the
  /// scroll position must not reduce [refreshPull].
  bool refreshing = false;
}
