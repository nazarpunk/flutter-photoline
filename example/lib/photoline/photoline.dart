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

  @override
  void initState() {
    _controller = ScrollSnapController(
      snapLast: true,
      snapPhotolines: () => _photolines,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
    );
    _photolineHolderDragController = PhotolineHolderDragController(
      snapController: _controller,
    );

    for (int i = 0; i < 50; i++) {
      final List<Uri> l = [];
      for (int k = 0; k < 113 - i; k++) {
        l.add(PhotolineDummys.get(i, k));
      }
      _uris.add(l);
    }

    for (int i = 0; i < _uris.length; i++) {
      final c = PhotolineController(
        getUri: (index) => _uris[i][index],
        getKey: (index) => ValueKey(_uris[i][index]),
        //getWidget: (index) => const Placeholder(),
        getWidget: (index) => const SizedBox(),
        getPersistentWidgets: (data) {
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

        //bottomHeightAddition: () => 30,
      );

      c.fullScreenExpander.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      _photolines.add(c);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //if (kDebugMode) return SizedBox();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 900),
        child: LayoutBuilder(
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
                  if (kDebugMode)
                    SliverPhotolineList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => kProfileMode
                            ? _Photoline(
                                index: index,
                              )
                            : Photoline(
                                controller: _photolines[index],
                                photoStripeColor:
                                    const Color.fromRGBO(255, 255, 255, .2),
                              ),
                        childCount: 50,
                      ),
                      itemExtentBuilder: (index, dimensions) {
                        //setState(() {});
                        return lerpDouble(
                              constraints.maxWidth * .7 + 64,
                              constraints.maxHeight,
                              _photolines[index].fullScreenExpander.value,
                            )! +
                            20;
                      },
                    ),
                  if (kProfileMode)
                    SliverFixedExtentList(
                      delegate: SliverChildBuilderDelegateWithGap(
                        (context, index) => AutomaticKeepAlive(
                          child: Photoline(
                            controller: _photolines[index],
                            photoStripeColor:
                                const Color.fromRGBO(255, 255, 255, .2),
                          ),
                        ),
                        childCount: _photolines.length,
                      ),
                      //itemExtent: constraints.maxHeight,
                      itemExtent: 500,
                    ),
                  if (kProfileMode)
                    SliverSnapList(
                      controller: _controller,
                      delegate: SliverChildBuilderDelegateWithGap(
                        (context, index) => AutomaticKeepAlive(
                          child: _Child(
                            index: index,
                            constraints: constraints,
                            controller: _photolines[index],
                          ),
                        ),
                        childCount: _photolines.length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
