import 'dart:isolate';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
import 'package:trace_viewer/pages/trace_view.dart';
import 'package:trace_viewer/utils/db.dart';
import 'package:trace_viewer/widgets/trace_search.dart';
import 'package:xqflite/xqflite.dart' as xqflite;

xqflite.Table buildTable(int index) {
  return xqflite.Table.builder("data_$index") //
      .primaryKey('id')
      .integer('rx_id')
      .integer('multi_line')
      .text('formatted_data')
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
  ItemScrollController? controller;
  TraceViewDataController? dataController;
  int i = 0;
  bool _ingesting = false;

  @override
  Widget build(BuildContext context) {
    final Widget view;

    if (trace == null) {
      view = const Text("Drop Here");
    } else {
      view = Stack(children: [
        TraceView(
          trace: trace!,
          controller: controller,
          dataController: dataController,
        ),
        if (_ingesting) const Positioned(child: LinearProgressIndicator()),
        if (!_ingesting)
          Positioned(
            right: 0,
            bottom: 0,
            child: TraceSearch(
              onSearch: (data) {
                // final List<CanMessage> result = [];

                // for (final message in trace!.messages) {
                //   var found = true;
                //   // var offset = -1;
                //   var startByte = -1;

                //   // for (final byte in data.data) {
                //   for (var i = 0; i < data.data.length; i++) {
                //     if (startByte == -1 && data.data[0] == message.data[i]) startByte = i;

                //     if (startByte != -1) {
                //       if (message.data[i] != data.data[i - startByte]) {
                //         found = false;
                //         break;
                //       }
                //     }
                //   }

                //   // for (final byte in message.data) {
                //   // for (var i = 0; i < message.data.length; i++) {
                //   //   if (offset > 0) {
                //   //     if (message.data[i] != data.data[i - offset]) {
                //   //       found = false;
                //   //       break;
                //   //     }
                //   //   } else {
                //   //     if (message.data[i] == data.data[0]) {
                //   //       offset = i;
                //   //     }
                //   //   }
                //   // }

                //   if (found) {
                //     result.add(message);
                //   }
                // }
                // print(result);

                // dataController?.goToItemId(result.first.messageNumber);

                XDatabase.instance
                    .data(i) //
                    .query(
                      xqflite.Query.contains(
                          'formatted_data',
                          data.data //
                              .map((e) => e.toRadixString(16).padLeft(2, '0'))
                              .join(' ')),
                    )
                    .then((value) {
                  if (value.isEmpty) return;

                  final index = value.first.messageNumber;

                  dataController?.goToItemId(index);
                });
              },
            ),
          ),
      ]);
    }

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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File contains non ascii character")));
            return;
          }

          final importer = TraceImporter.import(fileData);

          if (importer == null) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown file type")));
            return;
          }

          i++;

          final watch = Stopwatch()..start();
          await XDatabase.instance.addTable(buildTable(i));

          setState(() {
            _ingesting = true;
          });

          final (messages, _) = await importer.parseAsync();

          Isolate.run(() {
            XDatabase.instance.data(i).batch((batch) {
              for (final message in messages) {
                batch.insert(message);
              }
            }).whenComplete(() {
              if (mounted) setState(() => _ingesting = false);
            });
          });

          watch.stop();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Parsing took: ${watch.elapsedMilliseconds}ms"),
            ));
          }

          setState(() {
            trace = CanTrace(messages: messages, name: file.name);
            controller = ItemScrollController();
            dataController = TraceViewDataController();
          });
        },
        child: Center(child: view),
      ),
    );
  }
}
