part of 'image.dart';

class _PhotolineImageRender extends SingleChildRenderObjectWidget {
  const _PhotolineImageRender({
    required this.loader,
    required this.sigma,
    required this.animation,
  });

  final PhotolineLoader loader;
  final double sigma;
  final AnimationController animation;

  @override
  _PhotolineImagePaint createRenderObject(BuildContext context) {
    return _PhotolineImagePaint(
      animation: animation,
      loader: loader,
      sigma: sigma,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _PhotolineImagePaint renderObject,
  ) {
    renderObject
      ..animation = animation
      .._loader = loader
      .._sigma = sigma;
  }
}
