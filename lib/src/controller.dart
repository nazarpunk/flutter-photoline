import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/scroll/photoline/position.dart';
import 'package:photoline/src/tile/data.dart';
import 'package:photoline/src/tile/tile.dart';
import 'package:photoline/src/tile/uri.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/drag.dart';
import 'package:photoline/src/utils/mod.dart';
import 'package:photoline/src/utils/size.dart';

int _getViewCount(double? width) => 3;

int _getPagerIndexOffset() => 0;

Color _getPagerColor() => Colors.white;

double _wrapHeight(double w, double h, double t) {
  const double footer = 64;
  return w * .7 + footer;
}

/// Photoline controller
/// [ClipRect]
class PhotolineController extends ScrollController {
  PhotolineController({
    this.openRatio = .8,
    required this.getUri,
    this.getImage,
    required this.getKey,
    required this.getWidget,
    this.getBackside,
    required this.getPhotoCount,
    this.getViewCount = _getViewCount,
    this.onAdd,
    this.onRemove,
    this.onReorder,
    this.getPagerSize,
    this.getPagerItem,
    this.getPagerIndexOffset = _getPagerIndexOffset,
    this.getPagerColor = _getPagerColor,
    this.getPersistentWidgets,
    this.getTransferState,
    this.onTransfer,
    this.isTileOpenGray = false,
    this.onDebugAdd,
    this.useOpenSimulation = true,
    this.useOpenSideResize = true,
    this.useOpenSideResizeScale = true,
    required this.rebuilder,
    this.wrapHeight = _wrapHeight,
  });

  PhotolineHolderDragController? dragController;

  final PhotolineUri Function(int index) getUri;
  final ui.Image? Function(int)? getImage;

  final Widget Function(int) getWidget;
  final Widget Function(int index, bool show)? getBackside;
  final Key Function(int) getKey;
  final ValueGetter<int> getPhotoCount;
  final int Function(double? width) getViewCount;
  final void Function(int index, Object data)? onAdd;
  final void Function(int index)? onRemove;
  final List<Widget> Function(PhotolineTileData data)? getPersistentWidgets;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final double Function()? getPagerSize;
  final List<Widget> Function(int index, Color color)? getPagerItem;
  final int Function() getPagerIndexOffset;
  final Color Function() getPagerColor;
  final bool isTileOpenGray;
  final State? Function()? getTransferState;
  final void Function(State from, int fi, State target, int ti)? onTransfer;
  final ValueSetter<int>? onDebugAdd;

  final bool useOpenSimulation;
  final bool useOpenSideResize;
  final bool useOpenSideResizeScale;

  final void Function() rebuilder;

  final double openRatio;

  double get closeRatio => 1 / getViewCount(photolineWidth);

  double? photolineWidth;

  late final fullScreenExpander = ValueNotifier<double>(0)..addListener(rebuilder);

  final action = ValueNotifier<PhotolineAction>(PhotolineAction.close);
  final pageActivePaginator = ValueNotifier<int>(-1);
  final pageActiveOpen = ValueNotifier<int>(-1);
  final pageActiveOpenComplete = ValueNotifier<int>(-1);
  final pageTargetOpen = ValueNotifier<int>(-1);

  int pageOpenInitial = -1;

  final aspectRatio = ValueNotifier<double>(0);

  final double Function(double, double, double) wrapHeight;

  @override
  void dispose() {
    fullScreenExpander.dispose();
    action.dispose();
    pageActivePaginator.dispose();
    pageActiveOpen.dispose();
    pageActiveOpenComplete.dispose();
    pageTargetOpen.dispose();
    aspectRatio.dispose();

    super.dispose();
  }

  double? get page => position.page;

  @override
  PhotolineScrollPosition get position => super.position as PhotolineScrollPosition;

  PhotolineSize get size => PhotolineSize(this);

  int get count => getPhotoCount();

  int get countClose => getViewCount(photolineWidth);

  PhotolineState? photoline;

  final List<PhotolineMod?> mod = [];

  void onAnimationAdd() {
    if (photoline == null || mod.isEmpty) return;
    final double dx = photoline!.animationAdd.velocity * .7;

    for (var i = 0; i < mod.length; i++) {
      if (mod[i] == null) continue;
      mod[i]!.dx = dx;
      if (mod[i]!.dt > 0) {
        if (mod[i]!.t == 1) mod[i] = null;
      } else {
        if (mod[i]!.t == 0) {
          mod.removeAt(i);
          onRemove?.call(i);
        }
      }
    }

    while (mod.isNotEmpty) {
      if (mod.last != null) break;
      mod.removeLast();
    }

    // rebuild
    photoline?.rebuild();
  }

