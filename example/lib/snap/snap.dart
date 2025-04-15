import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class SnapExampleList extends StatefulWidget {
  const SnapExampleList({super.key});

  @override
  State<SnapExampleList> createState() => _SnapExampleListState();
}

class _SnapExampleListState extends State<SnapExampleList> {
  late final ScrollSnapController _controller = ScrollSnapController(
    snap: true,
    //snapLast: true,
    onRefresh: () async {},
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100, child: Placeholder(color: Colors.red)),
        Expanded(
          child: ScrollSnap(
            controller: _controller,
            cacheExtent: double.infinity,
            slivers: [
              ScrollSnapRefresh(controller: _controller),
              SliverSnapList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SizedBox(
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Placeholder(
                        child: Center(
                          child: Text('$index'),
                        ),
                      ),
                    ),
                  ),
                  childCount: 3000000000,
                ),
                controller: _controller,
              )
            ],
          ),
        ),
        const SizedBox(height: 70, child: Placeholder(color: Colors.purple)),
      ],
    );
  }
}
