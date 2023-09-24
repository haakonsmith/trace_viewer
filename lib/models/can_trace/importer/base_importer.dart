import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/models/can_trace/importer/pcan_importer.dart';

abstract class TraceImporter {
  final String data;

  const TraceImporter(this.data);

  (CanTrace, List<(int, Exception)>) parse();

  static TraceImporter? import(String data) {
    if (PcanImporter.canParse(data)) return PcanImporter(data);

    return null;
  }
}
