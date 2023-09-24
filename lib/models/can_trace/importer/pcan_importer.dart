import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
import 'package:trace_viewer/utils/collection_iterator.dart';
import 'package:trace_viewer/utils/iterator_extension.dart';
import 'package:trace_viewer/utils/nullable_extension.dart';
import 'package:trace_viewer/utils/string_extension.dart';

final class PcanImporter extends TraceImporter {
  const PcanImporter(super.data);

  static bool canParse(String data) {
    final lineIterable = data.lazySplit('\n');

    final line = lineIterable.elementAtOrNull(4);

    if (line == null) return false;
    if (line.length < 26) return false;

    return line.substring(17, 26) == "PCAN-View";
  }

  List<String> _parseLine(String line) {
    final iterator = line.iterable.iterator;
    final List<String> result = [];

    result.add('');
    while (iterator.moveNext() && iterator.current != ")") {
      if (iterator.current != " ") result.last += iterator.current;
    }

    for (var i = 0; i < 4; i++) {
      result.add('');
      iterator.moveNext();
      iterator.moveUntil((element) => element != " ");

      do {
        result.last += iterator.current;
      } while (iterator.moveNext() && iterator.current != " ");
    }

    result.add('');
    iterator.moveNext();
    iterator.moveUntil((element) => element != " ");

    do {
      result.last += iterator.current;
    } while (iterator.moveNext() && iterator.current != "\n");

    return result;
  }

  @override
  (CanTrace, List<(int, Exception)>) parse() {
    final lineIterator = data
        .lazySplit('\n') //
        .skip(14)
        // .take(100)
        .collectionIterator;
    final List<CanMessage> messages = [];
    final List<(int, Exception)> errors = [];

    int multiLineCounter = -1;
    int parentIndex = -1;
    int i = 0;

    while (lineIterator.moveNext()) {
      final line = lineIterator.current;

      final [messageNumber, timeOffset, _, id, dataLength, data] = _parseLine(line);

      final parsedData = data.parseBytes();

      if (parsedData.isErr()) {
        errors.add((int.parse(messageNumber), parsedData.unwrapErr()));
        continue;
      }

      final firstByte = int.parse(data.substring(0, 2), radix: 16);
      final nextFirstByte = lineIterator
          .peek() //
          ?.map((line) => _parseLine(line))
          ?.last
          .substring(0, 2)
          .map((value) => int.parse(value, radix: 16));

      if (nextFirstByte == 0x30) {
        multiLineCounter = 0;
        parentIndex = i;

        messages.add(CanMessage(
          rxId: int.parse(id, radix: 16),
          data: parsedData.unwrap(),
          timeOffset: double.parse(timeOffset),
          multiLine: true,
          messageNumber: i,
        ));
      } else if (multiLineCounter == 0 && firstByte == 0x30) {
        multiLineCounter += 1;

        messages.add(CanMessage(
          rxId: int.parse(id, radix: 16),
          data: parsedData.unwrap(),
          timeOffset: double.parse(timeOffset),
          multiLine: false,
          messageNumber: i,
          parent: parentIndex,
        ));
      } else if (firstByte == multiLineCounter + 0x20) {
        multiLineCounter += 1;

        messages.add(CanMessage(
          rxId: int.parse(id, radix: 16),
          data: parsedData.unwrap(),
          timeOffset: double.parse(timeOffset),
          multiLine: false,
          messageNumber: i,
          parent: parentIndex,
        ));

        if (multiLineCounter == 0x10) {
          multiLineCounter = 0;
        }
      } else {
        multiLineCounter = -1;

        messages.add(CanMessage(
          rxId: int.parse(id, radix: 16),
          data: parsedData.unwrap(),
          multiLine: false,
          timeOffset: double.parse(timeOffset),
          messageNumber: i,
        ));
      }

      i += 1;
    }

    return (CanTrace(messages: messages), errors);
  }
}
