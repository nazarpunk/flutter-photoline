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
        //getBackside: (index) => const Placeholder(),
        getPersistentWidgets: (data) => [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    '${data.index}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
        getPhotoCount: () => 30,
        getViewCount: _minPhotoLength,
        rebuilder: () {
          if (mounted) setState(() {});
        });

    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Photoline(
                controller: _photoline,
                photoStripeColor: const Color.fromRGBO(255, 255, 255, .2),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Add'),
              ),
            )
          ],
        );
      });
}

int _minPhotoLength(double? width) => width == null
    ? 3
    : (width < 0 ? 3 : (width < 600 ? 3 : (width < 1200 ? 4 : 5)));
