import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoline/photoline.dart';

class PhotolinePhotoWidget extends StatefulWidget {
  const PhotolinePhotoWidget({super.key});

  @override
  State<PhotolinePhotoWidget> createState() => _PhotolinePhotoWidgetState();
}

class _PhotolinePhotoWidgetState extends State<PhotolinePhotoWidget> {
  final uris = <PhotolineUri>[];

  Future<void> _response() async {
    for (final src in [
      'https://vk.com',
      'https://irinabot.ru',
      'https://not-exists.em',
      'https://venus.agency/photo/6b714e77fcde22180ae3a7c1d798b6299854cc846b8f0a683e0ac0240429c9ee/photo',
    ]) {
      uris.add(PhotolineUri(
        uri: Uri.parse(src),
        color: Colors.deepPurple,
      ));
    }

    if (mounted) setState(() {});
    return;
  }

  @override
  void initState() {
    unawaited(_response());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: <Widget>[
        for (final u in uris) PhotolinePhoto(uri: u),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[200],
          child: const Text('Heed not the rabble'),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[300],
          child: const Text('Sound of screams but the'),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[400],
          child: const Text('Who scream'),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[500],
          child: const Text('Revolution is coming...'),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.teal[600],
          child: const Text('Revolution, they...'),
        ),
      ],
    );
  }
}
