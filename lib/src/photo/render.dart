part of 'photo.dart';

class _PhotolinePhotoRender extends SingleChildRenderObjectWidget {
  const _PhotolinePhotoRender({
    required this.loader,
    required this.sigma,
    required this.animation,
  });

  final PhotolineLoader loader;
  final double sigma;
  final AnimationController animation;

  @override
  _PhotolinePhotoPaint createRenderObject(BuildContext context) {
    return _PhotolinePhotoPaint(
      animation: animation,
      loader: loader,
      sigma: sigma,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _PhotolinePhotoPaint renderObject,
  ) {
    renderObject
      ..animation = animation
      .._loader = loader;
  }
}
