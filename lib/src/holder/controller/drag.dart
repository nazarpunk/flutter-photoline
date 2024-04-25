import 'dart:async';

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/controller.dart';
import 'package:photoline/src/holder/holder.dart';
import 'package:photoline/src/tile/tile.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/photoline_tile_intersection.dart';

/// Drag controller.
class PhotolineHolderDragController implements Drag {
  /// === [Drag]
  PhotolineHolderState? holder;
  OverlayState? _overlayState;
  OverlayEntry? _overlayEntry;

  bool isDrag = false;
  bool isDragClose = false;

  late PhotolineController _initialController;
  late PhotolineController _currentController;
  late PhotolineTileState _initialTile;

  final _recognizerDelay = DelayedMultiDragGestureRecognizer();
  final _recogniserAbsorb = ImmediateMultiDragGestureRecognizer();
  late Offset _tileOffset;
  late Offset _tileOffsetVisible;
  late Offset _closeOffsetStart;
  late Offset _closeOffsetEnd;
  late Size _tileSize;

  Timer? _scrollTimer;

  void _onScrollTimerEnd(Timer timer) {
    if (isDragClose) return;
    _currentController.onDirection(_scrollDirection);
  }

  double removeDx = 0;

  late int _scrollDirection;
  late double closeDx;
  late bool _isRemove;

  void onAnimationDrag() {
    if (holder == null) return;
    final dx = holder!.animationDrag.velocity;

    if (isDragClose) {
      closeDx = (closeDx + dx * .5).clamp(0, 1);

      if (_isRemove) {
      } else {
        _tileOffsetVisible =
            Offset.lerp(_closeOffsetStart, _closeOffsetEnd, closeDx)!;
      }
      _animateControllers(dx);
      _overlayEntry?.markNeedsBuild();
      if (closeDx < 1) return;
      for (final photoline in holder!.photolines) {
        final controller = photoline.controller;
        if (!controller.isDragStart) continue;
        if (_isRemove) {
          controller.onDragEndRemove();
        } else {
          if (_initialController == _currentController) {
            controller.onDragEndReorder();
          } else {
            if (controller == _initialController) {
              controller.onTransfer?.call(
                _initialController.getTransferState!()!,
                _initialController.pageDragInitial,
                _currentController.getTransferState!()!,
                _currentController.pageDragTransferTarget,
              );
            }
          }
        }

        controller.onDragEndEnd();
      }

      holder?.animationDrag.stop();
      isDrag = false;
      isDragClose = false;
      _overlayEntry?.remove();
      _overlayEntry = null;

      return;
    }

    const curDh = .55;
    final RenderBox overlayBox =
        _overlayState!.context.findRenderObject()! as RenderBox;

    PhotolineController? current;
    for (final photoline in holder!.photolines) {
      final controller = photoline.controller;
      if (controller.action.value != PhotolineAction.drag &&
          controller.action.value != PhotolineAction.close) continue;

      controller
        ..renderBox = photoline.context.findRenderObject()! as RenderBox
        ..renderOffset = controller.renderBox
            .localToGlobal(Offset.zero, ancestor: overlayBox);

      final dh = photolineTileIntersection(_tileOffset.dy, _tileSize.height,
              controller.renderOffset.dy, controller.renderBox.size.height) /
          _tileSize.height;
      if (dh >= curDh) current = controller;
    }

    _isRemove = current == null;

    if (_isRemove) {
      removeDx = math.min(1, removeDx + dx);
    } else {
      removeDx = math.max(0, removeDx - dx);
      current!.onDragStart(false);
      if (_currentController != current) {
        _scrollTimer?.cancel();
        _scrollDirection = 0;
        _currentController.onChangeCurrent(false);
        current.onChangeCurrent(true);
      }
      _currentController = current;
    }

    int direction = 0;
    const double preciese = 10;
    final dirdiff = _tileOffset.dx - _tileOffsetVisible.dx;
    if (dirdiff < -preciese) {
      direction = -1;
    } else if (dirdiff > preciese) {
      direction = 1;
    }
    if (direction != _scrollDirection) {
      _scrollDirection = direction;
      _scrollTimer?.cancel();
      if (direction != 0) {
        _scrollTimer = Timer.periodic(
            const Duration(milliseconds: 300), _onScrollTimerEnd);
        _onScrollTimerEnd(_scrollTimer!);
      }
    }

    _animateControllers(dx);
  }

