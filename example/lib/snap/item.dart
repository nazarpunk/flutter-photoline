part of 'snap.dart';

class _Data {
  double t = 0;
  bool e = false;
}

class _Item extends StatefulWidget {
  const _Item(this.data, {required this.parent, super.key});

  final _Data data;
  final ScrollSnapController parent;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> with TickerProviderStateMixin {
  _Data get data => widget.data;

  late final _a = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200))
    ..addListener(_cb);

  void _cb() {
    data.t = _a.value;
    widget.parent.rebuild?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        data.e = !data.e;
        if (data.e) {
          _a.forward();
        } else {
          _a.reverse();
        }
      },
      child: const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Placeholder(),
      ),
    );
  }
}
