import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class PhotolineTestWidget extends StatefulWidget {
  const PhotolineTestWidget({super.key});

  @override
  State<PhotolineTestWidget> createState() => _PhotolineTestWidgetState();
}

class _PhotolineTestWidgetState extends State<PhotolineTestWidget> {
  late final _controller = ScrollSnapController();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          return PhotolineHolder(
            child: ScrollSnap(
              controller: _controller,
              cacheExtent: .1,
              slivers: [
                ScrollSnapRefresh(
                  controller: _controller,
                ),
                SliverSnapList(
                  controller: _controller,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _Child(constraints),
                    childCount: 10,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Child extends StatefulWidget {
  const _Child(this.constraints);

  final BoxConstraints constraints;

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  late final PhotolineController _controller;

  @override
  void initState() {
    _controller = PhotolineController(
      getUri: (index) => null,
      getKey: ValueKey.new,
      getWidget: (index) => const Placeholder(),
      getPersistentWidgets: (index) => [const Placeholder()],
      getPhotoCount: () => 10,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PhotolineConstrainted(
      controller: _controller,
      constraints: widget.constraints,
      header: Photoline(controller: _controller),
      footer: const SizedBox(child: Placeholder(color: Colors.green)),
    );
  }
}
