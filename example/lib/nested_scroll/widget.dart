import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

class _IconTile {
  const _IconTile(this.icon, this.color);

  final IconData icon;
  final Color color;
}

final List<_IconTile> _kTiles = () {
  const icons = <IconData>[
    Icons.star,
    Icons.favorite,
    Icons.bolt,
    Icons.pets,
    Icons.music_note,
    Icons.sunny,
    Icons.water_drop,
    Icons.rocket_launch,
    Icons.local_fire_department,
    Icons.forest,
    Icons.diamond,
    Icons.anchor,
    Icons.bug_report,
    Icons.cake,
    Icons.extension,
    Icons.fingerprint,
    Icons.gavel,
    Icons.headphones,
    Icons.icecream,
    Icons.key,
  ];
  final rng = Random(42);
  return List.generate(icons.length, (i) {
    final color = Color.fromARGB(
      255,
      50 + rng.nextInt(180),
      50 + rng.nextInt(180),
      50 + rng.nextInt(180),
    );
    return _IconTile(icons[i], color);
  });
}();

class NestedScrollWidgetExample extends StatefulWidget {
  const NestedScrollWidgetExample({super.key});

  @override
  State<NestedScrollWidgetExample> createState() => _State();
}

class _State extends State<NestedScrollWidgetExample> {
  late final PageController _pageController;
  int _currentPage = 0;

  final _headerController = ScrollSnapHeaderController(
    initialState: ScrollSnapHeaderInitialState.collapsed,
  );

  late final ScrollSnapController _c0 = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (i, _) => i < 30 ? 60.0 : null,
    //onRefresh: () => _onRefresh('Tab 0'),
  );

  late final ScrollSnapController _c1 = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (i, _) => i < 30 ? 60.0 : null,
    //onRefresh: () => _onRefresh('Tab 1'),
  );

  Future<void> _onRefresh(String tab) async {
    debugPrint('🔄 Pull-to-refresh triggered on $tab');
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('✅ Refresh complete on $tab');
  }

  late final List<ScrollSnapController> _controllers = [_c0, _c1];

  ScrollSnapController get _activeController => _controllers[_currentPage];

  @override
  void initState() {
    super.initState();
    _headerController.activeScrollController = _activeController;
    _pageController = PageController();
    _pageController.addListener(() {
      final p = _pageController.page?.round() ?? 0;
      if (p != _currentPage) {
        setState(() => _currentPage = p);
        _headerController.activeScrollController = _activeController;
      }
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
    return ScrollSnapHeader(
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

class _Header extends StatefulWidget {
  const _Header({
    required this.controller,
    required this.currentPage,
    required this.onTabTap,
  });

  final ScrollSnapHeaderController controller;
  final int currentPage;
  final ValueChanged<int> onTabTap;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller.height,
      builder: (context, _) => ColoredBox(
        color: Colors.blueGrey.shade900,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: widget.controller.height.value,
            child: Column(
              children: [
                // ── Counter button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _counter++),
                        icon: const Icon(Icons.add),
                        label: Text('Clicks: $_counter'),
                      ),
                    ],
                  ),
                ),
                // ── Expander: pushes tiles & tabs to the bottom ──
                const Spacer(),
                // ── Icon tiles (fixed 60×60) ──
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _kTiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final tile = _kTiles[i];
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: tile.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(tile.icon, color: Colors.white, size: 28),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // ── Tabs ──
                Row(
                  children: List.generate(2, (i) {
                    final sel = i == widget.currentPage;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onTabTap(i),
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
        if (kProfileMode) ScrollSnapRefresh(controller: widget.controller),
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