  void removeItem(int index) {
    if (action.value != PhotolineAction.close) return;
    while (index >= mod.length) {
      mod.add(null);
    }
    if (mod[index] == null) {
      mod[index] = PhotolineMod(1, -1);
    } else {
      if (mod[index]!.dt < 0) return;
      mod[index]!.dt = -1;
    }
  }

  bool addItemPhotoline(int index, Object data) {
    if (action.value != PhotolineAction.close) return false;
    onAdd?.call(index, data);
    while (index >= mod.length) {
      mod.add(null);
    }
    mod.insert(index, PhotolineMod(0, 1));
    photoline?.rebuild();
    return true;
  }

  void addItemUpload(int index, Object data) {
    photoline?.toUpload(index, data);
  }

  bool get canStartAdd {
    if (photoline == null) return false;
    if (!nearZero(position.pixels, precisionErrorTolerance)) return false;
    return true;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => PhotolineScrollPosition(
    controller: this,
    physics: physics,
    context: context,
    oldPosition: oldPosition,
  );

  /// === [Drag]
  bool get canDrag => onRemove != null && onReorder != null;
  int pageDragInitial = -1;
  int pageDragTile = 0;
  final List<PhotolineDrag> positionDrag = [];
  Offset dragOffset = Offset.zero;
  late RenderBox renderBox;
  late Offset renderOffset;
  bool isDragStart = false;
  bool isDragMain = false;

  void onPointerDown(PhotolineTileState tile, PointerDownEvent event) => dragController?.onPointerDown(this, tile, event);

  void onChangeCurrent(bool isCurrent) {
    final size = this.size;
    if (!isCurrent && count - 1 >= countClose) {
      for (int i = positionDrag.length - 1; i >= 0; i--) {
        final pi = positionDrag[i];
        if (isDragMain && pi.index == pageDragInitial) continue;
        if (pi.page <= size.viewCount - 1) {
          int po = size.viewCount;
          for (int k = positionDrag.length - 1; k >= 0; k--) {
            final pk = positionDrag[k];
            if (isDragMain && pk.index == pageDragInitial) continue;
            pk.page = --po;
          }
        }
        break;
      }
    }
  }

  void onDragStart(bool main) {
    if (isDragStart) return;
    isDragMain = main;
    if (!isDragMain) pageDragInitial = -1;

    isDragStart = true;
    photoline?.holder?.active.value = true;

    final size = this.size;

    final List<double> ws = [];
    final List<double> os = [];
    final count = this.count;
    mod.clear();

    for (var i = 0; i < count; i++) {
      final double w = size.close;
      final double o = i == 0 ? -size.pixels : os[i - 1] + ws[i - 1];
      os.add(o);
      ws.add(w);
      final p = PhotolineDrag()..page = (o / size.close).round();
      double dxo = 0;
      if (main && i > pageDragInitial) {
        p.page--;
        dxo = size.close;
      }
      positionDrag.add(
        p
          ..index = i
          ..offset = p.page * size.close + dxo,
      );
    }

    action.value = PhotolineAction.drag;
  }

  int pageDragTransferTarget = 0;

  int direction = 0;

  void onAnimationDrag({
    required double dx,
    required bool isCurrent,
    required double tileOffset,
  }) {
    final size = this.size;
    pageDragTile = (tileOffset / size.close).round();

    final List<int> l = [];
    final List<int> r = [];

    PhotolineDrag get(int i) {
      final pi = positionDrag[i];
      pi.pos = pi.page;
      if (isCurrent && pi.pos >= pageDragTile) pi.pos += 1;
      return pi;
    }

    for (var i = 0; i < positionDrag.length; i++) {
      // head
      final pi = get(i);
      if (isDragMain) {
        if (pi.index == pageDragInitial) continue;
      } else {
        if (pi.page == pageDragTile) pageDragTransferTarget = i;
      }

      // calc
      final double end = pi.pos * size.close;
      if (pi.offset == end) continue;
      (pi.offset > end ? l : r).add(i);
    }

    double moveDx(PhotolineDrag cur) {
      final e = cur.pos * size.close;
      final diff = (e - cur.offset).abs();

      final t = math.min(diff, size.close) / size.close;
      return dx * (Curves.easeOut.transform(t.clamp(0, 1)) + 1) * 80;
    }

    //print('⏰');

    /// left
    for (int i = l.length - 1; i >= 0; i--) {
      final cur = get(l[i]);
      cur.offset = math.max(cur.offset - moveDx(cur), cur.pos * size.close);
      /*
      if (i == l.length - 1) {

      }
      if (i > 0) {
        final left = get(l[i - 1]);
        final lo = cur.offset - size.close;
        final over = lo - left.offset;
        if (over < precisionErrorTolerance) left.offset = lo;
      }
       */
    }

    /// right
    for (var i = 0; i < r.length; i++) {
      final cur = get(r[i]);
      cur.offset = math.min(cur.offset + moveDx(cur), cur.pos * size.close);

      /*
      if (i == 0) {

      }
      if (i < r.length - 1) {
        final right = get(r[i + 1]);
        final ro = cur.offset + size.close;
        final over = ro - right.offset;
        if (over > -precisionErrorTolerance) right.offset = ro;
      }

       */
    }

    if (l.isEmpty && r.isEmpty && isCurrent) {
      if (direction > 0) {
        for (int i = positionDrag.length - 1; i >= 0; i--) {
          final pi = positionDrag[i];
          if ((isDragMain && pi.index == pageDragInitial) || pi.page < size.viewCount - 1) {
            continue;
          }

          for (int k = positionDrag.length - 1; k >= 0; k--) {
            positionDrag[k].page -= 1;
          }
          break;
        }
      }

      if (direction < 0) {
        for (var i = 0; i < positionDrag.length; i++) {
          final pi = positionDrag[i];
          if ((isDragMain && pi.index == pageDragInitial) || pi.page >= 0) {
            continue;
          }
          for (var k = 0; k < positionDrag.length; k++) {
            positionDrag[k].page += 1;
          }
          break;
        }
      }
    }

    final count = this.count;
    if (isDragMain) {
      if (pageDragTile >= count) pageDragTile = count - 1;
    } else {
      if (pageDragTile >= count) pageDragTransferTarget = count;
      if (positionDrag.isNotEmpty) {
        if (pageDragTile > positionDrag.last.page) pageDragTransferTarget++;
      }
    }
  }

  void onDragEndRemove() {
    if (positionDrag.length <= pageDragInitial) {
      positionDrag.removeAt(pageDragInitial);
    }
    onRemove?.call(pageDragInitial);
  }

  void onDragEndReorder() {
    if (pageDragInitial >= 0 && pageDragInitial < positionDrag.length) {
      for (var i = 0; i < positionDrag.length; i++) {
        final pi = positionDrag[i];
        if (pi.index == pageDragInitial) continue;
        int page = pi.page;
        if (pi.index > pageDragInitial) page += 1;
        if (pi.index == pageDragInitial || pageDragTile != page) continue;
        final item = positionDrag.removeAt(pageDragInitial);
        positionDrag.insert(pi.index, item);
        onReorder?.call(pageDragInitial, pi.index);
        pageDragInitial = pi.index;
        break;
      }
    }

    int d = pageDragTile;
    for (int i = pageDragInitial; i >= 0; i--) {
      positionDrag[i].page = d--;
    }
    d = pageDragTile;
    for (int i = pageDragInitial + 1; i < positionDrag.length; i++) {
      positionDrag[i].page = ++d;
    }
  }

  void onDragEndEnd() {
    action.value = PhotolineAction.close;
    for (var i = 0; i < positionDrag.length; i++) {
      final pi = positionDrag[i];
      if (pi.page == 0) {
        position.jumpToPage(i);
        break;
      }
    }
    positionDrag.clear();
    pageDragInitial = -1;
    pageDragTile = 0;
    isDragMain = false;
    isDragStart = false;
    photoline?.holder?.active.value = false;
  }

  Offset get closeOffsetEnd {
    int pdt = pageDragTile;
    final count = this.count;
    if (pdt > count) pdt = count;
    return Offset(renderOffset.dx + pdt * size.close, renderOffset.dy);
  }

  int correctCloseTargetIndex(int all, int visible, int current, int target) {
    visible--;
    final rlimit = all - 1 - current;
    final rtarget = visible - target;
    if (rtarget > rlimit) target += rtarget - rlimit;
    if (target > current) target += current - target;
    return target;
  }
}
