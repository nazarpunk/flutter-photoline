import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/photoline/dummy.dart';

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
                    (context, index) => _Child(
                      index: index,
                      constraints: constraints,
                    ),
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
  const _Child({
    required this.index,
    required this.constraints,
  });

  final int index;
  final BoxConstraints constraints;

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  late final PhotolineController _controller;

  @override
  void initState() {
    _controller = PhotolineController(
      getUri: (index) => PhotolineDummys.get(widget.index, index),
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
