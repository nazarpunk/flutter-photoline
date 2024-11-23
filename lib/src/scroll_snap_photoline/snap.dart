import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/scroll_snap_photoline/controller.dart';
import 'package:photoline/src/scroll_snap_photoline/metrics.dart';
import 'package:photoline/src/scroll_snap_photoline/physics.dart';

export 'controller.dart';
export 'metrics.dart';

class ScrollSnapPhotoline extends StatefulWidget {
  ScrollSnapPhotoline({
    super.key,
    this.scrollDirection = Axis.horizontal,
    this.controller,
    this.physics,
    this.onPageChanged,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required this.slivers,
  });

  final bool allowImplicitScrolling;

  final String? restorationId;

  final Axis scrollDirection;

  final ScrollSnapPhotolineController? controller;

  final ScrollPhysics? physics;

  final ValueChanged<int>? onPageChanged;

  final DragStartBehavior dragStartBehavior;

  final Clip clipBehavior;

  final HitTestBehavior hitTestBehavior;

  final List<Widget> slivers;

  @override
  State<ScrollSnapPhotoline> createState() => _ScrollSnapPhotolineState();
}

class _ScrollSnapPhotolineState extends State<ScrollSnapPhotoline> {
  int _lastReportedPage = 0;

  late ScrollSnapPhotolineController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
    _lastReportedPage = _controller.initialPage;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initController() {
    _controller = widget.controller ?? ScrollSnapPhotolineController();
  }

  @override
  void didUpdateWidget(ScrollSnapPhotoline oldWidget) {
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _initController();
    }
    super.didUpdateWidget(oldWidget);
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection =
            textDirectionToAxisDirection(textDirection);
        return axisDirection;
      case Axis.vertical:
        return AxisDirection.down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = _ForceImplicitScrollPhysics(
      allowImplicitScrolling: widget.allowImplicitScrolling,
    ).applyTo(
      _kPagePhysics.applyTo(widget.physics),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            widget.onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final PageMetricsPhotoline metrics =
              notification.metrics as PageMetricsPhotoline;
          final int currentPage = metrics.page!.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget.onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: _controller,
        physics: physics,
        restorationId: widget.restorationId,
        hitTestBehavior: widget.hitTestBehavior,
        scrollBehavior:
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (context, position) {
          return Viewport(
            cacheExtent: widget.allowImplicitScrolling ? 1.0 : 0.0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: axisDirection,
            offset: position,
            clipBehavior: widget.clipBehavior,
            slivers: widget.slivers,
          );
        },
      ),
    );
  }
}

const PageScrollPhysicsPhotoline _kPagePhysics = PageScrollPhysicsPhotoline();

class _ForceImplicitScrollPhysics extends ScrollPhysics {
  const _ForceImplicitScrollPhysics({
    required this.allowImplicitScrolling,
    super.parent,
  });

  @override
  _ForceImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForceImplicitScrollPhysics(
      allowImplicitScrolling: allowImplicitScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  final bool allowImplicitScrolling;
}
