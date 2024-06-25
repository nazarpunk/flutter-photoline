import 'package:flutter/material.dart';

class PageViewExample extends StatefulWidget {
  const PageViewExample({super.key});

  @override
  State<PageViewExample> createState() => _PageViewExampleState();
}

class _PageViewExampleState extends State<PageViewExample>
    with TickerProviderStateMixin {
  late PageController _pageViewController;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PageView(
      /// [PageView.scrollDirection] defaults to [Axis.horizontal].
      /// Use [Axis.vertical] to scroll vertically.
      controller: _pageViewController,
      onPageChanged: _handlePageViewChanged,
      children: <Widget>[
        Center(
          child: Text('First Page', style: textTheme.titleLarge),
        ),
        Center(
          child: Text('Second Page', style: textTheme.titleLarge),
        ),
        Center(
          child: Text('Third Page', style: textTheme.titleLarge),
        ),
      ],
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    setState(() {});
  }
}
