import 'package:flutter/material.dart';

extension ScaffoldMessengerUtils on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> text(String text) {
    return showSnackBar(SnackBar(content: Text(text)));
  }
}
