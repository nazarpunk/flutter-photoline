import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:photoline/src/scroll/snap/header/controller.dart';

class ScrollSnapHeader extends StatefulWidget {
  const ScrollSnapHeader({
    required this.header,
    required this.content,
    required this.controller,
    this.onRefresh,
    this.refreshTriggerExtent = 80.0,
    super.key,
  });

  final Widget header;
  final Widget content;
  final ScrollSnapHeaderController controller;

  /// If provided, enables pull-to-refresh when overscrolled past the
  /// fully-expanded header.
  final RefreshCallback? onRefresh;

  /// How far (in logical pixels) the user must pull past the expanded header
  /// to trigger a refresh.
  final double refreshTriggerExtent;

  @override
  State<ScrollSnapHeader> createState() => _ScrollSnapHeaderState();
}

class _ScrollSnapHeaderState extends State<ScrollSnapHeader>
    with TickerProviderStateMixin {
  Drag? _drag;

  // ── Refresh state ────────────────────────────────────────────────────────

  /// How far the user has pulled the refresh indicator (logical pixels).
  double _refreshPull = 0.0;

  /// Whether the pull has passed the trigger threshold.
  bool _armed = false;

  /// Whether we are currently awaiting the onRefresh future.
  bool _refreshing = false;

  /// True while the user is actively dragging and we are consuming pull
  /// towards the refresh indicator (header already fully expanded, scroll at
  /// minimum).
  bool _pullingRefresh = false;

  late final AnimationController _spinAnim;

  /// Collapse animation for dismissing the indicator after refresh or when
  /// released without arming.
  late final AnimationController _collapseAnim;

  @override
  void initState() {
    super.initState();
    widget.controller.canRefresh = widget.onRefresh != null;
    _spinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _collapseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_onCollapseTick);
  }

  @override
  void didUpdateWidget(ScrollSnapHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.canRefresh = widget.onRefresh != null;
  }

  @override
  void dispose() {
    _collapseAnim.removeListener(_onCollapseTick);
    _collapseAnim.dispose();
    _spinAnim.dispose();
    super.dispose();
  }

  bool get _canRefresh => widget.onRefresh != null;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Whether the active scroll position is at (or past) its minimum extent
  /// AND the header is fully expanded – i.e. the user can start pulling the
  /// refresh indicator.
  bool get _isAtTop {
    final hc = widget.controller;
    if (hc.height.value < hc.maxHeight - 0.5) return false;
    final sc = hc.activeScrollController;
    if (sc == null || !sc.hasClients) return true;
    final pos = sc.position;
    if (!pos.hasContentDimensions) return true;
    return pos.pixels <= pos.minScrollExtent + 0.5;
  }

  // ── Gesture handlers ────────────────────────────────────────────────────

  void _onVerticalDragStart(DragStartDetails details) {
    if (_refreshing) return; // Ignore new gestures while refreshing.
    _pullingRefresh = false;

    final sc = widget.controller.activeScrollController;
    if (sc == null || !sc.hasClients) return;

    _drag = sc.position.drag(
      DragStartDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        sourceTimeStamp: details.sourceTimeStamp,
      ),
      () => _drag = null,
    );
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_refreshing) return;

    final double dy = details.primaryDelta ?? 0.0;

    // Pulling down (dy > 0).
    if (dy > 0 && _canRefresh && _isAtTop) {
      // We've reached the top – start (or continue) feeding the refresh
      // indicator instead of the scroll position.
      if (!_pullingRefresh) {
        // Cancel the scroll drag so the list doesn't overscroll.
        _drag?.cancel();
        _drag = null;
        _pullingRefresh = true;
      }
    }

    if (_pullingRefresh) {
      // Apply rubber-band friction so the indicator doesn't grow linearly.
      final double friction =
          (1.0 - (_refreshPull / (widget.refreshTriggerExtent * 3.0))
                  .clamp(0.0, 0.8));
      final double consumed = dy * friction;

      final double newPull = (_refreshPull + consumed).clamp(0.0, double.infinity);

      final wasArmed = _armed;
      setState(() {
        _refreshPull = newPull;
        _armed = _refreshPull >= widget.refreshTriggerExtent;
        if (_armed && !wasArmed) {
          unawaited(HapticFeedback.mediumImpact());
        }
      });

      // If user drags back up past zero, re-engage the scroll drag.
      if (_refreshPull <= 0.0) {
        _pullingRefresh = false;
        _refreshPull = 0.0;
        _armed = false;
        // Re-start the scroll drag so the list scrolls normally.
        final sc = widget.controller.activeScrollController;
        if (sc != null && sc.hasClients) {
          _drag = sc.position.drag(
            DragStartDetails(
              globalPosition: details.globalPosition,
            ),
            () => _drag = null,
          );
        }
      }
      return;
    }

    _drag?.update(details);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_refreshing) return;

    if (_pullingRefresh) {
      _pullingRefresh = false;
      if (_canRefresh && _armed) {
        unawaited(_doRefresh());
      } else {
        _collapseIndicator();
      }
      return;
    }

    _drag?.end(details);
    _drag = null;
  }

  void _onVerticalDragCancel() {
    if (_pullingRefresh) {
      _pullingRefresh = false;
      if (!_refreshing) {
        _collapseIndicator();
      }
      return;
    }
    _drag?.cancel();
    _drag = null;
  }

  // ── Collapse animation ──────────────────────────────────────────────────

  double _collapseFrom = 0.0;

  void _collapseIndicator() {
    _collapseFrom = _refreshPull;
    _collapseAnim.forward(from: 0.0);
  }

  void _onCollapseTick() {
    final t = Curves.easeOut.transform(_collapseAnim.value);
    setState(() {
      _refreshPull = _collapseFrom * (1.0 - t);
      _armed = false;
      if (_collapseAnim.isCompleted) {
        _refreshPull = 0.0;
      }
    });
  }

  // ── Refresh flow ─────────────────────────────────────────────────────────

  Future<void> _doRefresh() async {
    setState(() {
      _refreshing = true;
      // Lock the indicator at the trigger extent for a clean look.
      _refreshPull = widget.refreshTriggerExtent;
    });
    unawaited(_spinAnim.repeat());

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        _spinAnim.stop();
        setState(() {
          _refreshing = false;
          _armed = false;
        });
        // Smoothly collapse the indicator.
        _collapseIndicator();
      }
    }
  }

  // ── Refresh indicator widget ─────────────────────────────────────────────

  Widget _buildRefreshIndicator() {
    final progress =
        (_refreshPull / widget.refreshTriggerExtent).clamp(0.0, 1.0);
    final opacity = ((_refreshPull - 8) / 24).clamp(0.0, 1.0);

    return SizedBox(
      height: _refreshPull,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: _RefreshIcon(
            progress: progress,
            armed: _armed,
            refreshing: _refreshing,
            spinAnimation: _spinAnim,
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ScrollSnapHeaderMultiChild(
      controller: widget.controller,
      refreshPull: _refreshPull,
      header: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: _onVerticalDragCancel,
        child: widget.header,
      ),
      refreshIndicator:
          _canRefresh && _refreshPull > 0 ? _buildRefreshIndicator() : null,
      content: widget.content,
    );
  }
}

