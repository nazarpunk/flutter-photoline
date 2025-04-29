import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class SnapExampleList2 extends StatefulWidget {
  const SnapExampleList2({super.key});

  @override
  State<SnapExampleList2> createState() => _SnapExampleList2State();
}

class _SnapExampleList2State extends State<SnapExampleList2> {
  late final ScrollSnapController _ca = ScrollSnapController(
      //snap: true,
      );

  late final ScrollSnapController _cb = ScrollSnapController(
      //snap: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100, child: Placeholder(color: Colors.red)),
        Expanded(
          child: ScrollSnap(
            controller: _ca,
            cacheExtent: double.infinity,
            slivers: [
              ScrollSnapRefresh(controller: _ca),
              SliverSnapList(
                controller: _ca,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 5) {
                      return const TextField();
                    }
                    return SizedBox(
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Placeholder(
                          child: Center(
                            child: Text('$index'),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 300,
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: ScrollSnap(
            controller: _cb,
            cacheExtent: double.infinity,
            slivers: [
              ScrollSnapRefresh(controller: _cb),
              SliverSnapList(
                controller: _cb,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 5) {
                      return const TextField();
                    }
                    return SizedBox(
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Placeholder(
                          child: Center(
                            child: Text('$index'),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: 300,
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 70, child: Placeholder(color: Colors.purple)),
      ],
    );
  }
}
