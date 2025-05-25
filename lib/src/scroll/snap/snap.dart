import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/scroll/snap/snap/physics.dart';
import 'package:photoline/src/scroll/snap/snap/position.dart';
import 'package:photoline/src/scroll/snap/snap/viewport/viewport.dart';

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

  @override
  void didChangeMetrics() {
    final media = MediaQuery.of(context);

    /// check
    if (!mounted) return;

    /// render box
    final wbox = context.findRenderObject();
    if (wbox is! RenderBox || !wbox.hasSize) return;

    final wdy = wbox.localToGlobal(Offset.zero).dy;
    final wh = wbox.size.height;

    final h = media.size.height;
    final vib = media.viewInsets.bottom;

    controller.keyboardOverlap = math.max(0, vib - h + wdy + wh);

    //print('${vib.toStringAsFixed(2)} - $h + $wdy + $wh = ${koverlap.toStringAsFixed(2)}',);

    final pos = controller.pos;

    /// focus node
    final FocusNode? activeNode = FocusManager.instance.primaryFocus;
    if (activeNode?.context == null) return;
    final fco = activeNode!.context!;
    if (fco.findAncestorStateOfType<ScrollSnapState>() != this) {
      return;
    }

    final fro = fco.findRenderObject();
    if (fro is! RenderBox || !fro.hasSize) return;

    final fdy = fro.localToGlobal(Offset.zero).dy;
    final fh = fro.size.height;

    const double gap = 20;

    final foverlap = math.max(0, vib - h + fdy + fh + gap);

    //print('${controller.keyboardOverlap.toStringAsFixed(2)} |  ${foverlap.toStringAsFixed(2)} | ${controller.pos.maxScrollExtent.toStringAsFixed(2)}',);

    if (foverlap <= 0) return;
    pos.jumpTo(pos.pixels + foverlap);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
