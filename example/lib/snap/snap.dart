import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class SnapExampleList extends StatefulWidget {
  const SnapExampleList({super.key});

  @override
  State<SnapExampleList> createState() => _SnapExampleListState();
}

class _SnapExampleListState extends State<SnapExampleList> {
  final _max = 10;

  late final ScrollSnapController _controller = ScrollSnapController(
    snapBuilder: (index, dimensions) {
      if (index >= _max) return null;
      return 100;
    },
    snapLast: true,
    onRefresh: () async {},
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100, child: Placeholder(color: Colors.red)),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            _controller.boxConstraints = constraints;
            return ScrollSnap(
              controller: _controller,
              slivers: [
                ScrollSnapRefresh(controller: _controller),
                SliverSnapList(
                  controller: _controller,
                  builder: (context, index) {
                    final k = ValueKey<int>(Object.hash(index, true));
                    return AutomaticKeepAlive(
                      key: k,
                      child: const Placeholder(),
                    );
                  },
                  childCount: _max,
                )
              ],
            );
          }),
        ),
        const SizedBox(height: 70, child: Placeholder(color: Colors.purple)),
      ],
    );
  }
}
