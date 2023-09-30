import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/importer/base_importer.dart';
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

  (String, String, String, String, String, String) _parseLine(String line) {
    int step = 0;
    int? messageNumberStart;
    int messageNumberEnd = 0;

    int? timeOffsetStart;
    int timeOffsetEnd = 0;

    int? rxTxStart;
    int rxTxEnd = 0;

    int? idStart;
    int idEnd = 0;

    int? dataLengthStart;
    int dataLengthEnd = 0;

    int? dataStart;
    int dataEnd = 0;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (step == 0) {
        if (char == ')' && messageNumberStart != null) {
          messageNumberEnd = i;
          step++;

          continue;
        }
        if (char == ' ') continue;
        messageNumberStart ??= i;
      }

      if (step == 1) {
        if (char == ' ' && timeOffsetStart != null) {
          timeOffsetEnd = i;
          step++;

          continue;
        }
        if (char == ' ') continue;
        timeOffsetStart ??= i;
      }

      if (step == 2) {
        if (char == ' ' && rxTxStart != null) {
          rxTxEnd = i;
          step++;

          continue;
        }
        if (char == ' ') continue;
        rxTxStart ??= i;
      }

      if (step == 3) {
        if (char == ' ' && idStart != null) {
          idEnd = i;
          step++;

          continue;
        }
        if (char == ' ') continue;
        idStart ??= i;
      }

      if (step == 4) {
        if (char == ' ' && dataLengthStart != null) {
          dataLengthEnd = i;
          step++;

          continue;
        }
        if (char == ' ') continue;
        dataLengthStart ??= i;
      }

      if (step == 5) {
        if (char != ' ' && dataStart == null) {
          dataStart = i;
          dataEnd = line.length - 1;
          break;
        }
      }
    }

    return (
      line.substring(messageNumberStart!, messageNumberEnd),
      line.substring(timeOffsetStart!, timeOffsetEnd),
      line.substring(rxTxStart!, rxTxEnd),
      line.substring(idStart!, idEnd),
      line.substring(dataLengthStart!, dataLengthEnd),
      line.substring(dataStart!, dataEnd),
    );
  }

  ParseResult parseLines(List<String> lines) {
    final List<CanMessage> messages = [];
    final List<(int, Exception)> errors = [];

    int multiLineCounter = -1;
    int parentIndex = -1;

    final size = lines.length;

    for (var i = 0; i < size; i++) {
      try {
        final line = lines[i];

        final (__, timeOffset, _, id, dataLength, data) = _parseLine(line);

        final parsedData = data.parseBytes(int.parse(dataLength));

        final firstByte = parsedData[0];
        final nextFirstByte = size > i + 1 //
            ? int.parse(_parseLine(lines[i + 1]).$6.substring(0, 2), radix: 16)
            : null;

        if (nextFirstByte == 0x30) {
          multiLineCounter = 0;
          parentIndex = i;

          messages.add(CanMessage(
            rxId: int.parse(id, radix: 16),
            data: parsedData,
            timeOffset: double.parse(timeOffset),
            multiLine: true,
            messageNumber: i,
          ));
        } else if (multiLineCounter == 0 && firstByte == 0x30) {
          multiLineCounter += 1;

          messages.add(CanMessage(
            rxId: int.parse(id, radix: 16),
            data: parsedData,
            timeOffset: double.parse(timeOffset),
            multiLine: false,
            messageNumber: i,
            parent: parentIndex,
          ));
        } else if (firstByte == multiLineCounter + 0x20) {
          multiLineCounter += 1;

          messages.add(CanMessage(
            rxId: int.parse(id, radix: 16),
            data: parsedData,
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
            data: parsedData,
            multiLine: false,
            timeOffset: double.parse(timeOffset),
            messageNumber: i,
          ));
        }
      } on Exception catch (e) {
        errors.add((i, e));
      }
    }

    return (messages, errors);
  }

  @override
  (List<CanMessage>, List<(int, Exception)>) parse() {
    return parseLines(data.trim().split('\n').sublist(14));
  }

  @override
  Future<ParseResult> parseAsync() async {
    final lines = data.trim().split('\n').sublist(14);
    final futures = <Future<ParseResult>>[];

    const isloateCount = 2;

    final lineLength = lines.length;
    final chunkSize = (lineLength / isloateCount).ceil();

    for (var i = 0; i < lineLength; i += chunkSize) {
      futures.add(
      //   compute(
      //   parseLines,
      //   lines.sublist(i, min<int>(i + chunkSize, lineLength)),
      // )
          Isolate.run(() {
            return parseLines(lines.sublist(i, min<int>(i + chunkSize, lineLength)));
          }),
          );
    }

    final results = await Future.wait(futures);

    for (final result in results.sublist(1)) {
      results[0].$1.addAll(result.$1);
      results[0].$2.addAll(result.$2);
    }

    return results[0];
  }
}
