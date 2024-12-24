part of 'photoline.dart';

class _Child extends StatefulWidget {
  const _Child({
    super.key,
    required this.index,
    required this.constraints,
    required this.controller,
  });

  final int index;
  final BoxConstraints constraints;
  final PhotolineController controller;

  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          child: Photoline(
            controller: widget.controller,
            photoStripeColor: const Color.fromRGBO(255, 255, 255, .2),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.controller.addItemUpload(0, PhotolineDummys.next());
            //widget.controller.photoline?.toPage(0);
            //print();
          },
          child: Center(child: Text('Add ${widget.index}')),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
