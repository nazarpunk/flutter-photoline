import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/scroll/snap/snap/physics.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';
import 'package:photoline/src/scroll/snap/snap/viewport/viewport.dart';
import 'package:photoline/src/scroll/snap/widgets_bindings/observer.dart';

export 'snap/sliver/list.dart';

class ScrollSnap extends StatefulWidget {
  const ScrollSnap({
    super.key,
    required this.controller,
    required this.slivers,
    this.cacheExtent = double.infinity,
  });

  final List<Widget> slivers;
  final ScrollSnapController controller;
  final double cacheExtent;

  @override
  State<ScrollSnap> createState() => ScrollSnapState();
}

class ScrollSnapState extends State<ScrollSnap>
    with StateRebuildMixin, WidgetsBindingObserver {
  ScrollPhysics? _physics;

  ScrollSnapController get controller => widget.controller;

  final _observer = WidgetsBindingObserverEx();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(_observer);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.boxConstraints = constraints;
        _physics ??= ScrollSnapPhysics(
          parent: const AlwaysScrollableScrollPhysics(),
          controller: controller,
        );
        return NotificationListener(
          onNotification: (notification) {
            if (notification is PhotolinePointerScrollNotification) {
              if (controller.position is ScrollSnapPosition) {
                final dx = notification.event.scrollDelta.dy;
                final double velocity = (math.max(dx.abs(), 50) * dx.sign) * 10;
                (controller.position as ScrollSnapPosition).goBallistic(
                  velocity,
                );
              }
              return false;
            }

            if (notification is ScrollUpdateNotification) {
              controller.isUserDrag.value = notification.dragDetails != null;
            }
            return false;
          },
          child: PhotolineScrollable(
            controller: controller,
            physics: _physics,
            viewportBuilder: (context, position) {
              //print('😍 $position');
              return ScrollSnapViewport(
                cacheExtent: widget.cacheExtent,
                offset: position,
                children: widget.slivers,
              );
            },
          ),
        );
      },
    );
  }
}
