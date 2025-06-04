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

  bool _shortAnim() {
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

    final up = b < 0;
    final dn = t > srb.size.height;

    if (!up && !dn) return false;

    if (widget.visible) {
      _animation.forward(from: 1);
      // ignore: invalid_use_of_protected_member
      if (up) s.position.forcePixels(p + h);
    } else {
      // ignore: invalid_use_of_protected_member
      if (up) s.position.forcePixels(p - h);
      _animation.reverse(from: 0);
    }

    setState(() {});

    return true;
  }

  @override
  void didUpdateWidget(covariant Hider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!mounted || widget.visible == oldWidget.visible) {
      return;
    }

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

    final Widget child = ClipRect(
      child: Align(
        alignment: widget.alignment,
        heightFactor: _curve.transform(_animation.value),
        child: Opacity(
          opacity: _animation.value.clamp(0, 1),
          child: ColoredBox(
            key: _key,
            color: widget.color,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    return child;
  }

  @override
  bool get wantKeepAlive => true;
}
