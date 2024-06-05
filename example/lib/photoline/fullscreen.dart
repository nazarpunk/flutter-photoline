import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline_example/photoline/dummy.dart';

class PhotolineTestFullscreenWidget extends StatefulWidget {
  const PhotolineTestFullscreenWidget({super.key});

  @override
  State<PhotolineTestFullscreenWidget> createState() =>
      _PhotolineTestFullscreenWidgetState();
}

class _PhotolineTestFullscreenWidgetState
    extends State<PhotolineTestFullscreenWidget> {
  late final PhotolineController _photoline;

  @override
  void initState() {
    _photoline = PhotolineController(
      getUri: (index) => PhotolineDummys.get(0, index),
      getKey: ValueKey.new,
      //getWidget: (index) => const Placeholder(),
      getWidget: (index) => const SizedBox(),
      //getPersistentWidgets: (index) => [const Placeholder()],
      getPhotoCount: () => 10,
      bottomHeightAddition: () => 30,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return Photoline(controller: _photoline);
      });
}
