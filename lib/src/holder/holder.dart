import 'package:flutter/material.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/photoline.dart';

class PhotolineHolder extends StatefulWidget {
  const PhotolineHolder({
    super.key,
    required this.child,
    this.dragController,
  });

  final Widget child;
  final PhotolineHolderDragController? dragController;

  @override
  State<PhotolineHolder> createState() => PhotolineHolderState();
}

class PhotolineHolderState extends State<PhotolineHolder>
    with TickerProviderStateMixin {
  PhotolineHolderDragController? get dragController => widget.dragController;
  final Set<PhotolineState> photolines = {};

  late final AnimationController animationDrag;

  @override
  void initState() {
    dragController?.holder = this;
    animationDrag = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 10 * 1000));
    if (dragController != null) {
      animationDrag.addListener(dragController!.onAnimationDrag);
    }
    super.initState();
  }

  @override
  void dispose() {
    dragController?.holder = null;
    animationDrag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
