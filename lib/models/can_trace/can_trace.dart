import 'package:trace_viewer/models/can_trace/can_message.dart';

class CanTrace {
  final List<CanMessage> messages;
  final String name;

  const CanTrace({
    required this.messages,
    required this.name,
  });

  @override
  String toString() {
    return messages.toString();
  }
}
