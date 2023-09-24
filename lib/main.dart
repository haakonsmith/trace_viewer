import 'package:flutter/material.dart';
import 'package:trace_viewer/pages/trace_scaffold.dart';

void main() {
  runApp(const TraceViewerApp());
}

class TraceViewerApp extends StatelessWidget {
  const TraceViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const TraceScaffold(),
    );
  }
}
