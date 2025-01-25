/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsSvgGen {
  const $AssetsSvgGen();

  /// Directory path: assets/svg/v2
  $AssetsSvgV2Gen get v2 => const $AssetsSvgV2Gen();
}

class $AssetsSvgV2Gen {
  const $AssetsSvgV2Gen();

  /// Directory path: assets/svg/v2/avatar
  $AssetsSvgV2AvatarGen get avatar => const $AssetsSvgV2AvatarGen();

  /// Directory path: assets/svg/v2/carousel
  $AssetsSvgV2CarouselGen get carousel => const $AssetsSvgV2CarouselGen();

  /// Directory path: assets/svg/v2/icon
  $AssetsSvgV2IconGen get icon => const $AssetsSvgV2IconGen();

  /// Directory path: assets/svg/v2/logo
  $AssetsSvgV2LogoGen get logo => const $AssetsSvgV2LogoGen();

  /// Directory path: assets/svg/v2/star
  $AssetsSvgV2StarGen get star => const $AssetsSvgV2StarGen();
}

class $AssetsSvgV2AvatarGen {
  const $AssetsSvgV2AvatarGen();

  /// File path: assets/svg/v2/avatar/support.svg
  SvgGenImage get support =>
      const SvgGenImage('assets/svg/v2/avatar/support.svg');

  /// File path: assets/svg/v2/avatar/user-deleted.svg
  SvgGenImage get userDeleted =>
      const SvgGenImage('assets/svg/v2/avatar/user-deleted.svg');

  /// File path: assets/svg/v2/avatar/user.svg
  SvgGenImage get user => const SvgGenImage('assets/svg/v2/avatar/user.svg');

  /// List of all assets
  List<SvgGenImage> get values => [support, userDeleted, user];
}

class $AssetsSvgV2CarouselGen {
  const $AssetsSvgV2CarouselGen();

  /// File path: assets/svg/v2/carousel/dummy-0.svg
  SvgGenImage get dummy0 =>
      const SvgGenImage('assets/svg/v2/carousel/dummy-0.svg');

  /// File path: assets/svg/v2/carousel/dummy-1.svg
  SvgGenImage get dummy1 =>
      const SvgGenImage('assets/svg/v2/carousel/dummy-1.svg');

  /// File path: assets/svg/v2/carousel/dummy-2.svg
  SvgGenImage get dummy2 =>
      const SvgGenImage('assets/svg/v2/carousel/dummy-2.svg');

  /// File path: assets/svg/v2/carousel/top100-user-star.svg
  SvgGenImage get top100UserStar =>
      const SvgGenImage('assets/svg/v2/carousel/top100-user-star.svg');

  /// List of all assets
  List<SvgGenImage> get values => [dummy0, dummy1, dummy2, top100UserStar];
}

class $AssetsSvgV2IconGen {
  const $AssetsSvgV2IconGen();

  /// File path: assets/svg/v2/icon/camera_circle.svg
  SvgGenImage get cameraCircle =>
      const SvgGenImage('assets/svg/v2/icon/camera_circle.svg');

  /// File path: assets/svg/v2/icon/photo.svg
  SvgGenImage get photo => const SvgGenImage('assets/svg/v2/icon/photo.svg');

  /// File path: assets/svg/v2/icon/realIcon1.svg
  SvgGenImage get realIcon1 =>
      const SvgGenImage('assets/svg/v2/icon/realIcon1.svg');

  /// File path: assets/svg/v2/icon/realIcon2.svg
  SvgGenImage get realIcon2 =>
      const SvgGenImage('assets/svg/v2/icon/realIcon2.svg');

  /// List of all assets
  List<SvgGenImage> get values => [cameraCircle, photo, realIcon1, realIcon2];
}

class $AssetsSvgV2LogoGen {
  const $AssetsSvgV2LogoGen();

  /// File path: assets/svg/v2/logo/logo.svg
  SvgGenImage get logo => const SvgGenImage('assets/svg/v2/logo/logo.svg');

  /// List of all assets
  List<SvgGenImage> get values => [logo];
}

class $AssetsSvgV2StarGen {
  const $AssetsSvgV2StarGen();

  /// File path: assets/svg/v2/star/star-10-confirm.svg
  SvgGenImage get star10Confirm =>
      const SvgGenImage('assets/svg/v2/star/star-10-confirm.svg');

  /// List of all assets
  List<SvgGenImage> get values => [star10Confirm];
}

class Assets {
  Assets._();

  static const $AssetsSvgGen svg = $AssetsSvgGen();
}

class SvgGenImage {
  const SvgGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = false;

  const SvgGenImage.vec(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
