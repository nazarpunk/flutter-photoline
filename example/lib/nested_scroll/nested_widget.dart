import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

class NestedScrollWidgetExample extends StatefulWidget {
  const NestedScrollWidgetExample({super.key});

  @override
  State<NestedScrollWidgetExample> createState() => _State();
}

class _State extends State<NestedScrollWidgetExample> {
  late final PageController _pageController;
  int _currentPage = 0;

  final _headerController = ScrollSnapHeaderController();

  late final ScrollSnapController _c0 = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (i, _) => i < 30 ? 60.0 : null,
  );

  late final ScrollSnapController _c1 = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (i, _) => i < 30 ? 60.0 : null,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final p = _pageController.page?.round() ?? 0;
      if (p != _currentPage) setState(() => _currentPage = p);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _c0.dispose();
    _c1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollSnapHeaderMultiChild(
      controller: _headerController,
      header: _Header(
        controller: _headerController,
        currentPage: _currentPage,
        onTabTap: (i) => _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      content: PageView(
        controller: _pageController,
        children: [
          _Page(controller: _c0, color: Colors.blue),
          _Page(controller: _c1, color: Colors.green),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.currentPage,
    required this.onTabTap,
  });

  final ScrollSnapHeaderController controller;
  final int currentPage;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.height,
      builder: (context, _) => ColoredBox(
        color: Colors.blueGrey.shade900,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'h = ${controller.height.value.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Row(
                children: List.generate(2, (i) {
                  final sel = i == currentPage;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabTap(i),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: sel ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Tab $i',
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white38,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class _Page extends StatefulWidget {
  const _Page({required this.controller, required this.color});

  final ScrollSnapController controller;
  final Color color;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  Widget build(BuildContext context) {
    return ScrollSnap(
      controller: widget.controller,
      slivers: [
        SliverSnapList(
          controller: widget.controller,
          childCount: 30,
          builder: (_, i) => SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ColoredBox(
                color: widget.color.withValues(alpha: 0.15 + (i % 5) * 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Item $i', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
