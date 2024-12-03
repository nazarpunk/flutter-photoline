part of 'photoline.dart';

class _Photoline extends StatefulWidget {
  const _Photoline({
    required this.index,
  });

  final int index;

  @override
  State<_Photoline> createState() => _PhotolineState();
}

class _PhotolineState extends State<_Photoline>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  void initState() {
    //print('init: ${widget.index}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.deepPurple,
      Colors.amberAccent,
      Colors.blue,
      Colors.deepOrange,
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('${widget.index}');
      },
      child: Placeholder(
        color: colors[widget.index % colors.length],
        child: Center(
          child: Container(
            color: Colors.brown,
            padding: const EdgeInsets.all(10),
            child: Text('${widget.index}'),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
