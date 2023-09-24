import 'package:flutter/material.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/pages/can_message_view.dart';

class TraceView extends StatefulWidget {
  const TraceView({
    required this.trace,
    super.key,
  });

  final CanTrace trace;

  @override
  State<TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<TraceView> {
  late final List<(CanMessage, List<CanMessage>)> messagePairs;

  @override
  void initState() {
    super.initState();

    messagePairs = _iterableMessages();
  }

  // Iterable<(CanMessage, List<CanMessage>?)> _iterableMessages() sync* {
  List<(CanMessage, List<CanMessage>)> _iterableMessages() {
    final messages = widget.trace.messages;
    final List<(CanMessage, List<CanMessage>)> result = [];
    var collapsed = 0;
    var collapsedLagged = 0;
    var linking = false;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      // if (messages.elementAtOrNull(i)?.parent != null) {

      if (message.parent != null) {
        result[message.parent! - collapsedLagged].$2.add(message);
        collapsed++;
      } else {
        result.add((message, []));

        if (collapsed != 0) {
          collapsedLagged += collapsed;
          collapsed = 0;
        }
      }
      // if (messages.elementAtOrNull(i + 1)?.parent != null) {
      //   result[messages
      // }

      // result.add(value)
    }

    return result;

    // for (var element in widget.trace.messages) {
    //
    //   }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messagePairs.length,
      itemBuilder: (context, index) {
        final messagePair = messagePairs[index];
        final message = messagePair.$1;
        final children = messagePair.$2;

        if (children.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CanMessageView(message: message),
          );
        }

        return ExpansionTile(
          title: CanMessageView(message: message),
          tilePadding: const EdgeInsets.all(8),
          controlAffinity: ListTileControlAffinity.trailing,
          children: [
            for (final message in children)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CanMessageView(message: message),
              ),
          ],
        );

        // return Card(
        //   child: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: Container(
        //       padding: const EdgeInsets.all(4),
        //       decoration: BoxDecoration(
        //         color: message.parent != null ? Colors.red : Colors.black12,
        //         borderRadius: BorderRadius.circular(2),
        //       ),
        //       child:             ),
        //   ),
        // );
      },
    );
  }
}
