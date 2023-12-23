import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/photoline.dart';
import 'package:photoline/src/scroll/position.dart';
import 'package:photoline/src/tile/tile.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/drag.dart';
import 'package:photoline/src/utils/mod.dart';
import 'package:photoline/src/utils/size.dart';

int _getCloseCount() => 3;

int _getPagerIndexOffset() => 0;

/// Photoline controller
class PhotolineController extends ScrollController {
  PhotolineController({
    this.openRatio = .8,
    required this.getUri,
    required this.getKey,
    required this.getBackground,
    required this.getWidget,
    required this.getPhotoCount,
    this.getCloseCount = _getCloseCount,
    this.onAdd,
    this.onRemove,
    this.onReplace,
    this.getPagerItem,
    this.getPagerIndexOffset = _getPagerIndexOffset,
    this.getPersistentWidgets,
    this.isTileOpenGray = true,
  });

  PhotolineHolderDragController? dragController;

  final Uri? Function(int) getUri;
  final Color Function(int) getBackground;
  final Widget Function(int) getWidget;
  final Key Function(int) getKey;
  final ValueGetter<int> getPhotoCount;
  final ValueGetter<int> getCloseCount;
  final void Function(int index)? onAdd;
  final void Function(int index)? onRemove;
  final List<Widget>? Function(int index)? getPersistentWidgets;
  final void Function(int newIndex, int oldIndex)? onReplace;
  final List<Widget> Function(int index, Color color)? getPagerItem;
  final int Function() getPagerIndexOffset;
  final bool isTileOpenGray;

  final double openRatio;

  double get closeRatio => 1 / getCloseCount();

  PhotolineAction action = PhotolineAction.close;
  int pageTargetOpen = -1;

  double? get page {
    assert(positions.isNotEmpty, 'PageController.page cannot be accessed before a PageView is built with it.');
    assert(positions.length == 1, 'The page property cannot be read when multiple PageViews are attached to the same PageController.');
    final PhotolineScrollPosition position = this.position as PhotolineScrollPosition;
    return position.page;
  }

  PhotolineScrollPosition get pos => position as PhotolineScrollPosition;

  PhotolineSize get size => PhotolineSize(this);

  int get count => math.max(getPhotoCount(), getCloseCount());

  PhotolineState? photoline;

  final List<PhotolineMod?> mod = [];

