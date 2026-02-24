import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

/// Test tile widget for Photoline.
/// Uses [PhotolineTileMixin] to handle image loading, tap, and drag.
class PhotolineTileTest extends StatefulWidget {
  const PhotolineTileTest({
    required this.index,
    required this.photoline,
    super.key,
  });

  final int index;
  final PhotolineController photoline;

  @override
  State<PhotolineTileTest> createState() => _PhotolineTileTestState();
}

class _PhotolineTileTestState extends State<PhotolineTileTest> with PhotolineTileMixin {
  @override
  int get index => widget.index;

  @override
  PhotolineController get photoline => widget.photoline;

  PhotolineHolderDragController? get _drag => photoline.photoline?.holder?.dragController;

  bool get _dragging => (_drag?.isDrag ?? false) && photoline.pageDragInitial == index;

  @override
  Widget buildContent() {
    if (_dragging) {
      final isRemove = _drag?.isRemove ?? false;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (loader?.image != null)
            Positioned.fill(
              child: ClipRect(
                child: PhotolineImage(
                  sigma: 10,
                  loader: loader,
                ),
              ),
            ),
          SizedBox.expand(
            child: ColoredBox(
              color: isRemove
                  ? const Color.fromRGBO(200, 0, 0, .4)
                  : const Color.fromRGBO(23, 162, 184, .4),
              child: Icon(
                isRemove ? Icons.delete : Icons.open_with,
                size: 32,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.expand();
  }
}

