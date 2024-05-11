import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:photoline_example/nested_scroll/nested_widget.dart';
// ignore: unused_import
import 'package:photoline_example/photoline/photoline.dart';

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
      home: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Title')),
        //body: const NestedScrollWidgetExample(),
        body: const PhotolineTestWidget(),
      ),
    );
  }
}
