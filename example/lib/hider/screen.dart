import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

part 'hider.dart';

class HiderExampleList extends StatefulWidget {
  const HiderExampleList({super.key});

  @override
  State<HiderExampleList> createState() => _HiderExampleListState();
}

class _HiderExampleListState extends State<HiderExampleList> {
  late final ScrollSnapController _controller = ScrollSnapController(
    onRefresh: () async {},
    rebuild: rebuild,
    freeMaxExtend: true,
  );

  void rebuild() => setState(() {});

  bool hidden = true;

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
                      key: ValueKey(index),
                      index: index,
                      visible: !(red && hidden),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    red ? Colors.redAccent : Colors.cyanAccent),
                          ),
                          child: red
                              ? Hider(
                                  //visible: !(red && hidden),
                                  index: -index - 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: SizedBox(
                                      height: red ? 100 : 50,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.purple),
                                        ),
                                        child: Center(
                                          child: Text('$index'),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 50,
                                  child: Center(
                                    child: Text('$index'),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                  childCount: 133,
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
                    print('🍒 $hidden');
                    rebuild();
                  }),
            )),
      ],
    );
  }
}
