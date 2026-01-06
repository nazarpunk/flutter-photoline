import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photoline/src/photoline/controller.dart';
import 'package:photoline/src/holder/holder.dart';
import 'package:photoline/src/scroll/snap/controller.dart';
import 'package:photoline/src/photoline/tile/tile.dart';
import 'package:photoline/src/utils/action.dart';
import 'package:photoline/src/utils/photoline_tile_intersection.dart';

/// Drag controller.
class PhotolineHolderDragController implements Drag {
  PhotolineHolderDragController({
    required this.snapController,
  });

  final ScrollSnapController snapController;

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

  int _snapDirection = 0;
  Timer? _snapTimer;

  late int _scrollDirection;
  late double closeDx;
  bool isRemove = false;

  void onAnimationDrag() {
    if (holder == null) return;
    final dx = holder!.animationDrag.velocity;

    if (isDragClose) {
      // close time
      closeDx = (closeDx + dx * (isRemove ? .7 : 1)).clamp(0, 1);

      if (isRemove) {
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
        if (isRemove) {
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

    final overlayBox =
        _overlayState!.context.findRenderObject()! as RenderBox;

    PhotolineController? current;
    for (final photoline in holder!.photolines) {
      final controller = photoline.controller;
      if (controller.action.value != PhotolineAction.drag &&
          controller.action.value != PhotolineAction.close) {
        continue;
      }

      controller
        ..renderBox = photoline.context.findRenderObject()! as RenderBox
        ..renderOffset = controller.renderBox
            .localToGlobal(Offset.zero, ancestor: overlayBox);

      final dh = photolineTileIntersection(_tileOffset.dy, _tileSize.height,
              controller.renderOffset.dy, controller.renderBox.size.height) /
          _tileSize.height;
      if (dh >= curDh) current = controller;
    }

    isRemove = current == null;

    if (!isRemove) {
      current!.onDragStart(false);
      if (_currentController != current) {
        _scrollDirection = 0;
        _currentController.onChangeCurrent(false);
        current.onChangeCurrent(true);
      }
      _currentController = current;
    }

    final phc = _currentController.photoline!.context;
    final prb = phc.findRenderObject()! as RenderBox;
    final pro = prb.localToGlobal(Offset.zero, ancestor: overlayBox);

    var direction = 0;
    const double preciese = 10;
    if ((_tileOffset.dx + _tileSize.width) - (pro.dx + prb.size.width) >=
        preciese) {
      direction = 1;
    }
    if (pro.dx - _tileOffset.dx >= preciese) {
      direction = -1;
    }

    if (direction != _scrollDirection) {
      _currentController.direction = _scrollDirection = direction;
    }

    _animateControllers(dx);
  }

  void _animateControllers(double dx) {
    for (final photoline in holder!.photolines) {
      final controller = photoline.controller;
      if (!controller.isDragStart) continue;
      controller.onAnimationDrag(
        dx: dx,
        isCurrent: _currentController == controller && !isRemove,
        tileOffset: (_tileOffsetVisible.dx - controller.renderOffset.dx)
            .clamp(0, controller.renderBox.size.width),
      );
    }
  }

  Drag? _onDragStart(Offset offset) {
    if (_initialController.action.value != PhotolineAction.close) return null;
    if (!_initialTile.context.mounted) return null;
    holder?.animationDrag.duration = const Duration(milliseconds: 10000);

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
    isRemove = false;

    _initialController.onDragStart(true);

    unawaited(holder!.animationDrag.repeat());

    _overlayState = Overlay.of(holder!.context);

    final tileBox =
        _initialTile.context.findRenderObject()! as RenderBox;
    final overlayBox =
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
                scale: isRemove ? (1 - closeDx).clamp(0, 1) : 1,
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

    if (!isRemove) {
      _closeOffsetStart = _tileOffsetVisible;
      _closeOffsetEnd = _currentController.closeOffsetEnd;
    }
    _snapTimer?.cancel();
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

  void _snapTimerRun() {
    if (_snapDirection == 0 || isDragClose) return;
    snapController.position.photolineScrollToNext(_snapDirection);
    _snapTimer = Timer(const Duration(milliseconds: 500), _snapTimerRun);
  }

  @override
  void update(DragUpdateDetails details) {
    _tileOffset += details.delta;
    double dx = _tileOffset.dx;
    final double dy = _tileOffset.dy;

    final overlayBox = _overlayState!.context.findRenderObject()! as RenderBox;

    final photolineBox =
        _currentController.photoline!.context.findRenderObject()! as RenderBox;

    final photolineOffset =
        photolineBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    // dx
    if (dx < photolineOffset.dx) dx = photolineOffset.dx;
    final pr = photolineBox.size.width + photolineOffset.dx;
    if (dx + _tileSize.width > pr) {
      dx = pr - _tileSize.width;
    }

    // dy
    var snapDir = 0;
    if (dy < 0) {
      //dy = 0;
      snapDir = -1;
    }
    if (dy + _tileSize.height > overlayBox.size.height) {
      //dy = overlayBox.size.height - _tileSize.height;
      snapDir = 1;
    }

    if (_snapDirection != snapDir) {
      _snapDirection = snapDir;
      _snapTimer?.cancel();
      _snapTimerRun();
    }

    _tileOffsetVisible = Offset(dx, dy);

    _overlayEntry?.markNeedsBuild();

    _initialController
      ..dragOffset += details.delta
      ..photoline?.rebuild();
  }
}
