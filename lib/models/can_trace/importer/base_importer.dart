import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/pcan_importer.dart';

typedef ParseResult = (List<CanMessage>, List<(int, Exception)>);

abstract class TraceImporter {
  final String data;

  const TraceImporter(this.data);

  ParseResult parse();
  Future<ParseResult> parseAsync();

  static TraceImporter? import(String data) {
    if (PcanImporter.canParse(data)) return PcanImporter(data);

    return null;
  }
}
