part of 'photoline.dart';

class _Child extends StatefulWidget {
  const _Child({
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
        SizedBox(
          width: double.infinity,
          child: PhotolineConstrainted(
            controller: widget.controller,
            constraints: widget.constraints,
            header: Photoline(
              controller: widget.controller,
              photoStripeColor: const Color.fromRGBO(255, 255, 255, .2),
            ),
            footer: ElevatedButton(
              onPressed: () {
                widget.controller.addItemUpload(0, PhotolineDummys.next());
                //widget.controller.photoline?.toPage(0);
                //print();
              },
              child: const Center(child: Text('Add')),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
