import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:huge_listview/huge_listview.dart';
import 'package:quiver/collection.dart';
import 'package:trace_viewer/models/can_trace/can_message.dart';
import 'package:trace_viewer/models/can_trace/can_trace.dart';
import 'package:trace_viewer/pages/can_message_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trace_viewer/widgets/expansion_tile.dart';

// typedef TraceItem = (CanMessage, bool);
class TraceItem {
  CanMessage message;
  bool visible;
  // bool get header;

  TraceItem(this.message, this.visible);
}

class TraceViewDataController {
  TraceItem Function(int index)? dataGetter;
  void Function(int index, bool expanded)? dataSetter;

  bool getExpanded(int index) => dataGetter!(index).visible;
  void setExpaned(int index, bool expanded) => dataSetter!(index, expanded);

  void Function(int id)? itemIdVisitor;

  void goToItemId(int id) => itemIdVisitor?.call(id);
}

class TraceView extends StatefulWidget {
  const TraceView({
    required this.trace,
    this.controller,
    this.dataController,
    super.key,
  });

  final CanTrace trace;
  final ItemScrollController? controller;
  final TraceViewDataController? dataController;

  @override
  State<TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<TraceView> {
  static const int pageSize = 7;
  static const double placeHolderSize = 36;

  final listKey = GlobalKey<HugeListViewState>();
  late final ItemScrollController scroll;

  late final List<TraceItem> data;
  late final HugeListViewController listViewController;
  final Map<int, CustomExpansionTileController> controllers = {};
  final Map<int, GlobalKey<CustomExpansionTileState>> keys = {};

  final LruMap<int, HugeListViewPageResult<TraceItem>>? lruMap = LruMap();

  late BiMap<int, int> realToLogicalIndexMap;
  late BiMap<int, int> logicalToRealIndexMap;

  late int openItems;

  @override
  void initState() {
    super.initState();

    data = _getData();

    // openItems = countOpenItems();
    logicalToRealIndexMap = _generateReverseMapping();
    realToLogicalIndexMap = logicalToRealIndexMap.inverse;

    listViewController = HugeListViewController(totalItemCount: logicalToRealIndexMap.keys.length);
    scroll = widget.controller ?? ItemScrollController();

    widget.dataController?.dataSetter = (index, expanded) => setState(() => data[index].visible = expanded);
    widget.dataController?.dataGetter = (index) => data[index];
    widget.dataController?.itemIdVisitor = (id) {
      print(data[id].message);
      realToLogicalIndexMap = logicalToRealIndexMap.inverse;

      if (realToLogicalIndexMap[id] == null) {
        final keys = realToLogicalIndexMap.keys.toList()..sort((a, b) => a - b);

        var lastSmallest = 0;

        for (var i = 0; i < keys.length; i++) {
          if (keys[i] > id) {
            for (var i = lastSmallest; i < data.length; i++) {
              if (i == id) {
                data[i].visible = true;

                logicalToRealIndexMap = _generateReverseMapping();
                realToLogicalIndexMap = logicalToRealIndexMap.inverse;
                listViewController.invalidateList(true);
                scroll.jumpTo(index: realToLogicalIndexMap[id]!);
                break;
              }
            }

            break;
          }

          lastSmallest = keys[i];
        }
        // for (var element in realToLogicalIndexMap.keys) {

        // }
        // for (var i = 0; i < realToLogicalIndexMap.; i++) {

        // }
      } else {
        scroll.jumpTo(index: realToLogicalIndexMap[id]!);
      }
    };
  }

  BiMap<int, int> _generateMapping() {
    // var total = 0;
    final BiMap<int, int> realToLogicalIndexMap = BiMap();

    var j = 0;

    for (var i = 0; i < data.length; i++) {
      // if (data[i].expanded) realToLogicalIndexMap[data[i].message.messageNumber] = i;
      if (data[i].visible) {
        realToLogicalIndexMap[i] = j;
        j++;
      }
    }

    return realToLogicalIndexMap;
  }

  BiMap<int, int> _generateReverseMapping() {
    final BiMap<int, int> mapping = BiMap();

    var skipped = 0;
    final openItems = countOpenItems();

    for (var i = 0; i < openItems; i++) {
      var nextVisibleIndex = i + skipped;

      for (var i = nextVisibleIndex; i < data.length; i++) {
        if (data[i].visible) {
          nextVisibleIndex = i;
          break;
        } else {
          skipped++;
        }
      }

      mapping[i] = nextVisibleIndex;
    }

    return mapping;
  }

  List<TraceItem> _getData() {
    final messages = widget.trace.messages;
    final List<TraceItem> result = [];

    for (var i = 0; i < messages.length; i++) {
      result.add(TraceItem(messages[i], messages[i].parent == null));
    }

    return result;
  }

  int countOpenItems() {
    var total = 0;

    for (var i = 0; i < data.length; i++) {
      if (data[i].visible) total++;
    }

    return total;
  }

  Widget buildPlaceholder() {
    double margin = Random().nextDouble() * 50;

    return Padding(
      padding: const EdgeInsets.all(8).copyWith(right: margin),
      child: Container(height: placeHolderSize, color: Colors.black26),
    );
  }

  List<TraceItem> _loadPage(int page, int pageSize) {
    int from = page * pageSize;

    int to = min(logicalToRealIndexMap.keys.length, from + pageSize);
    final List<TraceItem> result = [];

    for (var i = from; i < to; i++) {
      final id = logicalToRealIndexMap[i]!;

      result.add(data[id]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: HugeListView<TraceItem>(
          key: listKey,
          scrollController: scroll,
          listViewController: listViewController,
          pageSize: pageSize,
          startIndex: 0,
          velocityThreshold: 0.1,
          pageFuture: (page) => _loadPage(page, pageSize),
          lruMap: lruMap,
          // scrollableCountGetter: () => openItems,

          itemBuilder: (context, index, TraceItem item) {
            final message = item.message;
            final visible = item.visible;

            final id = message.messageNumber;

            // realToLogicalIndexMap[id] = index;

            if (!controllers.containsKey(id)) {
              controllers[id] = CustomExpansionTileController();
              keys[id] = GlobalKey();
            }

            // if (index == 14) print(message);
            // if (index == 14) print(visible);

            return Padding(
              padding: const EdgeInsets.all(6.0).copyWith(left: message.parent == null ? 0 : 40),
              child: Row(
                children: [
                  CanMessageView(message: message),
                  if (data.elementAtOrNull(id + 1)?.message.parent != null && message.parent == null) //

                    SizedBox(
                      height: 32,
                      child: IconButton(
                        onPressed: () {
                          // data[id].visible = !data[id].visible;

                          var i = id + 2;

                          data[id + 1].visible = !data[id + 1].visible;

                          while (data[i].message.parent == id) {
                            data[i].visible = data[id + 1].visible;

                            i++;
                          }

                          setState(() {
                            // openItems = countOpenItems();
                            logicalToRealIndexMap = _generateReverseMapping();
                            listViewController.totalItemCount = logicalToRealIndexMap.keys.length;
                            listViewController.invalidateList(true);
                          });
                        },
                        icon: const Icon(Icons.unfold_more),
                        selectedIcon: const Icon(Icons.unfold_less),
                        isSelected: !data[id + 1].visible,
                        splashRadius: 16,
                        iconSize: 16,
                      ),
                    ),
                ],
              ),
            );

            if (message.parent != null) {
              if (!visible) return const SizedBox(height: 0);
              if (visible) {
                return Padding(
                  padding: const EdgeInsets.all(6.0).copyWith(left: 40),
                  child: CanMessageView(message: message),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  CanMessageView(message: message),
                  if (data.elementAtOrNull(index + 1)?.message.parent != null && message.parent == null) //

                    SizedBox(
                      height: 32,
                      child: IconButton(
                        onPressed: () {
                          data[index].visible = !data[index].visible;

                          var i = index + 1;

                          while (data[i].message.parent == index) {
                            data[i].visible = data[index].visible;

                            i++;
                          }

                          setState(() {
                            openItems = countOpenItems();
                            // listViewController.totalItemCount = countOpenItems();
                          });
                        },
                        icon: const Icon(Icons.unfold_more),
                        selectedIcon: const Icon(Icons.unfold_less),
                        isSelected: visible,
                        splashRadius: 16,
                        iconSize: 16,
                      ),
                    ),
                ],
              ),
            );
            // }

            // return CanMessageView(message: message);

            // return CustomExpansionTile(
            //   title: CanMessageView(message: message),
            //   tilePadding: const EdgeInsets.all(8),
            //   controlAffinity: ListTileControlAffinity.trailing,
            //   controller: controllers[index],
            //   key: keys[index],
            //   children: [
            //     for (final message in children)
            //       Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: CanMessageView(
            //           message: message,
            //           trailing: TextButton(
            //             onPressed: () {
            //               controllers[index]?.collapse();
            //             },
            //             child: const Text("Close"),
            //           ),
            //         ),
            //       ),
            //   ],
            // );
          },

          thumbBuilder: DraggableScrollbarThumbs.ArrowThumb,
          thumbBackgroundColor: Theme.of(context).focusColor,
          thumbDrawColor: Colors.grey,
          thumbHeight: 48,
          placeholderBuilder: (context, index) => buildPlaceholder(),
          waitBuilder: (context) => const Center(child: CircularProgressIndicator()),
          emptyBuilder: (context) => const Text("empty :)"),
          firstShown: (index) {},
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(6.0),
          alwaysVisibleThumb: false,
        ),
      ),
    );
  }
}
