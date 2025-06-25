import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:photoline/src/backside/backside.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/holder/holder.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/paginaror/paginator.dart';
import 'package:photoline/src/scroll/photoline/position.dart';
import 'package:photoline/src/scroll/physics.dart';
import 'package:photoline/src/scroll/snap/snap.dart';
import 'package:photoline/src/scrollable/notification/pointer.dart';
import 'package:photoline/src/scrollable/scrollable.dart';
import 'package:photoline/src/sliver/sliver_child_delegate.dart';
import 'package:photoline/src/sliver/sliver_multi_box_adaptor_widget.dart';
import 'package:photoline/src/tile/tile.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/position.dart';
import 'package:photoline/src/viewport/viewport.dart';

class Photoline extends StatefulWidget {
  const Photoline({
    required this.controller,
    required this.photoStripeColor,
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

  final _physics = const PhotolineScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  final List<PhotolinePosition> positionWidth = [];

  late final PhotolineHolderState? holder;

  set _aspectRatio(double value) {
    final av = controller.aspectRatio.value;
    controller.aspectRatio.value = (av + value).clamp(0, 1);
  }

  void _listenerPositionClosing() {
    final t = Curves.easeInOut.transform(animationPosition.value);
    final count = controller.count;

    controller.fullScreenExpander.value = math.min(
      controller.fullScreenExpander.value,
      1 - t,
    );

    // center
    positionWidth[controller.pageTargetOpen.value].lerp(t);

    // left
    if (controller.pageTargetOpen.value > 0) {
      for (int i = controller.pageTargetOpen.value - 1; i >= 0; i--) {
        positionWidth[i]
          ..lerp(t)
          ..offset.current =
              positionWidth[i + 1].offset.current -
              positionWidth[i].width.current;
      }
    }

    // right
    if (controller.pageTargetOpen.value < count - 1) {
      for (int i = controller.pageTargetOpen.value + 1; i < count; i++) {
        positionWidth[i]
          ..lerp(t)
          ..offset.current =
              positionWidth[i - 1].offset.current +
              positionWidth[i - 1].width.current;
      }
    }
  }

  void _listenerPositionUpload() {
    final t = Curves.easeInOut.transform(animationPosition.value);
    final count = controller.count;

    controller.fullScreenExpander.value = math.min(
      controller.fullScreenExpander.value,
      1 - t,
    );

    for (var i = 0; i < count; i++) {
      positionWidth[i].lerp(t);
    }
  }

  void _listenerPositionOpening() {
    final t = Curves.easeInOut.transform(animationPosition.value);
    final count = controller.count;

    final pto = controller.pageTargetOpen.value;

    controller.fullScreenExpander.value = math.max(
      controller.fullScreenExpander.value,
      t,
    );

    // center
    final c = positionWidth[pto]..lerp(t);

    if (nearEqual(c.offset.current, c.offset.end, .2) &&
        nearEqual(c.width.current, c.width.end, .4)) {
      controller.pageActivePaginator.value = pto;
    }

    // left
    if (pto > 0) {
      positionWidth[pto - 1].lerp(t);
      for (int i = pto - 1; i >= 0; i--) {
        final c = positionWidth[i];
        c.offset.current =
            positionWidth[i + 1].offset.current - c.width.current;
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
      positionWidth[pto + 1].lerp(t);
      for (int i = pto + 1; i < count; i++) {
        final c = positionWidth[i];
        final s = positionWidth[i - 1];
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
      case PhotolineAction.upload:
        _listenerPositionUpload();
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
          PhotolineAction.drag ||
          PhotolineAction.upload:
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
          positionWidth.clear();
          controller
            ..pageActiveOpen.value = controller.pageTargetOpen.value
            ..pageActiveOpenComplete.value = controller.pageTargetOpen.value
            ..pageActivePaginator.value = controller.pageTargetOpen.value;

        case PhotolineAction.closing:
          controller.action.value = PhotolineAction.close;
          _position.jumpToPage(_pageTargetClose);
          controller.pageTargetOpen.value = -1;
          positionWidth.clear();
        case PhotolineAction.upload:
          controller.action.value = PhotolineAction.close;
          _position.jumpToPage(0);
          controller.pageTargetOpen.value = -1;
          positionWidth.clear();
      }
      rebuild();
    }
  }

  void _toUploadFromClose(int index, Object data) {
    final size = controller.size;

    final List<int> visible = [];
    positionWidth.clear();

    final isZero = controller.count == 0;

    if (isZero) {
    } else {
      for (var i = 0; i < controller.count; i++) {
        final double o = -size.pixels + (size.close * i);
        if (o + size.close > 0 && o < size.viewport) {
          visible.add(i + 1);
        }
        positionWidth.add(PhotolinePosition(size.close, o));
      }
    }

    controller.action.value = PhotolineAction.upload;

    if (isZero) {
      positionWidth.insert(
        0,
        PhotolinePosition(size.close, -size.close)..end(size.close, 0),
      );
    } else {
      positionWidth.insert(0, PhotolinePosition(size.close, -size.close));
    }

    controller.onAdd?.call(index, data);

    if (isZero) {
    } else {
      if (visible.isNotEmpty) {
        for (int i = visible.first; i >= 0; i--) {
          if (i <= 2 && !visible.contains(i)) {
            visible.insert(0, i);
          }
        }
      }

      for (var i = 0; i < controller.count; i++) {
        if (!visible.contains(i)) {
          positionWidth[i].width.all = 0;
        }
      }

      for (int i = visible.length - 2; i >= 0; i--) {
        positionWidth[visible[i]].offset.start =
            positionWidth[visible[i + 1]].offset.start - size.close;
      }

      for (var i = 0; i < visible.length; i++) {
        final c = positionWidth[visible[i]];
        c.offset.end =
            i == 0 ? 0 : positionWidth[visible[i - 1]].offset.end + size.close;
      }
    }

    //final double dx = positionWidth[0].offset.start.abs();
    //final int ms = ((dx / 300) * 1000).toInt();

    animationPosition
      ..stop()
      ..duration = const Duration(milliseconds: 400)
      ..forward(from: 0);
  }

  void _toUploadFromWidth(int index, Object data) {
    final List<int> visible = [];
    controller.action.value = PhotolineAction.upload;
    final size = controller.size;

    for (var i = 0; i < controller.count; i++) {
      final p = positionWidth[i];

      final double o = p.offset.current;
      if (p.width.current > 0 &&
          o + p.width.current >= 0 &&
          o <= size.viewport) {
        visible.add(i + 1);
        p.offset.start = o;
      } else {
        p.width.all = 0;
        p.offset.all = size.viewport * 2;
      }
    }

    for (int i = visible.first; i >= 0; i--) {
      if (i <= 2 && !visible.contains(i)) {
        visible.insert(0, i);
      }
    }

    controller.action.value = PhotolineAction.upload;
    positionWidth.insert(0, PhotolinePosition(size.close, -size.close));
    controller.onAdd?.call(index, data);

    for (var i = 0; i < visible.length; i++) {
      final c = positionWidth[visible[i]];
      c.width.start = c.width.current;
      c.width.end = size.close;
    }

    for (int i = visible.length - 2; i >= 0; i--) {
      final c = positionWidth[visible[i]];
      final r = positionWidth[visible[i + 1]];
      c.offset.all = r.offset.current - c.width.current;
    }

    for (var i = 0; i < visible.length; i++) {
      final c = positionWidth[visible[i]];
      c.offset.end =
          i == 0 ? 0 : positionWidth[visible[i - 1]].offset.end + size.close;
    }

    animationPosition
      ..stop()
      ..duration = const Duration(milliseconds: 400)
      ..forward(from: 0);
  }

  void _toUploadFromOpen(int index, Object data) {
    _toPageClose();
    _toUploadFromWidth(index, data);
  }

  void toUpload(int index, Object data) {
    switch (controller.action.value) {
      case PhotolineAction.close:
        return _toUploadFromClose(index, data);
      case PhotolineAction.upload:
      case PhotolineAction.opening:
      case PhotolineAction.closing:
        return _toUploadFromWidth(index, data);
      case PhotolineAction.open:
        return _toUploadFromOpen(index, data);
      case PhotolineAction.drag:
    }
  }

  void toPage(int target) {
    if (controller.action.value == PhotolineAction.upload) return;

    if (controller.dragController?.isDrag ?? false) return;
    if (target >= controller.getPhotoCount()) return;

    final pto = controller.pageTargetOpen.value;
    controller.pageTargetOpen.value = target;
    controller.pageActivePaginator.value = target;
    controller.pageActiveOpenComplete.value = -1;

    switch (controller.action.value) {
      case PhotolineAction.close:
        controller.pageOpenInitial = target;
        return _toPageOpenFromClose();
      case PhotolineAction.open:
        return pto == target ? _toPageClose() : _toPageOpenFromOpen();
      case PhotolineAction.opening:
        return pto == target ? _toPageClose() : _toPageOpenFromOpening();
      case PhotolineAction.closing:
      case PhotolineAction.upload:
        return _toPageOpenFromOpening();
      case PhotolineAction.drag:
    }
  }

  void _toPageOpenFromOpening() {
    //controller.pageActivePaginator.value = -1;
    final size = controller.size;
    final count = controller.count;

    final List<int> visible = [];

    assert(positionWidth.isNotEmpty);

    for (var i = 0; i < count; i++) {
      final c = positionWidth[i];
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
      positionWidth[pto - 1].width.end =
          controller.useOpenSideResize ? lend : size.open;
    }
    if (pto < count - 1) {
      positionWidth[pto + 1].width.end =
          controller.useOpenSideResize ? rend : size.open;
    }

    // <->
    final c = positionWidth[pto]..end(size.open, isFirst ? 0 : lend);

    for (var i = 0; i < count; i++) {
      if ((i - pto).abs() <= 1) continue;
      final p = positionWidth[i];
      p.width.start = p.width.current;
      p.width.end = 0;
    }

    controller.action.value = PhotolineAction.opening;

    _animationStart(c);
  }

  void _toPageOpenFromClose() {
    final snap = context.findAncestorStateOfType<ScrollSnapState>();
    if (snap != null) {
      snap.controller.pos.photolineScrollToOpen(
        (context.findRenderObject()! as RenderBox)
            .globalToLocal(
              Offset.zero,
              ancestor: snap.context.findRenderObject(),
            )
            .dy,
      );
    }

    //controller.pageActivePaginator.value = -1;
    final size = controller.size;
    final count = controller.count;

    final List<int> visible = [];
    final List<double> ws = [];
    final List<double> os = [];

    final mod = controller.mod;
    for (var i = 0; i < count; i++) {
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
      positionWidth.add(PhotolinePosition(w, o));
    }
    controller.mod.clear();

    final pto = controller.pageTargetOpen.value;

    final isFirst =
        pto == 0 || (pto == 1 && controller.getPagerIndexOffset() > 0);

    final lend = pto == count - 1 ? size.side2 : size.side;
    late final PhotolinePosition c;

    if (controller.useOpenSideResize) {
      final rend = isFirst ? size.side2 : size.side;

      if (pto > 0) positionWidth[pto - 1].width.end = lend;
      if (pto < count - 1) positionWidth[pto + 1].width.end = rend;

      // <->
      c = positionWidth[pto]..end(size.open, isFirst ? 0 : lend);
      for (var i = 0; i < count; i++) {
        if ((i - pto).abs() <= 1) continue;
        final p = positionWidth[i];
        p.width.start = p.width.current;
        p.width.end = 0;
      }
    } else {
      if (pto > 0) positionWidth[pto - 1].width.end = size.open;
      if (pto < count - 1) positionWidth[pto + 1].width.end = size.open;

      // <->
      c = positionWidth[pto]..end(size.open, isFirst ? 0 : lend);
      for (var i = 0; i < count; i++) {
        if ((i - pto).abs() <= 1) continue;
        final p = positionWidth[i];
        p.width.start = p.width.current;
        p.width.end = 0;
      }
    }
    controller.action.value = PhotolineAction.opening;
    _animationStart(c);
  }

  void _toPageOpenFromOpen() {
    //controller.pageActivePaginator.value = -1;
    final List<int> visible = _positionOpenAddOpen();
    final count = controller.count;
    final pto = controller.pageTargetOpen.value;
    final c = positionWidth[pto];
    final size = controller.size;

    final vf = positionWidth[visible.first];
    final vl = positionWidth[visible.last];

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
      final l = positionWidth[pto - 1];
      l.width
        ..start = l.width.current
        ..end = controller.useOpenSideResize ? rend : size.open;
    }

    if (pto < count - 1) {
      final r = positionWidth[pto + 1];
      r.width
        ..start = r.width.current
        ..end = controller.useOpenSideResize ? lend : size.open;
    }

    if (isFirst) {
      c.offset.end = 0;
      positionWidth[pto + 1].width.end =
          controller.useOpenSideResize ? size.side2 : size.open;
    }

    if (pto == count - 1) {
      c.offset.end = size.side2;
      positionWidth[pto - 1].width.end =
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

  void _toPageClose() {
    controller.pageActiveOpenComplete.value = -1;
    controller.pageActiveOpen.value = -1;
    controller.pageActivePaginator.value = -1;
    controller.action.value = PhotolineAction.closing;
    _positionOpenAddOpen();

    // --- close start
    final size = controller.size;
    final count = controller.count;

    double sz = 0;
    for (var i = 0; i < count; i++) {
      final c = positionWidth[i];
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

    final big = positionWidth[controller.pageTargetOpen.value];

    final bigLeft = big.offset.current.clamp(0, size.viewport).toDouble();
    final bigRight =
        (big.offset.current + big.width.current)
            .clamp(0, size.viewport)
            .toDouble();
    var viewIndex = 0;
    sz = 0;
    final closeCount = controller.getViewCount(controller.photolineWidth);

    for (var i = 0; i < closeCount; i++) {
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
        controller.getPagerIndexOffset() > 0) {
      viewIndex = 1;
    }

    viewIndex = controller.correctCloseTargetIndex(
      count,
      closeCount,
      controller.pageTargetOpen.value,
      viewIndex,
    );
    _pageTargetClose = controller.pageTargetOpen.value - viewIndex;

    big.offset.end = viewIndex * size.close;
    big.width.end = size.close;

    controller.action.value = PhotolineAction.closing;
    _animationStart(big);
  }

  void _animationStart(PhotolinePosition cur) {
    final size = controller.size;
    final count = controller.count;

    for (var i = 0; i < count; i++) {
      final c = positionWidth[i];
      c
        ..offsetL = math.min(0, c.offset.current)
        ..offsetR = math.max(size.viewport, c.offset.current + c.width.current);
    }

    animationPosition
      ..stop()
      ..duration = const Duration(milliseconds: 600)
      ..forward(from: 0);
  }

  List<int> _positionOpenAddOpen() {
    final size = controller.size;
    final count = controller.count;
    final List<int> visible = [];

    final bool toAdd = positionWidth.isEmpty;
    for (var i = 0; i < count; i++) {
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

      if (toAdd) positionWidth.add(PhotolinePosition(width, offset));
    }

    return visible;
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
      case PhotolineAction.upload:
    }
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification is PhotolinePointerScrollNotification) {
      switch (controller.action.value) {
        case PhotolineAction.open:
        case PhotolineAction.close:
          if (!_position.hasPixels) return true;
          final dx = notification.event.scrollDelta.dy;
          final pp = _position.pixels;
          final max = _position.maxScrollExtent;
          final min = _position.minScrollExtent;

          if (min + max == 0) return false;
          if (dx > 0) {
            if (pp >= max) return false;
          } else {
            if (pp <= min) return false;
          }
          final double velocity = (math.max(dx.abs(), 50) * dx.sign) * 10;

          _position.goBallistic(velocity);
          return true;
        case PhotolineAction.opening:
        case PhotolineAction.closing:
        case PhotolineAction.drag:
        case PhotolineAction.upload:
          return true;
      }
      //return false;
    }

    if (notification.depth != 0) return false;
    final a = controller.action.value;

    if (notification is ScrollEndNotification) {
      if (a == PhotolineAction.open) {
        final p = controller.pos.pageOpen.round();
        controller
          ..pageActiveOpenComplete.value = p
          ..pageActivePaginator.value = p
          ..pageTargetOpen.value = p;
      }
    }

    if (notification is ScrollUpdateNotification) {
      if (a == PhotolineAction.open) {
        final pto = controller.pageTargetOpen.value.toDouble();
        final po = controller.pos.pageOpen;

        controller.pageActivePaginator.value =
            nearEqual(pto, po, .02) ? controller.pageTargetOpen.value : -1;

        controller.pageActiveOpenComplete.value =
            controller.pageActivePaginator.value;

        final currentPage = controller.pos.pageOpen.round();
        if (currentPage != _lastReportedPage) {
          _lastReportedPage = currentPage;
          //widget.onPageChanged!(currentPage);
        }
      }
    }

    return false;
  }

  late final animationRepaint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void initState() {
    controller.photoline = this;

    holder = context.findAncestorStateOfType<PhotolineHolderState>();

    holder?.photolines.add(this);
    controller.dragController = holder?.dragController;

    animationPosition =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 400),
          )
          ..addListener(_listenerPosition)
          ..addStatusListener(_listenerPositionStatus);

    animationOpacity =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 50 * 1000),
          )
          ..addListener(_listenerOpacity)
          ..repeat();
    animationAdd =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 20 * 1000),
          )
          ..addListener(controller.onAnimationAdd)
          ..repeat();

    holder?.animationDrag.addListener(rebuild);

    super.initState();
  }

  @override
  void dispose() {
    animationRepaint.dispose();
    holder?.photolines.remove(this);
    animationPosition.dispose();
    animationAdd.dispose();
    animationOpacity.dispose();
    holder?.animationDrag.removeListener(rebuild);
    super.dispose();
  }

  /// [Viewport]
  @override
  Widget build(BuildContext context) {
    //_updater = !_updater;
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.photolineWidth = constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: PhotolineBackside(photoline: this)),
                    Positioned.fill(
                      child: NotificationListener(
                        onNotification: _onNotification,
                        child: PhotolineScrollable(
                          axisDirection: AxisDirection.right,
                          controller: controller,
                          physics: _physics,
                          viewportBuilder:
                              (context, position) => PhotolineViewport(
                                offset: position,
                                slivers: [
                                  PhotolineSliverMultiBoxAdaptorWidget(
                                    controller: controller,
                                    photoline: this,
                                    delegate:
                                        PhotolineSliverChildBuilderDelegate(
                                          (context, i) => PhotolineTile(
                                            photoline: this,
                                            key: controller.getKey(i),
                                            index: i,
                                            controller: controller,
                                          ),
                                          controller: controller,
                                        ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.getPagerItem != null &&
                controller.getPagerSize != null)
              PhotolinePager(photoline: this),
          ],
        );
      },
    );
  }
}
