import 'package:flutter/material.dart';

// ignore: unused_import
import 'package:photoline_example/nested_scroll/nested_widget.dart';

// ignore: unused_import
import 'package:photoline_example/photoline/fullscreen.dart';

// ignore: unused_import
import 'package:photoline_example/photoline/photoline.dart';
import 'package:photoline_example/widget/scroll.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, widget) {
        return Material(
          child: MediaQuery.removePadding(
            context: context,
            child: Overlay(
              //key: AppData.overlay,
              initialEntries: [
                OverlayEntry(
                  builder: (context) => widget!,
                ),
              ],
            ),
          ),
        );
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Photoline')),
        body:
        //const PhotolineTestWidget(),
        const PhotolineTestFullscreenWidget(),
      ),
    );
  }
}