  void onAnimationAdd() {
    if (photoline == null || mod.isEmpty) return;
    final double dx = photoline!.animationAdd.velocity;

    for (int i = 0; i < mod.length; i++) {
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
    if (action != PhotolineAction.close) return;
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

  void addItem(int index) {
    if (action != PhotolineAction.close) return;
    onAdd?.call(index);
    //final size = PhotolineSize(this);
    //pos.forceExtent(size.close);
    while (index >= mod.length) {
      mod.add(null);
    }
    mod.insert(index, PhotolineMod(0, 1));
    photoline?.rebuild();
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      PhotolineScrollPosition(
        controller: this,
        physics: physics,
        context: context,
        oldPosition: oldPosition,
      );

  /// === [Drag]
  int pageDragInitial = -1;
  int pageDragTile = 0;
  final List<PhotolineDrag> positionDrag = [];
  Offset dragOffset = Offset.zero;
  late RenderBox renderBox;
  late Offset renderOffset;
  bool isDragStart = false;
  bool isDragMain = false;

  void onPointerDown(PhotolineTileState tile, PointerDownEvent event) => dragController?.onPointerDown(this, tile, event);

  void onDirection(int direction) {
    if (direction == 0) return;
    final size = this.size;

    if (direction > 0) {
      for (int i = positionDrag.length - 1; i >= 0; i--) {
        final pi = positionDrag[i];
        if ((isDragMain && pi.index == pageDragInitial) || pi.page < size.viewCount - 1) continue;
        for (int k = positionDrag.length - 1; k >= 0; k--) {
          positionDrag[k].page -= 1;
        }
        break;
      }
    } else {
      for (int i = 0; i < positionDrag.length; i++) {
        final pi = positionDrag[i];
        if ((isDragMain && pi.index == pageDragInitial) || pi.page >= 0) {
          continue;
        }
        for (int k = 0; k < positionDrag.length; k++) {
          positionDrag[k].page += 1;
        }
        break;
      }
    }
  }

  void onChangeCurrent(bool isCurrent) {
    final size = this.size;
    if (!isCurrent) {
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

    final size = this.size;

    final List<double> ws = [];
    final List<double> os = [];
    final count = this.count;
    mod.clear();

    for (int i = 0; i < count; i++) {
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

    action = PhotolineAction.drag;
  }

  PhotolineDrag? _nxt(PhotolineDrag pi) {
    for (int k = pi.index + 1; k < positionDrag.length; k++) {
      final pk = positionDrag[k];
      if (isDragMain && pk.index == pageDragInitial) continue;
      return pk;
    }
    return null;
  }

  PhotolineDrag? _prv(PhotolineDrag pi) {
    for (int k = pi.index - 1; k >= 0; k--) {
      final pk = positionDrag[k];
      if (isDragMain && pk.index == pageDragInitial) continue;
      return pk;
    }
    return null;
  }

  void onAnimationDrag({
    required double dx,
    required bool isCurrent,
    required double tileOffset,
  }) {
    final size = this.size;
    pageDragTile = (tileOffset / size.close).round();

    for (int i = 0; i < positionDrag.length; i++) {
      final pi = positionDrag[i];
      if (isDragMain && pi.index == pageDragInitial) continue;

      int pos = pi.page;
      if (isCurrent && pos >= pageDragTile) pos += 1;

      double move = dx * 100;
      final double dd = size.close * 3;
      move *= Curves.easeOutCubic.transform((dd - math.min(dd, (pageDragTile * size.close - pi.offset).abs())) / dd) + 1;

      final double end = pos * size.close;
      final dist = (pi.offset - end).abs();
      if (move > dist) move = dist;

      if (pi.offset < end) {
        final nxt = _nxt(pi);
        if (nxt != null) {
          final r = pi.offset + size.close;
          move = r > nxt.offset ? 0 : math.min(nxt.offset - r, move);
        }
        pi.offset += move;
      } else {
        final prv = _prv(pi);
        if (prv != null) {
          final r = prv.offset + size.close;
          if (pi.offset < r) {
            move = 0;
          } else {
            move = math.min(pi.offset - r, move);
          }
        }
        pi.offset -= move;
      }
    }
  }

  void onDragEndStart(bool isReplace) {
    if (!isReplace) return;
  }

  void onDragEndEnd(bool isReplace) {
    if (!isDragStart) return;

    action = PhotolineAction.close;

    if (isReplace) {
      for (int i = 0; i < positionDrag.length; i++) {
        final pi = positionDrag[i];
        if (pi.index == pageDragInitial) continue;
        int page = pi.page;
        if (pi.index > pageDragInitial) page += 1;
        if (pi.index == pageDragInitial || pageDragTile != page) continue;
        final item = positionDrag.removeAt(pageDragInitial);
        positionDrag.insert(pi.index, item);
        onReplace?.call(pi.index, pageDragInitial);
        pageDragInitial = pi.index;
        break;
      }

      int d = pageDragTile;
      for (int i = pageDragInitial; i >= 0; i--) {
        positionDrag[i].page = d--;
      }
      d = pageDragTile;
      for (int i = pageDragInitial + 1; i < positionDrag.length; i++) {
        positionDrag[i].page = ++d;
      }

      for (int i = 0; i < positionDrag.length; i++) {
        final pi = positionDrag[i];
        if (pi.page == 0) {
          pos.jumpToPage(i);
          break;
        }
      }
    }

    positionDrag.clear();
    pageDragInitial = -1;
    pageDragTile = 0;
    isDragMain = false;
    isDragStart = false;
  }

  int correctCloseTargetIndex(int all, int visible, int current, int target) {
    visible--;
    final rlimit = all - 1 - current;
    final rtarget = visible - target;
    if (rtarget > rlimit) target += rtarget - rlimit;
    if (target > current) target += current - target;
    return target;
  }

  void replaceListItems(List<dynamic> list, int target, int anchor, bool isAfter) {
    final item = list.removeAt(target);
    if (isAfter) {
      list.insert(anchor, item);
    } else {
      list.insert(anchor, item);
    }
  }
}
