import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

extension LazyList on String {
  Uint8List parseBytes(int byteCount) {
    final result = Uint8List(byteCount);
    var count = 0;
    int lastFound = -1;

    // -50ms
    for (var i = 0; i < length; i++) {
      final char = this[i];

      if (char == ' ') {
        if (lastFound != -1) {
          result[count++] = int.parse(substring(lastFound, i), radix: 16);
        }

        lastFound = -1;
        continue;
      }

      if (char != ' ' && lastFound == -1) {
        lastFound = i;
      }
    }

    return result;

    // -50ms
    // final stringBytes = trim().split(' ');
    // final result = Uint8List(stringBytes.length);

    // for (var i = 0; i < stringBytes.length; i++) {
    //   result[i] = int.parse(stringBytes[i], radix: 16);
    // }

    // return result;

    // return Uint8List.fromList(trim().split(' ').map((e) => int.parse(e, radix: 16)).toList());
  }

  Iterable<String> lazySplit(String splitChar) sync* {
    final buffer = StringBuffer();

    for (var i = 0; i < length; i++) {
      if (this[i] == splitChar) {
        yield buffer.toString();

        buffer.clear();
      } else {
        buffer.write(this[i]);
      }
    }
  }

  /// To iterate a [String]: `"Hello".iterable()`
  Iterable<String> get iterable sync* {
    for (var i = 0; i < length; i++) {
      yield this[i];
    }
  }
}
