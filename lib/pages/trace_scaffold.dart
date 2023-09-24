import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
import 'package:trace_viewer/pages/trace_view.dart';

class TraceScaffold extends StatefulWidget {
  const TraceScaffold({super.key});

  @override
  State<TraceScaffold> createState() => _TraceScaffoldState();
}

class _TraceScaffoldState extends State<TraceScaffold> {
  CanTrace? trace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          onPressed: () {
            setState(() {
              trace = null;
            });
          },
          icon: const Icon(Icons.delete),
        ),
      ]),
      body: DropTarget(
        onDragDone: (detail) async {
          final file = detail.files.firstOrNull;

          if (file == null) return;

          final fileData = await file.readAsString();

          final importer = TraceImporter.import(fileData);

          if (importer == null) return;

          final traceResult = importer.parse();

          trace = traceResult.$1;

          setState(() {});
        },
        child: Center(
          child: trace == null ? const Text('drop here') : TraceView(trace: trace!),
        ),
      ),
    );
  }
}
