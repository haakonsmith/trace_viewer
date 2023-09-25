import 'dart:math';

import 'package:flutter/material.dart';
import 'package:huge_listview/huge_listview.dart';
import 'package:quiver/collection.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/pages/can_message_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trace_viewer/widgets/expansion_tile.dart';

typedef TraceItem = (CanMessage, List<CanMessage>);

class TraceView extends StatefulWidget {
  const TraceView({
    required this.trace,
    super.key,
  });

  final CanTrace trace;

  @override
  State<TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<TraceView> {
  static const int PAGE_SIZE = 12;
  static const double PLACEHOLDER_SIZE = 36;

  final listKey = GlobalKey<HugeListViewState>();
  final scroll = ItemScrollController();

  late final List<TraceItem> data;
  late final HugeListViewController controller;
  final Map<int, CustomExpansionTileController> controllers = Map();
  final Map<int, GlobalKey<CustomExpansionTileState>> keys = Map();

  final LruMap<int, HugeListViewPageResult<TraceItem>>? lruMap = LruMap();

  @override
  void initState() {
    super.initState();

    data = _iterableMessages();
    controller = HugeListViewController(totalItemCount: data.length);
  }

  List<TraceItem> _iterableMessages() {
    final messages = widget.trace.messages;
    final List<TraceItem> result = [];
    var collapsed = 0;
    var collapsedLagged = 0;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];

      if (message.parent != null) {
        result[message.parent! - collapsedLagged].$2.add(message);
        collapsed++;
      } else {
        result.add((message, []));

        if (collapsed != 0) {
          collapsedLagged += collapsed;
          collapsed = 0;
        }
      }
    }

    return result;
  }

  Widget buildPlaceholder() {
    double margin = Random().nextDouble() * 50;

    return Padding(
      // padding: EdgeInsets.fromLTRB(3, 3, 3 + margin, 3),
      padding: const EdgeInsets.all(8).copyWith(right: margin),
      child: Container(
        height: PLACEHOLDER_SIZE,
        color: Colors.black26,
      ),
    );
  }

  Future<List<TraceItem>> _loadPage(int page, int pageSize) async {
    int from = page * pageSize;
    int to = min(data.length, from + pageSize);

    return data.sublist(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: HugeListView<(CanMessage, List<CanMessage>)>(
          key: listKey,
          scrollController: scroll,
          listViewController: controller,
          pageSize: PAGE_SIZE,
          startIndex: 0,
          pageFuture: (page) => _loadPage(page, PAGE_SIZE),
          lruMap: lruMap,
          itemBuilder: (context, index, TraceItem messagePair) {
            final message = messagePair.$1;
            final children = messagePair.$2;

            if (!controllers.containsKey(index)) {
              controllers[index] = CustomExpansionTileController();
              keys[index] = GlobalKey();
            }

            if (children.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CanMessageView(message: message),
              );
            }

            return CustomExpansionTile(
              title: CanMessageView(message: message),
              tilePadding: const EdgeInsets.all(8),
              controlAffinity: ListTileControlAffinity.trailing,
              controller: controllers[index],
              key: keys[index],
              children: [
                for (final message in children)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CanMessageView(
                      message: message,
                      trailing: TextButton(
                        onPressed: () {
                          controllers[index]?.collapse();
                        },
                        child: const Text("Close"),
                      ),
                    ),
                  ),
              ],
            );
          },
          thumbBuilder: DraggableScrollbarThumbs.ArrowThumb,
          thumbBackgroundColor: Theme.of(context).focusColor,
          thumbDrawColor: Colors.grey,
          thumbHeight: 48,
          placeholderBuilder: (context, index) => buildPlaceholder(),
          waitBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          emptyBuilder: (context) => const Text("empty :)"),
          firstShown: (index) {},
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(6.0),
          alwaysVisibleThumb: false,
        ),
      ),
    );
    // return ListView.builder(
    //   itemCount: messagePairs.length,
    //   itemBuilder: (context, index) {
    //     final messagePair = messagePairs[index];
    //     final message = messagePair.$1;
    //     final children = messagePair.$2;

    //     if (children.isEmpty) {
    //       return Padding(
    //         padding: const EdgeInsets.all(8.0),
    //         child: CanMessageView(message: message),
    //       );
    //     }

    //     return ExpansionTile(
    //       title: CanMessageView(message: message),
    //       tilePadding: const EdgeInsets.all(8),
    //       controlAffinity: ListTileControlAffinity.trailing,
    //       children: [
    //         for (final message in children)
    //           Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: CanMessageView(message: message),
    //           ),
    //       ],
    //     );

    // return Card(
    //   child: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Container(
    //       padding: const EdgeInsets.all(4),
    //       decoration: BoxDecoration(
    //         color: message.parent != null ? Colors.red : Colors.black12,
    //         borderRadius: BorderRadius.circular(2),
    //       ),
    //       child:             ),
    //   ),
    // );
    //   },
    // );
  }
}
