import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/scroll/snap/controller.dart';
import 'package:photoline/src/scroll/snap/refresh/sliver.dart';

class ScrollSnapRefresh extends StatefulWidget {
  const ScrollSnapRefresh({super.key, required this.controller});

  final ScrollSnapController controller;

  @override
  State<ScrollSnapRefresh> createState() => ScrollSnapRefreshState();
}

class ScrollSnapRefreshState extends State<ScrollSnapRefresh> with StateRebuildMixin, SingleTickerProviderStateMixin {
  int viewState = 0;
  bool isWait = false;
  bool isWaitClose = false;

  int get _viewStateCurrent => isWaitClose ? 2 : viewState;

  ScrollSnapController get _controller => widget.controller;

  late final AnimationController animationController;

  Widget get _icon {
    late Widget child;
    switch (_viewStateCurrent) {
      case 2:
        child = const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFACACAC),
            backgroundColor: Color.fromRGBO(200, 200, 200, .2),
          ),
        );
      case 1:
        child = const Icon(Icons.refresh, color: Color(0xFFACACAC));
      case 0:
        child = const Icon(Icons.arrow_downward, color: Color(0xFFACACAC));
    }
    return SizedBox.square(
      key: ValueKey<int>(_viewStateCurrent),
      dimension: 24,
      child: Center(child: child),
    );
  }

  Future<void> _handleScroll() async {
    if (_controller.isUserDrag.value || isWait || viewState != 1 || isWaitClose) {
      return;
    }
    isWait = true;
    isWaitClose = true;
    viewState = 2;
    animationController
      ..stop()
      ..value = 1;
    rebuild();

    await widget.controller.onRefresh?.call();
    //if (kDebugMode) await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    viewState = 0;
    isWait = false;
    animationController.stop();
    unawaited(animationController.reverse(from: animationController.value));

    rebuild();
  }

  final double _triggerExtent = 60;

  double get overlapHeight => switch (viewState) {
    0 => animationController.value * _triggerExtent,
    1 || 2 => _triggerExtent,
    _ => 0,
  };

  int _setView(double height) {
    if (height > _triggerExtent) return 1;
    return 0;
  }

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(rebuild);

    super.initState();
    _controller.isUserDrag.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.isUserDrag.removeListener(_handleScroll);
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollSnapRefreshSliver(
    refresh: this,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        if (h == 0) {
          if (!isWait && isWaitClose) isWaitClose = false;
          return const SizedBox();
        }
        final v = _setView(h);
        if (!isWait && !isWaitClose) {
          if (viewState != v && v == 1) {
            unawaited(HapticFeedback.mediumImpact());
          }
          viewState = v;
        }

        return Center(
          child: Opacity(
            opacity: ((h - 20) / 50).clamp(0, 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: _icon,
                ),
                const SizedBox(width: 6),
                DefaultTextStyle.merge(
                  style: const TextStyle(height: 1, color: Color(0xFFACACAC)),
                  child: IndexedStack(
                    alignment: Alignment.center,
                    index: _viewStateCurrent,
                    children: const [
                      Text('Тяните чтоб обновить'),
                      Text('Отпустите чтоб обновить'),
                      Text('Обновляем...'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
