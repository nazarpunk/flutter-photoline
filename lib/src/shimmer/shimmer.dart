import 'package:flutter/material.dart';
import 'package:photoline/src/mixin/state/rebuild.dart';
import 'package:photoline/src/shimmer/container.dart';

class PhotolineShimmer extends StatefulWidget {
  const PhotolineShimmer({
    super.key,
    required this.child,
    this.linearGradient = _shimmerGradient,
  });

  final Widget child;
  final LinearGradient linearGradient;

  @override
  State<PhotolineShimmer> createState() => _PhotolineShimmerState();
}

class _PhotolineShimmerState extends State<PhotolineShimmer>
    with StateRebuildMixin {
  late final PhotolineShimmerContainerState _container;

  @override
  void initState() {
    super.initState();
    _container = PhotolineShimmerContainer.of(context)!
      ..shimmerChanges.addListener(rebuild);
  }

  @override
  void dispose() {
    _container.shimmerChanges.removeListener(rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_container.isSized) return const SizedBox();
    final ro = context.findRenderObject();
    if (ro == null) return const SizedBox();

    final os = _container.getDescendantOffset(descendant: ro as RenderBox);

    final shimmerSize = _container.size;
    final gradient = LinearGradient(
      colors: widget.linearGradient.colors,
      stops: widget.linearGradient.stops,
      begin: widget.linearGradient.begin,
      end: widget.linearGradient.end,
      transform: _SlidingGradientTransform(_container.controller.value),
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(
          -os.dx,
          -os.dy,
          shimmerSize.width,
          shimmerSize.height,
        ),
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * 1.25 * percent, 0.0, 0.0);
}

const _shimmerGradient = LinearGradient(
  colors: [
    Color(0x91000000),
    Colors.transparent,
    Colors.transparent,
    Color(0x91000000),
  ],
  stops: [0, .3, .7, 1],
);
