import 'package:flutter/material.dart';

class PhotolineAlbumPhotoDummy extends StatelessWidget {
  const PhotolineAlbumPhotoDummy({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return ClipRect(
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              height: constraints.maxHeight - 20,
              child: child,
            ),
          ),
        );
      });
}
