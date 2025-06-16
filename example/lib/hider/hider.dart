// ignore_for_file: invalid_use_of_protected_member

part of 'screen.dart';

class Hider extends StatefulWidget {
  const Hider({
    required this.index,
    super.key,
    this.visible = true,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.bottomCenter,
    this.color = Colors.transparent,
    this.duration = const Duration(milliseconds: kDebugMode ? 1000 : 200),
    this.onUpdate,
    this.statusListener,
    this.scrollExpand = false,
    this.parentContext,
  });

  final int index;

  final bool visible;
  final Widget child;
  final EdgeInsets padding;
  final AlignmentGeometry alignment;
  final Color color;
  final Duration duration;
  final ValueChanged<double>? onUpdate;
  final AnimationStatusListener? statusListener;
  final bool scrollExpand;
  final BuildContext? parentContext;

  @override
  State<Hider> createState() => HiderState();
}

class HiderState extends State<Hider>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animation;
  final GlobalKey _key = GlobalKey();

  final _curve = Curves.easeInOut;

  void _statusListener(AnimationStatus status) {
    widget.statusListener?.call(status);
    if (status != AnimationStatus.completed || !widget.scrollExpand) {
      return;
    }
  }

  @override
  void initState() {
    _animation = AnimationController(
      duration: widget.duration,
      vsync: this,
    )
      ..value = widget.visible ? 1 : 0
      ..addListener(() {
        if (widget.scrollExpand && _scrollable != null) {
          final sb = _scrollable?.context.findRenderObject()! as RenderBox?;
          final hb = _key.currentContext?.findRenderObject() as RenderBox?;
          if (sb != null && hb != null) {
            final av = _curve.transform(_animation.value);
            final so = sb.localToGlobal(Offset.zero);
            final ho = hb.localToGlobal(Offset.zero);

            final sbb = so.dy + sb.size.height;
            final h = hb.size.height * av;
            final hbb = ho.dy + h;
            final p = _scrollable!.position;

            switch (_animation.status) {
              case AnimationStatus.dismissed:
              case AnimationStatus.reverse:
                break;
              case AnimationStatus.forward:
              case AnimationStatus.completed:
                final dy = hbb - sbb;
                if (dy > 0) {
                  unawaited(p.animateTo(
                    p.pixels + dy,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.linear,
                  ));
                }
            }
          }
        }

        widget.onUpdate?.call(_animation.value);

        setState(() {});
      })
      ..addStatusListener(_statusListener);

    super.initState();
  }

  ScrollableState? _scrollable;

  @override
  void didChangeDependencies() {
    _scrollable = Scrollable.maybeOf(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  double _dh = 0;
  bool _topless = false;
  bool _opening = false;

  bool get _open => widget.visible;

  void _skip() {
    if (_open) {
      _animation.forward(from: 1);
    } else {
      _animation.reverse(from: 0);
    }
  }

  bool _shortAnim() {
    _dh = 0;
    _topless = false;
    final s = _scrollable;
    if (s == null) return false;

    final srb = s.context.findRenderObject() as RenderBox?;
    if (srb == null || !srb.attached) return false;

    final hrb = _key.currentContext?.findRenderObject() as RenderBox?;

    if (hrb == null || !hrb.attached) return false;

    final h = hrb.size.height;
    final ho = hrb.localToGlobal(Offset.zero, ancestor: srb);

    final p = s.position.pixels;
    final t = ho.dy;
    final b = t + h;

    _topless = b < 0;
    final dn = t > srb.size.height;

    final i = widget.index;
    final a = _animation;
    print(
        '🔥 $i |  $_open | $_opening | ${a.status.name} | ${a.value.toStringAsFixed(2)}');

    final List<HiderState> hiders = [];
    context.visitAncestorElements((e) {
      if (e is StatefulElement && e.state is HiderState) {
        hiders.add(e.state as HiderState);
      }
      return true;
    });

    for (final s in hiders) {
      final si = s.widget.index;
      final sa = s._animation;

      print(
          '💩 $si | ${s._open} | ${s._opening} | ${sa.status.name} | ${sa.value.toStringAsFixed(2)} ');

      switch (sa.status) {
        case AnimationStatus.completed:
        case AnimationStatus.dismissed:
          //print('💋 $i | $si');
          //_skip();
          //return true;
          break;

        case AnimationStatus.forward:
          //print('✅ $i | $si');
          _skip();
          return true;

        case AnimationStatus.reverse:
          return true;
      }
    }

    if (!_topless && !dn) return false;

    double dh = _open ? h : -h;

    for (final s in hiders) {
      if (!_topless) return false;

      //final si = s.widget.index;

      //print('💩 ${s.widget.index} | ${s._dh} | $_open | ${s._open} | ${s._opening} | ${s._updated}');

      //print('$si | ${s._open} | ${s._opening}');

      if (_open) {
        if (s._opening && s._dh == 0) {
          dh = 0;
          return false;
        }
      } else {
        if (!s._topless) {
          return true;
        }

        if (!s._open) {
          dh = 0;
        }
      }

      return true;
    }

    _skip();
    if (!_topless) return true;

    _dh = dh;

    if (dh != 0) s.position.forcePixels(p + dh);
    return true;
  }

  @override
  void didUpdateWidget(covariant Hider oldWidget) {
    super.didUpdateWidget(oldWidget);

    _opening = false;

    if (!mounted || widget.visible == oldWidget.visible) {
      return;
    }

    _opening = widget.visible;

    if (_shortAnim()) {
      return;
    }

    final isa = _animation.isAnimating;

    if (widget.visible) {
      _animation.forward(from: isa ? null : 0);
    } else {
      _animation.reverse(from: isa ? null : 1);
    }

    if (kDebugMode) return;

    if (widget.visible) {
      if (widget.scrollExpand &&
          _scrollable != null &&
          widget.parentContext != null) {
        final sb = _scrollable?.context.findRenderObject()! as RenderBox?;
        final pb = widget.parentContext?.findRenderObject() as RenderBox?;
        final p = _scrollable!.position;
        if (sb != null && pb != null) {
          final so = sb.localToGlobal(Offset.zero);
          final po = pb.localToGlobal(Offset.zero);
          final dy = po.dy - so.dy;
          if (dy < 0) {
            unawaited(p.animateTo(
              p.pixels + dy,
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
            ));
          }
        }
      }
      _animation.forward();
    } else {
      _animation.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ClipRect(
      child: Align(
        alignment: widget.alignment,
        heightFactor: _curve.transform(_animation.value),
        child: Opacity(
          key: _key,
          opacity: _animation.value.clamp(0, 1),
          child: ColoredBox(
            color: widget.color,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
