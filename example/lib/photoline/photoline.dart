import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/photoline/dummy.dart';

part '_child.dart';

part '_photoline.dart';

class PhotolineTestWidget extends StatefulWidget {
  const PhotolineTestWidget({super.key});

  @override
  State<PhotolineTestWidget> createState() => _PhotolineTestWidgetState();
}

class _PhotolineTestWidgetState extends State<PhotolineTestWidget> {
  late final ScrollSnapController _controller;
  late final PhotolineHolderDragController _photolineHolderDragController;

  final List<PhotolineController> _photolines = [];

  final List<List<Uri>> _uris = [];
  final List<List<Key>> _keys = [];

  int _min = -1;

  void _reload() {
    _photolines.clear();
    _uris.clear();
    ++_min;

    for (int i = _min; i < 10; i++) {
      final List<Uri> l = [];
      final List<Key> k = [];
      for (int j = 0; j < 20 - i; j++) {
        l.add(PhotolineDummys.get(i, j));
        k.add(ValueKey<String>('$i $j'));
      }
      _uris.add(l);
      _keys.add(k);
    }

    for (int i = 0; i < _uris.length; i++) {
      final c = PhotolineController(
        getUri: (index) => _uris[i][index],
        getKey: (index) => _keys[i][index],
        //getWidget: (index) => const Placeholder(),
        getWidget: (index) => const SizedBox(),
        getPersistentWidgets: (data) {
          if (kDebugMode) return [];

          final List<Widget> out = [];

          if (data.loading < 1) {
            out.add(const Center(
              child: CircularProgressIndicator(),
            ));
          }
          out.add(Center(
            child: ColoredBox(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${data.index}'),
              ),
            ),
          ));

          if (data.dragging) {
            out.add(const Placeholder());
          }

          return out;
        },
        getPhotoCount: () => _uris[i].length,
        onAdd: (index, data) {
          _uris[i].insert(index, data as Uri);
        },
        onRemove: (index) {
          _uris[i].removeAt(index);
          //print('onRemove|$index');
        },
        onReorder: (oldIndex, newIndex) {
          _uris[i].reorder(oldIndex, newIndex);
          //print('onReorder|$oldIndex|$newIndex');
        },
        getBackside: (index) {
          final List<Color> colors = [
            Colors.red,
            Colors.green,
            Colors.purple,
            Colors.tealAccent
          ];

          if (kDebugMode) {
            return Container(
              width: 500,
              height: 1,
              color: colors[index % colors.length],
            );
          }
          return PhotolineAlbumPhotoDummy(
            child: Container(
              width: 500,
              height: 1,
              color: colors[index % colors.length],
            ),
          );
        },
        wrapHeight: (w, h, t) {
          const double footer = 64;
          return lerpDouble(w * .7 + footer, h, t)! + 20;
        },
        rebuilder: () {
          if (mounted) setState(() {});
        },
      );

      _photolines.add(c);
    }
  }

  @override
  void initState() {
    _reload();

    _controller = ScrollSnapController(
      snapLast: true,
      snapPhotolines: () => _photolines,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _reload();
        setState(() {});
      },
    );
    _photolineHolderDragController = PhotolineHolderDragController(
      snapController: _controller,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _controller.boxConstraints = constraints;
        return PhotolineHolder(
          dragController: _photolineHolderDragController,
          child: ScrollSnap(
            controller: _controller,
            cacheExtent: .1,
            slivers: [
              ScrollSnapRefresh(
                controller: _controller,
              ),
              SliverPhotolineList(
                (context, index) => AutomaticKeepAlive(
                  key: ValueKey(index),
                  child: _Child(
                    key: ValueKey(index),
                    controller: _photolines[index],
                    index: index,
                    constraints: constraints,
                  ),
                ),
                childCount: _photolines.length,
                itemExtentBuilder: (index, dimensions) {
                  final p = _photolines[index];
                  return p.wrapHeight(
                    dimensions.crossAxisExtent,
                    dimensions.viewportMainAxisExtent,
                    p.fullScreenExpander.value,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
