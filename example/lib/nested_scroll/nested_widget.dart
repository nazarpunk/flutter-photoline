import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoline/library.dart';

/// Демонстрация Nested Scroll:
/// - Шапка (header) сжимается/разжимается при вертикальном скролле
///   в диапазоне [minHeight..maxHeight]
/// - Горизонтальный PageView с 3 страницами — у каждой свой вертикальный скролл
/// - Pull-to-refresh на каждой странице
class NestedScrollWidgetExample extends StatefulWidget {
  const NestedScrollWidgetExample({super.key});

  @override
  State<NestedScrollWidgetExample> createState() =>
      _NestedScrollWidgetExampleState();
}

class _NestedScrollWidgetExampleState extends State<NestedScrollWidgetExample> {
  late final PageController _pageController;
  int _currentPage = 0;

  final _headerController = ScrollSnapHeaderController();

  /// Высота одного элемента на каждой странице (snapBuilder)
  static const double _contactH = 80;
  static const double _galleryH = 160;
  static const double _settingsH = 72;

  late final ScrollSnapController _contacts = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (_, __) => _contactH,
    onRefresh: () => Future.delayed(const Duration(seconds: 1)),
  );

  late final ScrollSnapController _gallery = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (_, __) => _galleryH,
    onRefresh: () => Future.delayed(const Duration(seconds: 1)),
  );

  late final ScrollSnapController _settings = ScrollSnapController(
    headerHolder: _headerController,
    snapBuilder: (_, __) => _settingsH,
    onRefresh: () => Future.delayed(const Duration(seconds: 1)),
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
    _contacts.dispose();
    _gallery.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollSnapHeaderMultiChild(
      controller: _headerController,

      // ── Header поверх контента ──
      header: IgnorePointer(
        ignoring: false,
        child: _Header(
          controller: _headerController,
          currentPage: _currentPage,
          onTabTap: (i) => _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
      ),

      // ── Body: горизонтальный PageView ──
      content: PageView(
        controller: _pageController,
        children: [
          _KeepAlive(
            child: ScrollSnap(
              controller: _contacts,
              slivers: [
                ScrollSnapRefresh(controller: _contacts),
                SliverSnapList(
                  controller: _contacts,
                  childCount: 40,
                  builder: (_, i) => _ContactTile(index: i, height: _contactH),
                ),
              ],
            ),
          ),
          _KeepAlive(
            child: ScrollSnap(
              controller: _gallery,
              slivers: [
                ScrollSnapRefresh(controller: _gallery),
                SliverSnapList(
                  controller: _gallery,
                  childCount: 25,
                  builder: (_, i) =>
                      _GalleryCard(index: i, height: _galleryH),
                ),
              ],
            ),
          ),
          _KeepAlive(
            child: ScrollSnap(
              controller: _settings,
              slivers: [
                ScrollSnapRefresh(controller: _settings),
                SliverSnapList(
                  controller: _settings,
                  childCount: 20,
                  builder: (_, i) =>
                      _SettingsTile(index: i, height: _settingsH),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER — сжимаемая шапка
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.currentPage,
    required this.onTabTap,
  });

  final ScrollSnapHeaderController controller;
  final int currentPage;
  final ValueChanged<int> onTabTap;

  static const _tabs = ['Контакты', 'Галерея', 'Настройки'];
  static const _icons = [Icons.people, Icons.photo_library, Icons.settings];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.height,
      builder: (context, _) {
        final range = controller.maxHeight - controller.minHeight;
        final t = range > 0
            ? ((controller.height.value - controller.minHeight) / range)
                .clamp(0.0, 1.0)
            : 0.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                    const Color(0xFF0D253F), const Color(0xFF0B3D6E), t)!,
                Color.lerp(
                    const Color(0xFF1B3A5C), const Color(0xFF11477A), t)!,
              ],
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Содержимое шапки ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Аватар
                        _Avatar(progress: t),
                        const SizedBox(width: 14),
                        // Текст
                        Expanded(child: _HeaderInfo(progress: t)),
                      ],
                    ),
                  ),
                ),

                // ── Таб-бар ──
                _TabBar(
                  tabs: _tabs,
                  icons: _icons,
                  current: currentPage,
                  onTap: onTabTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 36.0 + 36.0 * progress;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
      ),
      child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nested Scroll',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 + 6 * progress,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        if (progress > 0.25) ...[
          const SizedBox(height: 4),
          Opacity(
            opacity: ((progress - 0.25) / 0.3).clamp(0.0, 1.0),
            child: const Text(
              'Шапка сжимается при скролле вниз\nи разжимается при скролле вверх',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
            ),
          ),
        ],
        if (progress > 0.65) ...[
          const SizedBox(height: 8),
          Opacity(
            opacity: ((progress - 0.65) / 0.35).clamp(0.0, 1.0),
            child: const Wrap(
              spacing: 6,
              children: [
                _Chip(icon: Icons.swap_vert, text: 'Верт. скролл'),
                _Chip(icon: Icons.swap_horiz, text: 'Гориз. свайп'),
                _Chip(icon: Icons.refresh, text: 'Pull-to-refresh'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.icons,
    required this.current,
    required this.onTap,
  });

  final List<String> tabs;
  final List<IconData> icons;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == current;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i],
                          size: 15,
                          color: sel ? Colors.white : Colors.white30),
                      const SizedBox(width: 5),
                      Text(
                        tabs[i],
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.white30,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: sel ? 32 : 0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 1 — Контакты
// ═══════════════════════════════════════════════════════════════════════════════

const _names = [
  'Алексей Петров',  'Мария Иванова',   'Дмитрий Сидоров',
  'Анна Козлова',    'Иван Новиков',    'Елена Морозова',
  'Сергей Волков',   'Ольга Лебедева',  'Николай Зайцев',
  'Татьяна Соколова','Артём Попов',     'Наталья Миронова',
  'Владимир Фёдоров','Екатерина Орлова','Андрей Кузнецов',
];

const _roles = [
  'Дизайнер',   'Разработчик', 'Менеджер',    'Аналитик',
  'Тестировщик', 'DevOps',      'Архитектор',  'Продакт',
  'Скрам-мастер','Техлид',
];

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.index, required this.height});
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    final name = _names[index % _names.length];
    final role = _roles[index % _roles.length];
    final hue = (index * 37.0) % 360;
    final color = HSLColor.fromAHSL(1, hue, 0.5, 0.35).toColor();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  child: Text(
                    name.characters.first,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(role,
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Text('#${index + 1}',
                    style: const TextStyle(color: Colors.white12, fontSize: 11)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white12, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 2 — Галерея
// ═══════════════════════════════════════════════════════════════════════════════

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.index, required this.height});
  final int index;
  final double height;

  static const _titles = ['Пейзажи', 'Портреты', 'Абстракция', 'Макро', 'Архитектура'];
  static const _icons = [
    Icons.landscape, Icons.photo_camera, Icons.palette,
    Icons.filter_vintage, Icons.location_city,
  ];

  @override
  Widget build(BuildContext context) {
    final h1 = (index * 53.0) % 360;
    final h2 = (h1 + 45) % 360;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, h1, 0.65, 0.28).toColor(),
                  HSLColor.fromAHSL(1, h2, 0.55, 0.42).toColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Декоративный круг
                const Positioned(
                  right: -16,
                  top: -16,
                  child: _Circle(size: 80, opacity: 0.07),
                ),
                const Positioned(
                  left: -12,
                  bottom: -24,
                  child: _Circle(size: 64, opacity: 0.05),
                ),
                // Контент
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_icons[index % _icons.length],
                              color: Colors.white54, size: 24),
                          const Spacer(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              child: Text('${(index + 1) * 4} фото',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _titles[index % _titles.length],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Коллекция #${index + 1}',
                        style:
                            const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 3 — Настройки
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsTile extends StatefulWidget {
  const _SettingsTile({required this.index, required this.height});
  final int index;
  final double height;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _on = false;

  static const _items = [
    (Icons.dark_mode,             'Тёмная тема',         'Оформление'),
    (Icons.notifications_active,  'Уведомления',         'Push-уведомления'),
    (Icons.cloud_sync,            'Синхронизация',       'Авто-синк данных'),
    (Icons.fingerprint,           'Биометрия',           'Вход по отпечатку'),
    (Icons.data_saver_on,         'Экономия трафика',    'Сжатие картинок'),
    (Icons.translate,             'Язык',                'Русский'),
    (Icons.storage,               'Кэш',                 'Очистка данных'),
    (Icons.security,              'Безопасность',        '2FA'),
    (Icons.speed,                 'Производительность',  'GPU-ускорение'),
    (Icons.animation,             'Анимации',            'Плавные переходы'),
    (Icons.wifi,                  'Только Wi-Fi',        'Загрузка по Wi-Fi'),
    (Icons.battery_saver,         'Энергосбережение',    'Батарея'),
    (Icons.text_fields,           'Размер текста',       'Шрифты'),
    (Icons.color_lens,            'Акцент',              'Цвет приложения'),
    (Icons.backup,                'Бэкап',               'Авто-резервирование'),
    (Icons.vpn_key,               'VPN',                 'Защита трафика'),
    (Icons.do_not_disturb,        'Не беспокоить',       'Тихий режим'),
    (Icons.location_on,           'Геолокация',          'Доступ к GPS'),
    (Icons.accessibility_new,     'Доступность',         'Специальные возможности'),
    (Icons.update,                'Обновления',          'Авто-обновление'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _items[widget.index % _items.length];
    final hue = (widget.index * 47.0) % 360;

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF222233),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: HSLColor.fromAHSL(1, hue, 0.45, 0.22).toColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.$1, color: Colors.white54, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      Text(s.$3,
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _on,
                  onChanged: (v) => setState(() => _on = v),
                  activeTrackColor: const Color(0xFF6A11CB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  KeepAlive
// ═══════════════════════════════════════════════════════════════════════════════

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
