import 'package:flutter/material.dart';
import 'package:photoline/library.dart';
import 'package:photoline/src/photoline/sliver/render_sliver_multi_box_adaptor.dart';

mixin PhotolineTileMixin<T extends StatefulWidget> on State<T> {
  Widget buildContent();

  PhotolineController get photoline;

  int get index;

  final _loaderNotifier = PhotolineLoaderNotifier.instance;

  PhotolineLoader? loader;

  VoidCallback markNeedsPaint = () {};

  void onImageLoad() {
    final l = loader;
    if (l == null) return;
    l.opacity = 1;
    markNeedsPaint();
    if (super.mounted) super.setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loader = photoline.getLoader?.call(index);
    PhotolineLoaderNotifier.instance.addListener(_onLoaderChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final renderSliver = context.findAncestorRenderObjectOfType<PhotolineRenderSliverMultiBoxAdaptor>();
    markNeedsPaint = renderSliver?.markNeedsPaint ?? () {};
    final l = loader;
    if (l != null && l.image != null) {
      onImageLoad();
    }
  }

  @override
  void dispose() {
    PhotolineLoaderNotifier.instance.removeListener(_onLoaderChange);
    super.dispose();
  }

  void _onLoaderChange() {
    final l = loader;
    if (l == null) return;
    final uri = l.uri;
    if (uri != null && uri == _loaderNotifier.uri) {
      onImageLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = buildContent();

    if (photoline.canDrag && photoline.photoline?.holder?.dragController != null && photoline.getPhotoCount() > index) {
      child = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => photoline.onPointerDown(this, event),
        child: child,
      );
    }

    return GestureDetector(
      onTap: () => photoline.photoline?.toPage(index),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
