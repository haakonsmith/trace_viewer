import 'dart:typed_data';

class CanMessage {
  final int rxId;
  final bool multiLine;
  final Uint8List data;
  final double timeOffset;
  final int messageNumber;
  final int? parent;

  const CanMessage({
    required this.rxId,
    required this.multiLine,
    required this.data,
    required this.timeOffset,
    required this.messageNumber,
    this.parent,
  });

  @override
  String toString() {
    return "$rxId, $multiLine, $data";
  }
}
