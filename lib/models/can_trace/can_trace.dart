import 'package:trace_viewer/models/can_trace/can_message.dart';

class CanTrace {
  final List<CanMessage> messages;

  const CanTrace({
    required this.messages,
  });

  @override
  String toString() {
    return messages.toString();
  }
}
