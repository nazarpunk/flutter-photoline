import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/photoline/dummy.dart';

class PhotolineTestWidget extends StatefulWidget {
  const PhotolineTestWidget({super.key});

  @override
  State<PhotolineTestWidget> createState() => _PhotolineTestWidgetState();
}

class _PhotolineTestWidgetState extends State<PhotolineTestWidget> {
  late final ScrollSnapController _controller;

  final List<PhotolineController> _photolines = [];

  @override
  void initState() {
    _controller = ScrollSnapController(
      snapLast: true,
      snapPhotolines: () => _photolines,
    );
    for (int i = 0; i < 3; i++) {
      _photolines.add(PhotolineController(
        getUri: (index) => PhotolineDummys.get(i, index),
        getKey: ValueKey.new,
        //getWidget: (index) => const Placeholder(),
        getWidget: (index) => const SizedBox(),
        //getPersistentWidgets: (index) => [const Placeholder()],
        getPhotoCount: () => 10,
      ));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _controller.boxConstraints = constraints;
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
                  delegate: SliverChildBuilderDelegateWithGap(
                    (context, index) => _Child(
                      index: index,
                      constraints: constraints,
                      controller: _photolines[index],
                    ),
                    childCount: _photolines.length,
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
    required this.controller,
  });

  final int index;
  final BoxConstraints constraints;
  final PhotolineController controller;

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  @override
  Widget build(BuildContext context) {
    return PhotolineConstrainted(
      controller: widget.controller,
      constraints: widget.constraints,
      header: Photoline(controller: widget.controller),
      footer: const SizedBox(child: Placeholder(color: Colors.green)),
    );
  }
}
