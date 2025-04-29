import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class NestedScrollWidgetExample extends StatefulWidget {
  const NestedScrollWidgetExample({super.key});

  @override
  State<NestedScrollWidgetExample> createState() =>
      _NestedScrollWidgetExampleState();
}

class _NestedScrollWidgetExampleState extends State<NestedScrollWidgetExample> {
  late PageController _pageViewController;

  late final ScrollSnapController _ca;
  late final ScrollSnapController _cb;

  final headerController = ScrollSnapHeaderController();

  @override
  void initState() {
    _ca = ScrollSnapController(headerHolder: headerController);
    _cb = ScrollSnapController(headerHolder: headerController);

    _pageViewController = PageController(viewportFraction: .5);
    super.initState();
  }

  /// [NestedScrollView]
  @override
  Widget build(BuildContext context) {
    /*
    final delegate = SliverChildBuilderDelegate(
      (context, index) => Container(
        padding: const EdgeInsets.all(40),
        color: Colors.lightBlue[100 * (index % 9)],
        child: Center(child: Text('Test! $index')),
      ),
      childCount: 50,
    );

     */
    return ScrollSnapHeaderMultiChild(
      header: IgnorePointer(
        ignoring: false,
        child: ColoredBox(
          color: Colors.teal,
          child: SizedBox.expand(
            child: Placeholder(
              color: Colors.red,
              child: Column(
                children: [
                  //NestedScrollView(headerSliverBuilder: headerSliverBuilder, body: body),
                  const Expanded(child: SizedBox()),
                  ElevatedButton(
                    onPressed: () {
                      //print('tap');
                    },
                    child: const Text('button'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      controller: headerController,
      content: PageView(
        controller: _pageViewController,
        padEnds: false,
        children: [
          _KeepAlive(
            child: ScrollSnap(
              controller: _ca,
              slivers: const [
                //SliverSnapList(controller: _ca, delegate: delegate),
              ],
            ),
          ),
          _KeepAlive(
            child: ScrollSnap(
              controller: _cb,
              slivers: const [
                //SliverSnapList(controller: _cb, delegate: delegate),
              ],
            ),
          ),
          const ColoredBox(
            color: Colors.redAccent,
            child: Center(
              child: Text('Third Page'),
            ),
          ),
        ],
      ),
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