// ==================================================================================================================

class ScrollSnapHeaderMultiChild extends MultiChildRenderObjectWidget {
  ScrollSnapHeaderMultiChild({
    super.key,
    required this.header,
    required this.content,
    required this.controller,
    this.refreshIndicator,
    this.refreshPull = 0.0,
  }) : super(children: [
          content,
          if (refreshIndicator != null) refreshIndicator,
          header,
        ]);

  final Widget header;
  final Widget content;
  final Widget? refreshIndicator;
  final ScrollSnapHeaderController controller;
  final double refreshPull;

  @override
  ScrollSnapScrollHeaderRenderBox createRenderObject(BuildContext context) =>
      ScrollSnapScrollHeaderRenderBox(
        controller: controller,
        refreshPull: refreshPull,
      );

  @override
  void updateRenderObject(
      BuildContext context, ScrollSnapScrollHeaderRenderBox renderObject) {
    renderObject.refreshPull = refreshPull;
  }
}

class ScrollSnapScrollHeaderRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  ScrollSnapScrollHeaderRenderBox({
    required this.controller,
    double refreshPull = 0.0,
  }) : _refreshPull = refreshPull;

  @override
  void attach(PipelineOwner owner) {
    controller.height.addListener(markNeedsLayout);
    super.attach(owner);
  }

  @override
  void detach() {
    controller.height.removeListener(markNeedsLayout);
    super.detach();
  }

  ScrollSnapHeaderController controller;

  double get refreshPull => _refreshPull;
  double _refreshPull;

  set refreshPull(double value) {
    if (value == _refreshPull) return;
    _refreshPull = value;
    markNeedsLayout();
  }

  /// Children order: [content, (refreshIndicator)?, header]
  /// firstChild = content, lastChild = header
  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  /// The optional refresh indicator is between content and header.
  RenderBox? get _refreshBox {
    final next =
        (_contentBox.parentData! as MultiChildLayoutParentData).nextSibling;
    return next == _headerBox ? null : next;
  }

  @override
  void performLayout() {
    final c = constraints.loosen();

    // Layout header at its natural height (no stretching for refresh).
    _headerBox.layout(
      c.copyWith(maxHeight: controller.height.value),
      parentUsesSize: true,
    );

    // Layout the optional refresh indicator if present.
    final refreshBox = _refreshBox;
    if (refreshBox != null) {
      refreshBox.layout(
        c.copyWith(
          minHeight: _refreshPull,
          maxHeight: _refreshPull,
        ),
        parentUsesSize: true,
      );
    }

    _contentBox.layout(c, parentUsesSize: true);

    final width = c.constrainWidth(
      math.max(c.minWidth, _contentBox.size.width),
    );
    final height = c.constrainHeight(
      math.max(c.minHeight, _contentBox.size.height),
    );
    size = Size(width, height);

    // Content stays at top (0,0).
    (_contentBox.parentData! as MultiChildLayoutParentData).offset =
        Offset.zero;

    // Header is on top.
    (_headerBox.parentData! as MultiChildLayoutParentData).offset =
        Offset.zero;

    // Refresh indicator sits right below the header.
    if (refreshBox != null) {
      (refreshBox.parentData! as MultiChildLayoutParentData).offset =
          Offset(0, _headerBox.size.height);
    }
  }

  @override
  void setupParentData(RenderObject child) {
    super.setupParentData(child);
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _contentBox.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _contentBox.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _contentBox.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _contentBox.getMaxIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result as BoxHitTestResult, position: position);

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