  void _animateControllers(double dx) {
    for (final photoline in holder!.photolines) {
      final controller = photoline.controller;
      if (!controller.isDragStart) continue;
      controller.onAnimationDrag(
        dx: dx,
        isCurrent: _currentController == controller && !_isRemove,
        tileOffset: (_tileOffsetVisible.dx - controller.renderOffset.dx)
            .clamp(0, controller.renderBox.size.width),
      );
    }
  }

  Drag? _onDragStart(Offset offset) {
    if (_initialController.action.value != PhotolineAction.close) return null;
    if (!_initialTile.context.mounted) return null;

    for (final photoline in holder!.photolines) {
      final controller = photoline.controller;
      if (controller.action.value == PhotolineAction.drag) return null;
    }

    for (final photoline in holder!.photolines) {
      photoline.close();
    }

    if (isDrag || isDragClose) return null;
    isDrag = true;
    _scrollDirection = 0;
    closeDx = 0;
    _isRemove = false;
    removeDx = 0;

    _initialController.onDragStart(true);

    holder!.animationDrag.repeat();

    _overlayState = Overlay.of(holder!.context);

    final RenderBox tileBox =
        _initialTile.context.findRenderObject()! as RenderBox;
    final RenderBox overlayBox =
        _overlayState!.context.findRenderObject()! as RenderBox;

    _tileSize = tileBox.size;
    _tileOffset = tileBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    _tileOffsetVisible = _tileOffset;

    _overlayState!.insert(
      _overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned(
              left: _tileOffsetVisible.dx,
              top: _tileOffsetVisible.dy,
              width: _tileSize.width,
              height: _tileSize.height,
              child: Transform.scale(
                scale: _isRemove ? (1 - closeDx).clamp(0, 1) : 1,
                child: _initialTile.widget,
              ),
            ),
          ],
        ),
      ),
    );

    return this;
  }

  void _onDragEndStart() {
    isDrag = false;
    isDragClose = true;
    _scrollTimer?.cancel();
    if (_isRemove) {
    } else {
      _closeOffsetStart = _tileOffsetVisible;
      _closeOffsetEnd = _currentController.closeOffsetEnd;
    }
  }

  void onPointerDown(PhotolineController controller, PhotolineTileState tile,
      PointerDownEvent event) {
    if (controller.action.value != PhotolineAction.close) return;
    if (isDrag) {
      _recogniserAbsorb.addPointer(event);
    } else {
      if (!isDragClose) {
        _initialController = controller;
        _currentController = controller;
        _initialTile = tile;
        controller.pageDragInitial = tile.widget.index;
      }
      _recognizerDelay
        ..onStart = _onDragStart
        ..addPointer(event);
    }
  }

  @override
  void cancel() => _onDragEndStart();

  @override
  void end(DragEndDetails details) => _onDragEndStart();

  @override
  void update(DragUpdateDetails details) {
    _tileOffset += details.delta;
    double dx = _tileOffset.dx;
    double dy = _tileOffset.dy;

    final RenderBox overlayBox =
        _overlayState!.context.findRenderObject()! as RenderBox;

    if (dx < 0) dx = 0;
    if (dx + _tileSize.width > overlayBox.size.width) {
      dx = overlayBox.size.width - _tileSize.width;
    }
    if (dy < 0) dy = 0;
    if (dy + _tileSize.height > overlayBox.size.height) {
      dy = overlayBox.size.height - _tileSize.height;
    }

    _tileOffsetVisible = Offset(dx, dy);

    _overlayEntry?.markNeedsBuild();

    _initialController
      ..dragOffset += details.delta
      ..photoline?.rebuild();
  }
}
