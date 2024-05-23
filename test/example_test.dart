import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_view/infinite_scroll_view.dart';

main() {
  Future<void> p(WidgetTester tester) async =>
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text("demo")),
          body: const MyWidget(),
        ),
      ));

  testWidgets("", (tester) async {
    await p(tester);

    await tester.pump(const Duration(milliseconds: 500));

    //addDebugPrintOnScrollEvent();

    await IsvTestUtil.scrollUntilVisibleAndPump(
        tester, find.byType(CircularProgressIndicator));

    await IsvTestUtil.scrollUntilVisibleAndPump(
        tester, find.byType(CircularProgressIndicator));

    await IsvTestUtil.scrollUntilVisibleAndPump(
        tester, find.byType(CircularProgressIndicator));

    await IsvTestUtil.scrollUntilVisibleAndPump(
        tester, find.text("end of data"));
  });

  testWidgets("", (tester) async {
    await p(tester);

    await tester.pump(const Duration(milliseconds: 500));

    await IsvTestUtil.scrollUntilVisibleAndPump(
        tester, find.text("end of data"));
  });

  testWidgets("", (tester) async {
    await p(tester);

    await tester.pump(const Duration(milliseconds: 500));

    await IsvTestUtil.scrollUntilVisibleAndPump(tester, find.text("99"));

    // skip pending timer
    await tester.binding.delayed(const Duration(days: 999));
  });
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<int>? items;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final offset = items?.length ?? 0;
    items = [
      ...(items ?? []),
      ...(List.generate(100, (index) => offset + index))
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollView(
      controller: ScrollController(),
      items: items,
      builder: (context, item, index) => Text(
        "$item",
        textAlign: TextAlign.center,
      ),
      hasMore: items == null || items!.length < 300,
      loadMore: getData,
      endOfDataWidgetMaker: (context) => const Text("end of data"),
    );
  }
}

// for debug print
void addDebugPrintOnScrollEvent() {
  doCallbackOnScrollController((c) {
    c.addListener(() {
      debugPrint("${c.position.pixels}, ${c.position.maxScrollExtent}");
    });
  });
}

void doCallbackOnScrollController(void Function(ScrollController) callback) {
  final controller = getScrollController();
  assert(controller != null);
  callback(controller!);
}

ScrollController? getScrollController() {
  final finder = find.byType(ListView);
  if (finder.evaluate().isEmpty) return null;
  final listViewWidget = finder.evaluate().first.widget as ListView;
  return listViewWidget.controller;
}
