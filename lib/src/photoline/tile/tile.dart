import 'package:flutter/material.dart';
import 'package:photoline/src/holder/controller/drag.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/photoline/controller.dart';
import 'package:photoline/src/photoline/loader/loader.dart';
import 'package:photoline/src/photoline/photoline.dart';
import 'package:photoline/src/photoline/tile/data.dart';
import 'package:photoline/src/photoline/tile/uri.dart';

class PhotolineTile extends StatefulWidget {
  const PhotolineTile({
    super.key,
    required this.index,
    required this.controller,
    required this.photoline,
  });

  final int index;
  final PhotolineController controller;
  final PhotolineState photoline;

  @override
  State<PhotolineTile> createState() => PhotolineTileState();
}

class PhotolineTileState extends State<PhotolineTile> with TickerProviderStateMixin, StateRebuildMixin {
  int get _index => widget.index;

  PhotolineState get _photoline => widget.photoline;

  PhotolineController get _controller => widget.controller;

  PhotolineHolderDragController? get _drag => _controller.photoline?.holder?.dragController;

  @override
  void initState() {
    super.initState();
    PhotolineUriNotifier.instance.addListener(_onUriChange);
    PhotolineLoaderNotifier.instance.addListener(_onLoaderChange);
  }

  @override
  void dispose() {
    PhotolineUriNotifier.instance.removeListener(_onUriChange);
    PhotolineLoaderNotifier.instance.removeListener(_onLoaderChange);
    super.dispose();
  }

  void _onUriChange() {
    final uri = _controller.getUri(_index)?.cached.uri;
    if (uri != null && uri == PhotolineUriNotifier.instance.uri) {
      rebuild();
    }
  }

  void _onLoaderChange() {
    final loader = _controller.getLoader?.call(_index);
    if (loader?.uri != null && loader!.uri == PhotolineLoaderNotifier.instance.uri) {
      rebuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = _controller.size;

          final uri = _controller.getUri(widget.index)?.cached;
          final loader = _controller.getLoader?.call(widget.index);

          final (double, double) limit = size.close > size.side2 ? (size.side2, size.close) : (size.close, size.side2);
          final double cdwa = constraints.maxWidth.clamp(limit.$1, limit.$2) - size.side2;

          final data = PhotolineTileData(
            index: _index,
            uri: uri,
            loader: loader,
            closeDw: (cdwa / (size.close - size.side2)).clamp(0, 1),
            openDw: (constraints.maxWidth - size.close) / (size.open - size.close).clamp(-1, 1),
            dragging: (_drag?.isDrag ?? false) && _controller.pageDragInitial == _index,
            isRemove: _drag?.isRemove ?? false,
          );

          final List<Widget>? persistent = _controller.getPersistentWidgets?.call(data);

          Widget child = Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('widget'),
                child: _controller.pageActiveOpenComplete.value == _index ? _controller.getWidget(_index) ?? const SizedBox() : const SizedBox(),
              ),
              if (persistent != null) ...persistent,
            ],
          );

          if (_controller.canDrag && _photoline.holder?.dragController != null && _controller.getPhotoCount() > _index) {
            child = Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _controller.onPointerDown(this, event),
              child: child,
            );
          }

          return GestureDetector(
            onTap: () => _photoline.toPage(_index),
            behavior: HitTestBehavior.opaque,
            child: child,
          );
        },
      ),
    );
  }
}