// ══════════════════════════════════════════════════════════════════════════════
// Text-free refresh indicator icon
// ══════════════════════════════════════════════════════════════════════════════

class _RefreshIcon extends StatelessWidget {
  const _RefreshIcon({
    required this.progress,
    required this.armed,
    required this.refreshing,
    required this.spinAnimation,
  });

  /// 0..1 how far the user has pulled towards the trigger threshold.
  final double progress;
  final bool armed;
  final bool refreshing;
  final Animation<double> spinAnimation;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;

    if (refreshing) {
      return AnimatedBuilder(
        animation: spinAnimation,
        builder: (_, __) {
          return CustomPaint(
            size: const Size.square(size),
            painter: _SpinnerPainter(
              rotation: spinAnimation.value * 2 * math.pi,
            ),
          );
        },
      );
    }

    // Scale bounce when armed
    final scale = armed ? 1.15 : 0.7 + 0.3 * progress;

    return Transform.scale(
      scale: scale,
      child: CustomPaint(
        size: const Size.square(size),
        painter: _ArrowArcPainter(
          progress: progress,
          armed: armed,
        ),
      ),
    );
  }
}

/// Draws a circular arc-arrow that grows with [progress].
/// When [armed] the arrow is complete and highlighted.
class _ArrowArcPainter extends CustomPainter {
  _ArrowArcPainter({required this.progress, required this.armed});

  final double progress;
  final bool armed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;
    final strokeWidth = size.width * 0.09;

    final color = armed ? const Color(0xFF4CAF50) : const Color(0xFFACACAC);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track (faint ring).
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Arc sweep: from top (–π/2), sweep up to 330° based on progress.
    final sweepAngle = progress * (330 * math.pi / 180);
    if (sweepAngle > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // Arrow head at the end of the arc.
    if (progress > 0.15) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(endAngle);
      final tipY = center.dy + radius * math.sin(endAngle);
      final tip = Offset(tipX, tipY);

      final arrowLen = size.width * 0.18;
      final tangent = endAngle + math.pi / 2;
      final wing1 = Offset(
        tipX - arrowLen * math.cos(tangent - 0.5),
        tipY - arrowLen * math.sin(tangent - 0.5),
      );
      final wing2 = Offset(
        tipX - arrowLen * math.cos(tangent + 0.5),
        tipY - arrowLen * math.sin(tangent + 0.5),
      );

      final arrowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.85
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawLine(wing1, tip, arrowPaint);
      canvas.drawLine(wing2, tip, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(_ArrowArcPainter old) =>
      old.progress != progress || old.armed != armed;
}

/// Rotating arc spinner for the refreshing state.
class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.rotation});

  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;
    final strokeWidth = size.width * 0.09;

    // Faint track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x26ACACAC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Spinning arc (120°)
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation,
      2 * math.pi / 3,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.rotation != rotation;
}
