import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:trace_viewer/utils/byte_data_input_formatter.dart';

typedef TraceSearchData = ({Uint8List data});
typedef TraceSearchCallback = void Function(TraceSearchData data);

class TraceSearch extends StatefulWidget {
  const TraceSearch({super.key, this.onSearch});

  final TraceSearchCallback? onSearch;

  @override
  State<TraceSearch> createState() => _TraceSearchState();
}

class _TraceSearchState extends State<TraceSearch> {
  final byteDataController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextField(
              controller: byteDataController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9a-f]')),
                ByteDataInputFormatter(),
              ],
              onSubmitted: (value) {
                try {
                  final byteStrings = value
                      .trim() //
                      .split(" ")
                      .map((e) => int.parse(e, radix: 16))
                      .toList();

                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(byteStrings.toString())));

                  widget.onSearch?.call((data: Uint8List.fromList(byteStrings)));
                } on FormatException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("error parsing")));
                }
                // widget.onSearch?.call();
              },
            )
          ]),
        ),
      ),
    );
  }
}
