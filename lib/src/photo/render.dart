part of 'photo.dart';

class _PhotolinePhotoRender extends SingleChildRenderObjectWidget {
  const _PhotolinePhotoRender({
    required this.uri,
    required this.sigma,
    required this.animation,
    this.mainImageBlur,
  });

  final PhotolineUri uri;
  final double sigma;
  final AnimationController animation;
  final double? Function()? mainImageBlur;

  @override
  _PhotolinePhotoPaint createRenderObject(BuildContext context) {
    return _PhotolinePhotoPaint(
      animation: animation,
      uri: uri.cached,
      sigma: sigma,
      mainImageBlur: mainImageBlur,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _PhotolinePhotoPaint renderObject,
  ) {
    renderObject
      ..animation = animation
      .._uri = uri.cached
      ..mainImageBlur = mainImageBlur;
  }
}
