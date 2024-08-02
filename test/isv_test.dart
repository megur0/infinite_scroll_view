import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_view/infinite_scroll_view.dart';

//import './scroll.dart';

// flutter test --plain-name 'InfiniteScrollView'
void main() {
  group("InfiniteScrollView", () {
    testWidgets("正常系： loadMore", (tester) async {
      const totalNumberOfData = 100;
      await tester.pumpWidget(const MaterialApp(
        home: _DummyPage(
          totalNumberOfData: totalNumberOfData,
          count: 30,
        ),
      ));

      await tester.scrollUntilVisible(
        find.text("$totalNumberOfData"),
        200,
        maxScrolls: 50,
        duration: const Duration(milliseconds: 50),
        scrollable: find.byType(Scrollable),
      );
    });

    // 要素の高さの合計がISVの高さに満たない場合は、スクロールができない。
    // このときドラッグをしても特にスクロールポジションが変わらないことを確認する。
    // また、スクロールイベントも発生しないことを確認。
    testWidgets("正常系: 要素の高さの合計がISVの高さに満たない場合", (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _DummyPage(
          totalNumberOfData: 15,
          count: 3,
        ),
      ));

      doCallbackOnScrollController(tester, (c) {
        c.addListener(() {
          // スクロールイベントが発生したらエラー。
          assert(false);
        });
      });

      expectMaxScrollExtentIs(tester, 0.0);
      expectScrollPositionIs(tester, 0.0);
      await dragScrollable(tester, 10.0);
      expectScrollPositionIs(tester, 0.0);

      await tester.pumpAndSettle();
    });
  });
}

Future<void> dragScrollable(WidgetTester tester, double delta) async {
  await TestAsyncUtils.guard<void>(() async {
    Offset moveStep;
    final scroll = find.byType(Scrollable);
    switch ((find.byType(Scrollable).evaluate().single.widget as Scrollable)
        .axisDirection) {
      case AxisDirection.up:
        moveStep = Offset(0, delta);
      case AxisDirection.down:
        moveStep = Offset(0, -delta);
      case AxisDirection.left:
        moveStep = Offset(delta, 0);
      case AxisDirection.right:
        moveStep = Offset(-delta, 0);
    }
    await tester.drag(scroll, moveStep);
  });
}

void expectMaxScrollExtentIs(WidgetTester widgetTester, double exp) {
  doCallbackOnScrollController(widgetTester, (c) {
    expect(c.position.maxScrollExtent, exp);
  });
}

void expectScrollPositionIs(WidgetTester widgetTester, double exp) {
  doCallbackOnScrollController(widgetTester, (c) {
    expect(c.position.pixels, exp);
  });
}

/// ListViewが表示されていない場合やコントローラーが設定されて場合はエラーとなる
void doCallbackOnScrollController(
    WidgetTester widgetTester, void Function(ScrollController) callback) {
  final listView = find.byType(ListView);
  final listViewWidget = listView.evaluate().first.widget as ListView;
  callback(listViewWidget.controller!);
}

class _DummyItem {
  const _DummyItem(
    this.content,
    this.createdAt,
  );
  final String content;
  final DateTime createdAt;
}

class _DummyPage extends StatefulWidget {
  const _DummyPage({required this.totalNumberOfData, required this.count})
      : assert(totalNumberOfData >= count);

  final int totalNumberOfData;
  final int count;

  @override
  State<_DummyPage> createState() => _DummyPageState();
}

class _DummyPageState extends State<_DummyPage> {
  List<_DummyItem> _items = [];
  bool hasMore = true;
  int offset = 0;
  Object? error;

  void loadMore() {
    offset += widget.count;
    load();
  }

  void load() {
    //debugPrint("load: $offset~${offset + widget.count}");
    _items = [..._items, ...fetchMore(offset, widget.count)];
    if (widget.totalNumberOfData <= offset + widget.count) {
      hasMore = false;
    }
    setState(() {});
  }

  List<_DummyItem> fetchMore(int offset, int count) {
    List<_DummyItem> item = [];
    final last = widget.totalNumberOfData < offset + count
        ? widget.totalNumberOfData
        : offset + count;
    for (int i = offset + 1; i <= last; i++) {
      item.add(_DummyItem(i.toString(),
          DateTime.parse("2022-01-01 00:00:00").subtract(Duration(hours: i))));
    }
    return item;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("test")),
      body: InfiniteScrollView<_DummyItem, Object>(
        items: _items,
        controller: ScrollController(),
        infiniteScrollType: InfiniteScrollType.toBottom,
        builder: (BuildContext context, _DummyItem item, int index) {
          return ListTile(
            title: Text(item.content),
          );
        },
        hasMore: hasMore,
        loadMore: loadMore,
        retry: load,
        // onRefresh: loadNew,
        error: error,
        loadErrorWidgetMaker: (context, error, loadRetryCallback) {
          return LoadErrorScaffold(loadRetryCallback);
        },
        moreLoadErrorWidgetMaker: (context, error, loadRetryCallback) {
          return LoadErrorScaffold(loadRetryCallback);
        },
      ),
    );
  }
}

class LoadErrorScaffold extends StatelessWidget {
  const LoadErrorScaffold(this.onPressed, {super.key});
  final void Function()? onPressed;

  @override
  build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        const Text(
          "load error",
        ),
        TextButton(
            onPressed: onPressed,
            child: const Text(
              "load error retry",
            ))
      ],
    ));
  }
}
