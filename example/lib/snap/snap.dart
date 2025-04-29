import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class SnapExampleList extends StatefulWidget {
  const SnapExampleList({super.key});

  @override
  State<SnapExampleList> createState() => _SnapExampleListState();
}

class _SnapExampleListState extends State<SnapExampleList> {
  late final ScrollSnapController _controller = ScrollSnapController(
    //snap: true,
    snapLast: true,
    onRefresh: () async {},
  );

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      SliverPhotolineList(
        (context, index) {
          final k = ValueKey<int>(Object.hash(index, true));
          return AutomaticKeepAlive(
            key: k,
            child: const Placeholder(),
          );
        },
        childCount: 20,
        itemExtentBuilder: (index, dimensions) {
          return 150;
        },
      );
    }

    return Column(
      children: [
        const SizedBox(height: 100, child: Placeholder(color: Colors.red)),
        Expanded(
          child: ScrollSnap(
            controller: _controller,
            cacheExtent: double.infinity,
            slivers: [
              ScrollSnapRefresh(controller: _controller),
              SliverPhotolineList(
                (context, index) {
                  final k = ValueKey<int>(Object.hash(index, true));
                  return AutomaticKeepAlive(
                    key: k,
                    child: const Placeholder(),
                  );
                },
                childCount: 10,
                itemExtentBuilder: (index, dimensions) {
                  return 150;
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 70, child: Placeholder(color: Colors.purple)),
      ],
    );
  }
}
