import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoline/photoline.dart';

class PhotolinePhotoWidget extends StatefulWidget {
  const PhotolinePhotoWidget({super.key});

  @override
  State<PhotolinePhotoWidget> createState() => _PhotolinePhotoWidgetState();
}

class _PhotolinePhotoWidgetState extends State<PhotolinePhotoWidget> {
  Future<void> _response() async {
    final response =
        await http.get(Uri.parse('https://venus.agency/api/miss/leaders'));

    final map = jsonDecode(response.body)[0]['avatar'];

    _uri = PhotolineUri(
      uri: Uri.parse(map['src'] as String),
      color: Colors.deepPurple,
    );

    //_uri!.blur = await decodeImageFromList(map['blur'] as Uint8List);

    if (mounted) setState(() {});
    return;
  }

  PhotolineUri? _uri;

  @override
  void initState() {
    unawaited(_response());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 200,
        child: PhotolinePhoto(
          uri: _uri,
        ),
      ),
    );
  }
}
