import 'package:flutter/services.dart';

class ByteDataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    final int textLength = text.length;

    int selectionIndex = newValue.selection.end;

    final StringBuffer buffer = StringBuffer();
    final cleanText = newValue.text.replaceAll(' ', '');

    for (var i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);

      if ((i + 1) % 2 == 0 && i < cleanText.length - 1) {
        buffer.write(' ');
      }
    }

    return newValue.copyWith(
      text: buffer.toString(),
      // text: text,
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
