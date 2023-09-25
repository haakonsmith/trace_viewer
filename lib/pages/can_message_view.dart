import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';

class CanMessageView extends StatelessWidget {
  const CanMessageView({

    this.trailing,
    required this.message,
    super.key,
  });

  final Widget? trailing;
  final CanMessage message;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.robotoMono(
      // color: const Color(0xFF505050),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    final fragments = message.data
        .map((e) => e.toRadixString(16).toUpperCase().padLeft(2, "0"))
        .toList();
    var fragmentColors = [
      message.multiLine ? style.copyWith(color: Colors.white38) : style,
    ];

    if (message.parent != null &&
        message.parent! - message.messageNumber == -1) {
      fragmentColors =
          List.generate(8, (index) => style.copyWith(color: Colors.white12));
    }

    if (!message.multiLine && message.parent == null) {
      fragmentColors = [];
      var found = false;

      for (final frag in fragments.reversed) {
        if (!found && frag != "00") found = true;

        fragmentColors.add(
          found ? style : style.copyWith(color: Colors.white12),
        );
      }

      fragmentColors = fragmentColors.reversed.toList();
    }

    final row = Row(
      children: [
        trailing ?? const SizedBox(),
        SizedBox(
          width: 60,
          child: Text(
            message.messageNumber.toString(),
            style: style.copyWith(color: const Color(0xFF303030)),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            "0x${message.rxId.toRadixString(16)}",
            style: style.copyWith(color: const Color(0xFF505050)),
          ),
        ),
        SelectableText.rich(
          TextSpan(children: [
            for (var i = 0; i < fragments.length; i++)
              TextSpan(
                text: "${fragments[i]} ",
                // style: message.multiLine ? style.copyWith(color: Colors.white38) : style,
                style: fragmentColors.elementAtOrNull(i) ?? style,
              ),
          ]),
        ),
        // SizedBox(
        //   width: 300,
        //   child: Text(
        //     fragments.skip(1).join(" "),
        //     style: (message.parent != null //
        //             ? message.parent! - message.messageNumber == -1
        //             : false)
        //         ? style.copyWith(color: Colors.white12)
        //         : style,
        //   ),
        // ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // color: message.parent != null ? Colors.red : Colors.black12,
        color: Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
      child: row,
    );
  }
}
