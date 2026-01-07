import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

mixin PhotolineTileMixin<T extends StatefulWidget> on State<T> {
  Widget buildContent();

  PhotolineController get photoline;

  int get index;

  final _loaderNotifier = PhotolineLoaderNotifier.instance;

  PhotolineLoader? loader;

  @override
  void initState() {
    loader = photoline.getLoader?.call(index);
    PhotolineLoaderNotifier.instance.addListener(_onLoaderChange);
    super.initState();
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
      l.opacity = 1;
      super.setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = buildContent();
    return GestureDetector(
      onTap: () => photoline.photoline?.toPage(index),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
