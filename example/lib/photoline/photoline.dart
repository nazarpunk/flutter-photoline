import 'package:flutter/foundation.dart';
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
  late final PhotolineHolderDragController _photolineHolderDragController;

  final List<PhotolineController> _photolines = [];

  final List<List<Uri>> _uris = [];

  @override
  void initState() {
    _controller = ScrollSnapController(
      snapLast: true,
      snapPhotolines: () => _photolines,
    );
    _photolineHolderDragController = PhotolineHolderDragController(
      snapController: _controller,
    );

    for (int i = 0; i < 12; i++) {
      final List<Uri> l = [];
      for (int k = 0; k < 13 - i; k++) {
        l.add(PhotolineDummys.get(i, k));
      }
      _uris.add(l);
    }

    for (int i = 0; i < _uris.length; i++) {
      _photolines.add(
        PhotolineController(
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

            return PhotolineAlbumPhotoDummy(
              child: Container(
                width: 500,
                height: 1,
                color: colors[index % colors.length],
              ),
              //child: Placeholder(),
            );
          },

          //bottomHeightAddition: () => 30,
        ),
      );
    }

    super.initState();
  }

  late final ScrollSnapPhotolineController _snapController =
      ScrollSnapPhotolineController();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return LayoutBuilder(builder: (context, constraints) {
        return ScrollSnapPhotoline(
          scrollDirection: Axis.vertical,
          controller: _snapController,
          slivers: [
            ScrollSnapRefresh(
              controller: _controller,
            ),
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
        );
      });
    }

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

class _ChildState extends State<_Child> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PhotolineConstrainted(
            controller: widget.controller,
            constraints: widget.constraints,
            header: Photoline(
              controller: widget.controller,
              photoStripeColor: const Color.fromRGBO(255, 255, 255, .2),
            ),
            footer: ElevatedButton(
              onPressed: () {
                widget.controller.addItemUpload(0, PhotolineDummys.next());
                //widget.controller.photoline?.toPage(0);
                //print();
              },
              child: const Center(child: Text('Add')),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
