import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

import 'package:photoline_example/nested_scroll/app_bar.dart';

class NestedScrollWidgetExample extends StatefulWidget {
  const NestedScrollWidgetExample({super.key});

  @override
  State<NestedScrollWidgetExample> createState() =>
      _NestedScrollWidgetExampleState();
}

class _NestedScrollWidgetExampleState extends State<NestedScrollWidgetExample> {
  final List<ScrollSnapController> _controller = [];
  late PageController _pageViewController;

  @override
  void initState() {
    _controller
      ..add(ScrollSnapController())
      ..add(ScrollSnapController());
    _pageViewController = PageController(viewportFraction: .5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final delegate = SliverChildBuilderDelegate(
      (context, index) => Container(
        padding: const EdgeInsets.all(40),
        color: Colors.lightBlue[100 * (index % 9)],
        child: Center(child: Text('Test! $index')),
      ),
      childCount: 50,
    );

    return PageView(
      controller: _pageViewController,
      padEnds: false,
      children: [
        _KeepAlive(
          child: SizedBox.expand(
            child: ScrollSnap(
              controller: _controller[0],
              slivers: [
                const SliverAppBarEx(),
                SliverSnapList(
                  controller: _controller[0],
                  delegate: delegate,
                ),
              ],
            ),
          ),
        ),
        _KeepAlive(
          child: SizedBox.expand(
            child: ScrollSnap(
              controller: _controller[1],
              slivers: [
                const SliverAppBarEx(),
                SliverSnapList(
                  controller: _controller[1],
                  delegate: delegate,
                ),
              ],
            ),
          ),
        ),
        const ColoredBox(
          color: Colors.redAccent,
          child: Center(
            child: Text('Third Page'),
          ),
        ),
      ],
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({
    required this.child,
  });

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
