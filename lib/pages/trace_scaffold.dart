import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
import 'package:trace_viewer/pages/trace_view.dart';
import 'package:trace_viewer/utils/db.dart';
import 'package:xqflite/xqflite.dart' as xqflite;

xqflite.Table buildTable(int index) {
  return xqflite.Table.builder("data_$index") //
      .primaryKey('id')
      .integer('rx_id')
      .integer('multi_line')
      .real('time_offset')
      .integer('message_number')
      .bytes('data')
      .integer('parent', nullable: true)
      .build();
}

class TraceScaffold extends StatefulWidget {
  const TraceScaffold({super.key});

  @override
  State<TraceScaffold> createState() => _TraceScaffoldState();
}

class _TraceScaffoldState extends State<TraceScaffold> {
  CanTrace? trace;
  int i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: trace == null ? const Text("No File") : Text(trace!.name),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                trace = null;
              });
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: DropTarget(
        onDragDone: (detail) async {
          final file = detail.files.firstOrNull;

          if (file == null) return;

          late final String fileData;

          try {
            fileData = await file.readAsString();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("File contains non ascii character")));
            return;
          }

          final importer = TraceImporter.import(fileData);

          if (importer == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Unknown file type")));
            return;
          }

          final watch = Stopwatch()..start();
          await XDatabase.instance.addTable(buildTable(i));

          final traceResult = importer.parse(file.name);

          for (final message in traceResult.$1.messages.take(100)) {
            await XDatabase.instance.data(i).insert(message);
          }

          i++;

          watch.stop();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Parsing took: ${watch.elapsedMilliseconds}ms"),
            ));
          }

          setState(() {
            trace = traceResult.$1;
          });
        },
        child: Center(
          child: trace == null
              ? const Text('drop here')
              : TraceView(trace: trace!),
        ),
      ),
    );
  }
}
