import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

part 'h.dart';

class HiderExampleList extends StatefulWidget {
  const HiderExampleList({super.key});

  @override
  State<HiderExampleList> createState() => _HiderExampleListState();
}

class _HiderExampleListState extends State<HiderExampleList> {
  late final ScrollSnapController _controller = ScrollSnapController(
    onRefresh: () async {},
    rebuild: rebuild,
  );

  void rebuild() => setState(() {});

  bool hidden = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100, child: Placeholder(color: Colors.amber)),
        Expanded(
          child: ScrollSnap(
            controller: _controller,
            slivers: [
              ScrollSnapRefresh(controller: _controller),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final red = index.isEven;

                    return Hider(
                      visible: !(red && hidden),
                      child: SizedBox(
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Placeholder(
                              color: red ? Colors.redAccent : Colors.cyanAccent,
                            ),
                          )),
                    );
                  },
                  childCount: 30,
                ),
              )
            ],
          ),
        ),
        SizedBox(
            height: 70,
            child: Placeholder(
              color: Colors.lightGreenAccent,
              child: CheckboxListTile(
                  title: Text(hidden ? 'Show' : 'Hide'),
                  value: hidden,
                  onChanged: (value) {
                    hidden = !hidden;
                    rebuild();
                  }),
            )),
      ],
    );
  }
}
