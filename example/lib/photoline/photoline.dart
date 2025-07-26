import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/generated/assets.gen.dart';
import 'package:photoline_example/photoline/dummy.dart';

part '_child.dart';

part '_photoline.dart';

final List<Widget> dummys = [
  Assets.svg.v2.carousel.dummy0.svg(),
  Assets.svg.v2.carousel.dummy1.svg(),
  Assets.svg.v2.carousel.dummy2.svg(),
];

class PhotolineTestWidget extends StatefulWidget {
  const PhotolineTestWidget({super.key});

  @override
  State<PhotolineTestWidget> createState() => _PhotolineTestWidgetState();
}

class _PhotolineTestWidgetState extends State<PhotolineTestWidget> {
  final List<PhotolineController> _photolines = [];
  int _start = -1;

  void _reload() {
    _start++;
    while (_photolines.isNotEmpty) {
      _photolines.removeLast().dispose();
    }

    for (int i = _start; i < 50; i++) {
      final photos = PhotolineDummys.list(i);

      _photolines.add(PhotolineController(
        getUri: (index) {
          return PhotolineUri(
            uri: photos[index],
            stripe: const Color.fromRGBO(10, 10, 10, .5),
          );
        },
        getKey: (index) => ValueKey(Object.hash(_start, i, index)),
        //getWidget: (index) => const Placeholder(),
        getWidget: (index) => const SizedBox(),
        getPersistentWidgets: (data) {
          //if (kDebugMode) return [];

          final List<Widget> out = [
            ColoredBox(
              color: Color.lerp(Colors.transparent, const Color.fromRGBO(0, 0, 0, .7), 1 - data.closeDw)!,
              child: const SizedBox.expand(),
            ),
            Center(
              child: ColoredBox(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${data.index}| ${data.closeDw.toStringAsFixed(2)}'),
                ),
              ),
            )
          ];

          if (data.dragging) {
            out.add(const Placeholder());
          }

          return out;
        },
        getPhotoCount: () => photos.length,
        onAdd: (index, data) {
          photos.insert(index, data as Uri);
        },
        onRemove: photos.removeAt,
        onReorder: photos.reorder,
        getBackside: (index, show) {
          if (kDebugMode) return const SizedBox();

          return PhotolineStripe(
            stripeColor: const Color.fromRGBO(10, 10, 10, .5),
            child: AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: PhotolineAlbumPhotoDummy(
                child: SizedBox(
                  width: 500,
                  height: 1,
                  child: dummys[index % dummys.length],
                ),
              ),
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
      ));
    }
  }

  @override
  void initState() {
    _reload();
    super.initState();
  }

  late final ScrollSnapController _snap = ScrollSnapController(
    snapLastMax: true,
    snapGap: 20,
    snapArea: true,
    onRefresh: () async {
      await Future.delayed(const Duration(milliseconds: 500));
      _reload();
      setState(() {});
    },
    snapCan: (index, dimensions) {
      final p = _photolines.elementAtOrNull(index);
      if (p == null) return null;
      final w = dimensions.crossAxisExtent;
      final h = dimensions.viewportMainAxisExtent;

      if (p.wrapHeight(w, h, 0) - 20 > h) return false;
      if (p.wrapHeight(w, h, 1) - 20 > h) return false;

      return true;
    },
    snapBuilder: (index, dimensions) {
      final p = _photolines.elementAtOrNull(index);
      if (p == null) return null;
      return p.wrapHeight(
        dimensions.crossAxisExtent,
        dimensions.viewportMainAxisExtent,
        p.fullScreenExpander.value,
      );
    },
  );

  late final PhotolineHolderDragController _photolineHolderDragController = PhotolineHolderDragController(
    snapController: _snap,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 60,
          child: Placeholder(
            color: Colors.green,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: 800,
                child: PhotolineHolder(
                  dragController: _photolineHolderDragController,
                  child: ScrollSnap(
                    controller: _snap,
                    cacheExtent: .1,
                    slivers: [
                      ScrollSnapRefresh(
                        controller: _snap,
                      ),
                      SliverSnapList(
                        controller: _snap,
                        builder: (context, index) {
                          return _Child(
                            key: ValueKey(Object.hash(_start, index)),
                            controller: _photolines[index],
                            index: index,
                            constraints: constraints,
                          );
                        },
                        childCount: _photolines.length,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(
          height: 60,
          child: Placeholder(
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}
