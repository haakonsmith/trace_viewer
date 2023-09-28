import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class ScrollVelocityListener extends StatefulWidget {
  final Function(double) onVelocity;
  final Widget child;

  const ScrollVelocityListener({
    super.key,
    required this.onVelocity,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _ScrollVelocityListenerState();
}

class _ScrollVelocityListenerState extends State<ScrollVelocityListener> {
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  double lastVelocity = 0;
  Debouncer debouncer = Debouncer(milliseconds: 30);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final now = DateTime.now();
        final timeDiff = now.millisecondsSinceEpoch - lastMilli;

        if (notification is ScrollUpdateNotification) {
          final pixelsPerMilli = notification.scrollDelta! / timeDiff;

          widget.onVelocity(pixelsPerMilli);
          lastVelocity = pixelsPerMilli;
          lastMilli = DateTime.now().millisecondsSinceEpoch;
        }

        if (notification is ScrollEndNotification && lastVelocity != 0) {
          debouncer.run(() {
            widget.onVelocity(0);
            lastVelocity = 0;
            lastMilli = DateTime.now().millisecondsSinceEpoch;
          });
        }

        return false;
      },
      child: widget.child,
    );
  }
}
