import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:photoline/src/backside/backside.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/holder/holder.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/paginaror/paginator.dart';
import 'package:photoline/src/scroll/physics.dart';
import 'package:photoline/src/scroll/position.dart';
import 'package:photoline/src/sliver/sliver_child_delegate.dart';
import 'package:photoline/src/sliver/sliver_multi_box_adaptor_widget.dart';
import 'package:photoline/src/tile/tile.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/position.dart';

class Photoline extends StatefulWidget {
  const Photoline({
    required this.controller,
    this.photoStripeColor = const Color.fromRGBO(255, 255, 255, .1),
    super.key,
  });

  final PhotolineController controller;
  final Color photoStripeColor;

  @override
  State<Photoline> createState() => PhotolineState();
}

class PhotolineState extends State<Photoline>
    with StateRebuildMixin, TickerProviderStateMixin {
  PhotolineController get controller => widget.controller;
  late final AnimationController animationPosition;
  late final AnimationController animationOpacity;
  late final AnimationController animationAdd;

  PhotolineScrollPosition get _position => widget.controller.pos;

  int _lastReportedPage = 0;

  int _pageTargetClose = -1;
  final _physics =
      const PhotolineScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  final List<PhotolinePosition> positionOpen = [];

  late final PhotolineHolderState? holder;

  set _aspectRatio(double value) {
    final av = controller.aspectRatio.value;
    controller.aspectRatio.value = (av + value).clamp(0, 1);
  }

  void _listenerPositionClosing() {
    final t = Curves.easeInOut.transform(animationPosition.value);
    final count = controller.count;

    // center
    positionOpen[controller.pageTargetOpen.value].lerp(t);

    // left
    if (controller.pageTargetOpen.value > 0) {
      for (int i = controller.pageTargetOpen.value - 1; i >= 0; i--) {
        positionOpen[i]
          ..lerp(t)
          ..offset.current = positionOpen[i + 1].offset.current -
              positionOpen[i].width.current;
      }
    }

    // right
    if (controller.pageTargetOpen.value < count - 1) {
      for (int i = controller.pageTargetOpen.value + 1; i < count; i++) {
        positionOpen[i]
          ..lerp(t)
          ..offset.current = positionOpen[i - 1].offset.current +
              positionOpen[i - 1].width.current;
      }
    }
  }

  void _listenerPositionOpening() {
    final t = Curves.easeInOut.transform(animationPosition.value);
    final count = controller.count;

    final pto = controller.pageTargetOpen.value;

    // center
    final c = positionOpen[pto]..lerp(t);

    if (nearEqual(c.offset.current, c.offset.end, .2) &&
        nearEqual(c.width.current, c.width.end, .4)) {
      controller.pageActivePaginator.value = pto;
    }

    // left
    if (pto > 0) {
      positionOpen[pto - 1].lerp(t);
      for (int i = pto - 1; i >= 0; i--) {
        final c = positionOpen[i];
        c.offset.current = positionOpen[i + 1].offset.current - c.width.current;
        if (controller.useOpenSideResize) {
          if (c.offsetL != null && c.offset.current < c.offsetL!) {
            final diff = c.offsetL! - c.offset.current;
            c.offset.current += diff;
            c.width.current = math.max(0, c.width.current - diff);
          }
        }
      }
    }

    // right
    if (pto < count - 1) {
      positionOpen[pto + 1].lerp(t);
      for (int i = pto + 1; i < count; i++) {
        final c = positionOpen[i];
        final s = positionOpen[i - 1];
        c.offset.current = s.offset.current + s.width.current;
        final r = c.offset.current + c.width.current;
        if (controller.useOpenSideResize) {
          if (c.offsetR != null && r > c.offsetR!) {
            final diff = r - c.offsetR!;
            c.width.current = math.max(0, c.width.current - diff);
          }
        }
      }
    }
  }

  void _listenerPosition() {
    switch (controller.action.value) {
      case PhotolineAction.opening:
        _listenerPositionOpening();
      case PhotolineAction.closing:
        _listenerPositionClosing();
      case PhotolineAction.open ||
            PhotolineAction.close ||
            PhotolineAction.drag:
    }
    rebuild();
  }

  void _listenerOpacity() {
    final dx = animationOpacity.velocity.abs() * 1.8;
    switch (controller.action.value) {
      case PhotolineAction.open || PhotolineAction.opening:
        _aspectRatio = dx;
      case PhotolineAction.closing ||
            PhotolineAction.close ||
            PhotolineAction.drag:
        _aspectRatio = -dx;
    }
  }

  void _listenerPositionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      switch (controller.action.value) {
        case PhotolineAction.open:
        case PhotolineAction.close:
        case PhotolineAction.drag:
          return;
        case PhotolineAction.opening:
          controller.action.value = PhotolineAction.open;
          _position.jumpToPage(controller.pageTargetOpen.value);
          positionOpen.clear();
          controller
            ..pageActiveOpen.value = controller.pageTargetOpen.value
            ..pageActivePaginator.value = controller.pageTargetOpen.value;

        case PhotolineAction.closing:
          controller.action.value = PhotolineAction.close;
          _position.jumpToPage(_pageTargetClose);
          controller.pageTargetOpen.value = -1;
          positionOpen.clear();
      }
      rebuild();
    }
  }

  void _toPageOpenFromOpening() {
    controller.pageActivePaginator.value = -1;
    final size = controller.size;
    final count = controller.count;

    final List<int> visible = [];

    assert(positionOpen.isNotEmpty);

    for (int i = 0; i < count; i++) {
      final c = positionOpen[i];
      final double offset = c.offset.current;
      c.width.all = c.width.current;
      c.offset.all = c.offset.current;
      if (offset + c.width.current > 0 && offset < size.viewport) {
        visible.add(i);
      }
    }

    final pto = controller.pageTargetOpen.value;

    final isFirst =
        pto == 0 || (pto == 1 && controller.getPagerIndexOffset() > 0);

    final lend = pto == count - 1 ? size.side2 : size.side;
    final rend = isFirst ? size.side2 : size.side;

    if (pto > 0) {
      positionOpen[pto - 1].width.end =
          controller.useOpenSideResize ? lend : size.open;
    }
    if (pto < count - 1) {
      positionOpen[pto + 1].width.end =
          controller.useOpenSideResize ? rend : size.open;
    }

    // <->
    final c = positionOpen[pto]..end(size.open, isFirst ? 0 : lend);

    for (int i = 0; i < count; i++) {
      if ((i - pto).abs() <= 1) continue;
      final p = positionOpen[i];
      p.width.start = p.width.current;
      p.width.end = 0;
    }

    controller.action.value = PhotolineAction.opening;

    _animationStart(c);
  }

  void _toPageOpenFromClose() {
    controller.pageActivePaginator.value = -1;
    final size = controller.size;
    final count = controller.count;

    final List<int> visible = [];
    final List<double> ws = [];
    final List<double> os = [];

    final mod = controller.mod;
    for (int i = 0; i < count; i++) {
      final double w;
      if (i < mod.length && mod[i] != null) {
        w = mod[i]!.t * size.close;
      } else {
        w = size.close;
      }
      final double o = i == 0 ? -size.pixels : os[i - 1] + ws[i - 1];
      if (o + w > 0 && o < size.viewport) {
        visible.add(i);
      }
      os.add(o);
      ws.add(w);
      positionOpen.add(PhotolinePosition(w, o));
    }
    controller.mod.clear();

    final pto = controller.pageTargetOpen.value;

    final isFirst =
        pto == 0 || (pto == 1 && controller.getPagerIndexOffset() > 0);

    if (controller.useOpenSideResize) {
      final lend = pto == count - 1 ? size.side2 : size.side;
      final rend = isFirst ? size.side2 : size.side;

      if (pto > 0) positionOpen[pto - 1].width.end = lend;
      if (pto < count - 1) positionOpen[pto + 1].width.end = rend;

      // <->
      final c = positionOpen[pto]..end(size.open, isFirst ? 0 : lend);
      for (int i = 0; i < count; i++) {
        if ((i - pto).abs() <= 1) continue;
        final p = positionOpen[i];
        p.width.start = p.width.current;
        p.width.end = 0;
      }

      controller.action.value = PhotolineAction.opening;
      _animationStart(c);
    } else {
      final lend = pto == count - 1 ? size.side2 : size.side;

      if (pto > 0) positionOpen[pto - 1].width.end = size.open;
      if (pto < count - 1) positionOpen[pto + 1].width.end = size.open;

      // <->
      final c = positionOpen[pto]..end(size.open, isFirst ? 0 : lend);
      for (int i = 0; i < count; i++) {
        if ((i - pto).abs() <= 1) continue;
        final p = positionOpen[i];
        p.width.start = p.width.current;
        p.width.end = 0;
      }

      controller.action.value = PhotolineAction.opening;
      _animationStart(c);
    }
  }

  void _toPageOpenFromOpen() {
    controller.pageActivePaginator.value = -1;
    final List<int> visible = _positionOpenAddOpen();
    final count = controller.count;
    final pto = controller.pageTargetOpen.value;
    final c = positionOpen[pto];
    final size = controller.size;

    final vf = positionOpen[visible.first];
    final vl = positionOpen[visible.last];

    final isFirst =
        pto == 0 || (pto == 1 && controller.getPagerIndexOffset() > 0);

    final lend = pto == count - 1 ? size.side2 : size.side;
    final rend = isFirst ? size.side2 : size.side;

    c.width
      ..start = c.width.current
      ..end = size.open;

    c.offset
      ..start = c.offset.current
      ..end = size.side;

    if (pto > 0) {
      final l = positionOpen[pto - 1];
      l.width
        ..start = l.width.current
        ..end = controller.useOpenSideResize ? rend : size.open;
    }

    if (pto < count - 1) {
      final r = positionOpen[pto + 1];
      r.width
        ..start = r.width.current
        ..end = controller.useOpenSideResize ? lend : size.open;
    }

    if (isFirst) {
      c.offset.end = 0;
      positionOpen[pto + 1].width.end =
          controller.useOpenSideResize ? size.side2 : size.open;
    }

    if (pto == count - 1) {
      c.offset.end = size.side2;
      positionOpen[pto - 1].width.end =
          controller.useOpenSideResize ? size.side2 : size.open;
    }

    if (pto < visible.first) {
      c.width.begin = 0;
      c.offset.begin = vf.offset.current;
    }

    if (pto > visible.last) {
      c.width.begin = 0;
      c.offset.begin = vl.offset.current + vl.width.current;
    }

    controller.action.value = PhotolineAction.opening;
    _animationStart(c);
  }

  void _animationStart(PhotolinePosition cur) {
    final size = controller.size;
    final count = controller.count;

    for (int i = 0; i < count; i++) {
      final c = positionOpen[i];
      c
        ..offsetL = math.min(0, c.offset.current)
        ..offsetR = math.max(size.viewport, c.offset.current + c.width.current);
    }

    animationPosition
      ..stop()
      ..duration = const Duration(milliseconds: 600)
      ..forward(from: 0);
  }

  void _toPageClose() {
    controller.pageActiveOpen.value = -1;
    controller.pageActivePaginator.value = -1;
    controller.action.value = PhotolineAction.closing;
    _positionOpenAddOpen();

    // --- close start
    final size = controller.size;
    final count = controller.count;

    double sz = 0;
    for (int i = 0; i < count; i++) {
      final c = positionOpen[i];
      c.width.begin = c.width.current;
      c.width.end = size.close;
      c.offset.all = c.offset.current;
      final l = c.offset.current;
      final r = l + c.width.current;
      final s = math.min(r, size.viewport) - math.max(l, 0);
      if (s > sz) {
        controller.pageTargetOpen.value = i;
        sz = s;
      }
    }

    final big = positionOpen[controller.pageTargetOpen.value];

    final bigLeft = big.offset.current.clamp(0, size.viewport).toDouble();
    final bigRight = (big.offset.current + big.width.current)
        .clamp(0, size.viewport)
        .toDouble();
    int viewIndex = 0;
    sz = 0;
    final closeCount = controller.getViewCount(controller.photolineWidth);

    for (int i = 0; i < closeCount; i++) {
      final sizz =
          controller.useOpenSideResize && !controller.useOpenSideResizeScale
              ? size.open
              : size.close;

      final a = i * sizz;
      final b = (i + 1) * sizz;
      final s = math.min(bigRight, b) - math.max(bigLeft, a);
      if (s > sz) {
        viewIndex = i;
        sz = s;
      }
    }

    if (controller.pageTargetOpen.value == 1 &&
        controller.getPagerIndexOffset() > 0) viewIndex = 1;

    viewIndex = controller.correctCloseTargetIndex(
        count, closeCount, controller.pageTargetOpen.value, viewIndex);
    _pageTargetClose = controller.pageTargetOpen.value - viewIndex;

    big.offset.end = viewIndex * size.close;
    big.width.end = size.close;

    controller.action.value = PhotolineAction.closing;
    _animationStart(big);
  }

  List<int> _positionOpenAddOpen() {
    final size = controller.size;
    final count = controller.count;
    final List<int> visible = [];

    final bool toAdd = positionOpen.isEmpty;
    for (int i = 0; i < count; i++) {
      double width = size.open;
      double offset = -size.pixels + size.open * i;
      if (offset + width > 0 && offset < size.viewport) {
        if (controller.useOpenSideResize) {
          if (offset < 0) {
            width += offset;
            offset = 0;
          }
          final double r = offset + width;
          if (r > size.viewport) width += size.viewport - r;
        }
        visible.add(i);
      } else {
        width = 0;
      }
      if (toAdd) positionOpen.add(PhotolinePosition(width, offset));
    }

    return visible;
  }

  void toPage(int target) {
    if (controller.dragController?.isDrag ?? false) return;
    if (target >= controller.getPhotoCount()) return;

    final pto = controller.pageTargetOpen.value;
    controller.pageTargetOpen.value = target;

    switch (controller.action.value) {
      case PhotolineAction.close:
        controller.pageOpenInitial = target;
        return _toPageOpenFromClose();
      case PhotolineAction.open:
        return pto == target ? _toPageClose() : _toPageOpenFromOpen();
      case PhotolineAction.opening:
        return pto == target ? _toPageClose() : _toPageOpenFromOpening();
      case PhotolineAction.closing:
        return _toPageOpenFromOpening();
      case PhotolineAction.drag:
    }
  }

  void close() {
    if (controller.dragController?.isDrag ?? false) return;
    switch (controller.action.value) {
      case PhotolineAction.open:
      case PhotolineAction.opening:
        _toPageClose();
      case PhotolineAction.close:
      case PhotolineAction.closing:
      case PhotolineAction.drag:
    }
  }

  bool _notification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final a = controller.action.value;

    if (notification is ScrollEndNotification) {
      if (a == PhotolineAction.open) {
        controller.pageActivePaginator.value = controller.pos.pageOpen.round();
      }
    }

    if (notification is ScrollUpdateNotification) {
      if (a == PhotolineAction.open) {
        final pto = controller.pageTargetOpen.value.toDouble();
        final po = controller.pos.pageOpen;

        controller.pageActivePaginator.value =
            nearEqual(pto, po, .02) ? controller.pageTargetOpen.value : -1;

        final currentPage = controller.pos.pageOpen.round();
        if (currentPage != _lastReportedPage) {
          _lastReportedPage = currentPage;
          //widget.onPageChanged!(currentPage);
        }
      }
    }

    return false;
  }

  @override
  void initState() {
    controller.photoline = this;

    holder = context.findAncestorStateOfType<PhotolineHolderState>();
    holder?.photolines.add(this);
    controller.dragController = holder?.dragController;

    animationPosition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )
      ..addListener(_listenerPosition)
      ..addStatusListener(_listenerPositionStatus);

    animationOpacity = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50 * 1000))
      ..addListener(_listenerOpacity)
      ..repeat();
    animationAdd = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 20 * 1000))
      ..addListener(controller.onAnimationAdd)
      ..repeat();

    holder?.animationDrag.addListener(rebuild);

    super.initState();
  }

  @override
  void dispose() {
    holder?.photolines.remove(this);
    animationPosition.dispose();
    animationAdd.dispose();
    animationOpacity.dispose();
    holder?.animationDrag.removeListener(rebuild);
    super.dispose();
  }

  bool _updater = false;

  @override
  Widget build(BuildContext context) {
    _updater = !_updater;
    final count = controller.getPhotoCount();

    return LayoutBuilder(builder: (context, constraints) {
      controller.photolineWidth = constraints.maxWidth;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kDebugMode && controller.onDebugAdd != null)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < math.max(1, count); i++)
                    IconButton(
                      onPressed: () => controller.onDebugAdd!(i),
                      icon: Text('$i'),
                    ),
                ],
              ),
            ),
          if (kProfileMode)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < count; i++)
                    IconButton(
                      onPressed: () => controller.removeItem(i),
                      icon: Text('$i'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: PhotolineBackside(photoline: this)),
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _notification,
                      child: Scrollable(
                        axisDirection: AxisDirection.right,
                        controller: controller,
                        physics: _physics,
                        viewportBuilder: (context, position) => Viewport(
                          cacheExtent: 0.0,
                          cacheExtentStyle: CacheExtentStyle.viewport,
                          axisDirection: AxisDirection.right,
                          offset: position,
                          slivers: [
                            PhotolineSliverMultiBoxAdaptorWidget(
                              controller: controller,
                              photoline: this,
                              delegate: PhotolineSliverChildBuilderDelegate(
                                (context, i) => PhotolineTile(
                                  photoline: this,
                                  key: controller.getKey(i),
                                  index: i,
                                  uri: controller.getUri(i),
                                  controller: controller,
                                ),
                                controller: controller,
                              ),
                              updater: _updater,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (controller.getPagerItem != null) PhotolinePager(photoline: this),
        ],
      );
    });
  }
}
