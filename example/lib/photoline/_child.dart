part of 'test.dart';

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

class _ChildState extends State<_Child> {
  @override
  void initState() {
    //print('✅ ${widget.index}');
    super.initState();
  }

  @override
  void dispose() {
    //print('❌ ${widget.index}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Photoline(
            controller: widget.controller,
            photoStripeColor: const Color.fromRGBO(255, 255, 255, .2),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.controller.addItemUpload(0, PhotolineDummys.next());
                  //widget.controller.photoline?.toPage(0);
                  //print();
                },
                child: Center(child: Text('Add ${widget.index}')),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  unawaited(pickForUpload());
                },
                child: const Center(child: Text('Upload')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  final _picker = ImagePicker();

  Future<void> pickForUpload() async {
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isEmpty) return;

    for (var i = 0; i < files.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      final pos = widget.controller.position;
      if (pos.pixels > 0) {
        unawaited(widget.controller.position.animateTo(0, duration: Duration(milliseconds: (pos.pixels * 1.5).toInt()), curve: Curves.easeIn));
      }
      widget.controller.addItemUpload(0, files[i]);
    }
  }
}
