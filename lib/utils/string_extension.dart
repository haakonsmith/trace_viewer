import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

extension LazyList on String {
  Result<Uint8List, Exception> parseBytes() {
    return Result<Uint8List, Exception>.of(() {
      return Uint8List.fromList(trim().split(' ').map((e) {
        return int.parse(e, radix: 16);
      }).toList());
    });
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
