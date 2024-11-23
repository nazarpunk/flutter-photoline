import 'package:flutter/material.dart';
import 'package:photoline/src/scroll_snap_photoline/position.dart';

class ScrollSnapPhotolineController extends ScrollController {
  ScrollSnapPhotolineController({
    this.initialPage = 0,
    this.keepPage = true,
    super.onAttach,
    super.onDetach,
  }) ;

  final int initialPage;

  final bool keepPage;


  double? get page {
    assert(
      positions.isNotEmpty,
      'PageControllerPhotoline.page cannot be accessed before a PageView is built with it.',
    );
    assert(
      positions.length == 1,
      'The page property cannot be read when multiple PageViews are attached to '
      'the same PageControllerPhotoline.',
    );
    final ScrollSnapPhotolinePagePosition position =
        this.position as ScrollSnapPhotolinePagePosition;
    return position.page;
  }

  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    final ScrollSnapPhotolinePagePosition position =
        this.position as ScrollSnapPhotolinePagePosition;
    if (position.cachedPage != null) {
      position.cachedPage = page.toDouble();
      return Future<void>.value();
    }

    return position.animateTo(
      position.getPixelsFromPage(page.toDouble()),
      duration: duration,
      curve: curve,
    );
  }

  void jumpToPage(int page) {
    final ScrollSnapPhotolinePagePosition position =
        this.position as ScrollSnapPhotolinePagePosition;
    if (position.cachedPage != null) {
      position.cachedPage = page.toDouble();
      return;
    }

    position.jumpTo(position.getPixelsFromPage(page.toDouble()));
  }

  Future<void> nextPage({required Duration duration, required Curve curve}) {
    return animateToPage(page!.round() + 1, duration: duration, curve: curve);
  }

  Future<void> previousPage(
      {required Duration duration, required Curve curve}) {
    return animateToPage(page!.round() - 1, duration: duration, curve: curve);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return ScrollSnapPhotolinePagePosition(
      physics: physics,
      context: context,
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: 1,
      oldPosition: oldPosition,
    );
  }

}
