import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photoline/library.dart';
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
  late PhotolineTileMixin _initialTile;
  Widget? _overlayChild;
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
  /// Fully reset drag controller state so the next drag can start cleanly.
  void _fullReset() {
    _snapTimer?.cancel();
    _snapTimer = null;
    _snapDirection = 0;
    isRemove = false;
    // Stop animation BEFORE clearing flags to prevent listener re-entry issues
    holder?.animationDrag.stop();
    isDrag = false;
    isDragClose = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayChild = null;
    holder?.active.value = false;
  }
  void onAnimationDrag() {
    if (holder == null) return;
    final dx = holder!.animationDrag.velocity;
    if (isDragClose) {
      // Use animation value directly with easing for smooth close
      final animValue = holder!.animationDrag.value;
      closeDx = Curves.easeOut.transform(animValue);
      _tileOffsetVisible =
          Offset.lerp(_closeOffsetStart, _closeOffsetEnd, closeDx)!;
      _animateControllers(dx);
      _overlayEntry?.markNeedsBuild();
      if (animValue < 1) return;
      // Cache transfer parameters before any reset
      final doTransfer = !isRemove && _initialController != _currentController;
      final State? fromState = doTransfer ? _initialController.getTransferState?.call() : null;
      final int fromIndex = _initialController.pageDragInitial;
      final State? toState = doTransfer ? _currentController.getTransferState?.call() : null;
      final int toIndex = _currentController.pageDragTransferTarget;
      final transferCallback = doTransfer ? _initialController.onTransfer : null;
      // Perform transfer BEFORE resetting controllers so that
      // the target already has the item when it transitions to close state
      // (prevents repeated add animation).
      if (doTransfer && fromState != null && toState != null) {
        transferCallback?.call(fromState, fromIndex, toState, toIndex);
      }
      // Reorder within same photoline (only for the main controller)
      if (!doTransfer) {
        for (final photoline in holder!.photolines) {
          final controller = photoline.controller;
          if (!controller.isDragStart) continue;
          controller.onDragEndReorder();
        }
      }
      // End drag on ALL controllers (not only those with isDragStart,
      // to guarantee no stale state remains after transfer).
      for (final photoline in holder!.photolines) {
        final controller = photoline.controller;
        controller.onDragEndEnd(setHolderInactive: false);
      }
      // Rebuild photolines after transfer so they reflect the new item counts
      if (doTransfer) {
        _initialController.photoline?.rebuild();
        _initialController.photoline?.widget.rebuilder();
        _currentController.photoline?.rebuild();
        _currentController.photoline?.widget.rebuilder();
      }
      // Full reset of the drag controller state
      _fullReset();
      if (kDebugMode) print('✅ Drag cleanup complete: doTransfer=\$doTransfer');
      return;
    }
    const curDh = .55;
    // Only process drag animation if we're actually dragging
    if (!isDrag) return;
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
    // Build overlay child from the loader image
    final loader = _initialController.getLoader?.call(_initialTile.index);
    _overlayChild = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: loader?.image != null
          ? PhotolineImage(
              loader: loader,
              sigma: 0,
            )
          : const ColoredBox(color: Color.fromRGBO(50, 50, 50, 1)),
    );
    _overlayState!.insert(
      _overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned(
              left: _tileOffsetVisible.dx,
              top: _tileOffsetVisible.dy,
              width: _tileSize.width,
              height: _tileSize.height,
              child: _overlayChild!,
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
    _closeOffsetStart = _tileOffsetVisible;
    if (isRemove) {
      // Animate back to original position
      _closeOffsetEnd = _initialController.closeOffsetEnd;
      _currentController = _initialController;
    } else {
      _closeOffsetEnd = _currentController.closeOffsetEnd;
    }
    _snapTimer?.cancel();
    _snapTimer = null;
    _snapDirection = 0;
    // Restart animation with a fixed duration for smooth close
    final anim = holder?.animationDrag;
    if (anim != null) {
      anim
        ..stop()
        ..duration = const Duration(milliseconds: 300);
      closeDx = 0;
      unawaited(anim.forward(from: 0));
    } else {
      // Safety: if holder/anim is null, force cleanup immediately
      for (final photoline in holder?.photolines ?? <PhotolineState>{}) {
        photoline.controller.onDragEndEnd(setHolderInactive: false);
      }
      _fullReset();
    }
  }
  void onPointerDown(PhotolineController controller, PhotolineTileMixin tile,
      PointerDownEvent event) {
    if (controller.action.value != PhotolineAction.close) return;
    if (isDrag) {
      _recogniserAbsorb.addPointer(event);
    } else {
      if (!isDragClose) {
        _initialController = controller;
        _currentController = controller;
        _initialTile = tile;
        controller.pageDragInitial = tile.index;
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
