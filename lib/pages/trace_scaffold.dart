import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
import 'package:trace_viewer/pages/trace_view.dart';
import 'package:trace_viewer/utils/db.dart';
import 'package:trace_viewer/utils/scaffold_messenger_extension.dart';
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
        Positioned(
          right: 0,
          bottom: 0,
          left: 1000,
          child: TraceSearch(
            onSearch: (data) {
              // print(
              //   data.data //
              //       .map((e) => e.toRadixString(16).padLeft(2, "0"))
              //       .join(),
              // );
              XDatabase.instance
                  .data(i) //
                  .query(
                    xqflite.Query.contains(
                        // 'hex(data)',
                        'formatted_data',
                        data.data //
                            .map((e) => e.toRadixString(16).padLeft(2, '0'))
                            .join(' ')),
                  )
                  .then((value) {
                if (value.isEmpty) return;

                final index = value.first.messageNumber;

                // dataController?.setExpaned(index, true);
                dataController?.goToItemId(index);
                // controller?.scrollTo(
                //   index: index,
                //   alignment: 0.5,
                //   duration: const Duration(milliseconds: 160),
                // );
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

          final traceResult = importer.parse(file.name);

          for (final message in traceResult.$1.messages.take(100)) {
            await XDatabase.instance.data(i).insert(message);
          }

          watch.stop();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Parsing took: ${watch.elapsedMilliseconds}ms"),
            ));
          }

          setState(() {
            trace = traceResult.$1;
            controller = ItemScrollController();
            dataController = TraceViewDataController();
          });
        },
        child: Center(child: view),
      ),
    );
  }
}
