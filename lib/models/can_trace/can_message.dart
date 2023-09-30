import 'dart:typed_data';

import 'package:xqflite/xqflite.dart';

class CanMessage {
  final int? id;

  final int rxId;
  final bool multiLine;
  final Uint8List data;
  final double timeOffset;
  final int messageNumber;
  final int? parent;

  const CanMessage({
    this.id,
    required this.rxId,
    required this.multiLine,
    required this.data,
    required this.timeOffset,
    required this.messageNumber,
    this.parent,
  });

  @override
  String toString() {
    return 'CanMessage(rxId: $rxId, multiLine: $multiLine, data: $data, timeOffset: $timeOffset, messageNumber: $messageNumber, parent: $parent)';
  }

  CanMessage copyWith({
    int? rxId,
    bool? multiLine,
    Uint8List? data,
    double? timeOffset,
    int? messageNumber,
    int? parent,
  }) {
    return CanMessage(
      rxId: rxId ?? this.rxId,
      multiLine: multiLine ?? this.multiLine,
      data: data ?? this.data,
      timeOffset: timeOffset ?? this.timeOffset,
      messageNumber: messageNumber ?? this.messageNumber,
      parent: parent ?? this.parent,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'rx_id': rxId,
      'multi_line': multiLine ? 1 : 0,
      'data': data,
      'time_offset': timeOffset,
      'message_number': messageNumber,
      'parent': parent,
      'formatted_data': data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' '),
    };
  }

  factory CanMessage.fromMap(Map<String, dynamic> map) {
    return CanMessage(
      id: map['id'] as int?,
      rxId: map['rx_id'] as int,
      multiLine: map['multi_line'] == 1,
      data: map['data'],
      timeOffset: map['time_offset'] as double,
      messageNumber: map['message_number'] as int,
      parent: map['parent'] != null ? map['parent'] as int : null,
    );
  }

  static Converter<CanMessage> get converter => (
        fromDb: CanMessage.fromMap,
        toDb: (data) => data.toMap(),
      );

  @override
  bool operator ==(covariant CanMessage other) {
    if (identical(this, other)) return true;

    return other.rxId == rxId && //
        other.id == id &&
        other.multiLine == multiLine &&
        other.data == data &&
        other.timeOffset == timeOffset &&
        other.messageNumber == messageNumber &&
        other.parent == parent;
  }

  @override
  int get hashCode {
    return rxId.hashCode ^ //
        multiLine.hashCode ^
        id.hashCode ^
        data.hashCode ^
        timeOffset.hashCode ^
        messageNumber.hashCode ^
        parent.hashCode;
  }
}
