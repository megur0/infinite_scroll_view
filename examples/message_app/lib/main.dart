import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_view/infinite_scroll_view.dart';

import 'data/fetch_data.dart';
import 'data/message_data.dart';
import 'widget/widget.dart';

void main() {
  ThemeData theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  );

  runApp(MaterialApp(
      title: 'Infinite Scroll Messages',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Messages in infinite scroll'),
        ),
        body: const MessageApp(),
      )));
}

class MessageApp extends StatefulWidget {
  const MessageApp({super.key});

  @override
  State<MessageApp> createState() => _MessageAppState();
}

class _MessageAppState extends State<MessageApp> {
  static const int _dataOffset = 10;
  InfiniteScrollType scrollType =
      InfiniteScrollType.toBottomWithRefreshIndicator;
  DateTime? latestMessageDatetime;
  List<MessageData> _items = <MessageData>[];
  Err? _error;
  int _page = 1;
  bool _needsAdditionalLoadAtFuture = true;
  late bool _hasMore = true;

  Widget _builder(BuildContext context, MessageData content, int index) {
    switch (content.type) {
      case MessageDataType.message:
        return MessageWidget(content: content);
      case MessageDataType.image:
        return ImageWidget(content: content);
    }
  }

  Future<void> _refresh() async {
    assert(latestMessageDatetime != null);
    try {
      final messages = await fetchAfter(latestMessageDatetime!);
      latestMessageDatetime = messages[0].createdAt;
      _items = [...messages, ..._items];
    } catch (err) {
      _error = Err(message: err.toString());
    }
    setState(() {});
  }

  Future<void> _future() async {
    if (!_needsAdditionalLoadAtFuture) return;
    _needsAdditionalLoadAtFuture = false;
    try {
      final messages = await fetchData(
          offset: _dataOffset, cursor: (_page - 1) * _dataOffset);
      if (_page == 1) {
        latestMessageDatetime = messages.messages[0].createdAt;
      }
      _hasMore = messages.hasMoreMessage;
      _items = [..._items, ...messages.messages];
    } catch (err) {
      //_page--;
      _error = Err(message: err.toString());
    }
  }

  void _loadMore() {
    _page++;
    _needsAdditionalLoadAtFuture = true;
    setState(() {});
  }

  void _retry() {
    _needsAdditionalLoadAtFuture = true;
    setState(() {});
  }

  @override
  build(BuildContext context) {
    return FutureBuilder(
        future: _future(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.waiting &&
              snapshot.connectionState != ConnectionState.done) {
            throw FlutterError('unexpected future state.');
          }
          return Stack(children: [
            InfiniteScrollView<MessageData, Err>(
              items: _items,
              builder: _builder,
              hasMore: _hasMore,
              loadMore: _loadMore,
              retry: _retry,
              onRefresh: _refresh,
              error: _error,
              infiniteScrollType: scrollType,
              debugPrintLoadStatus: true,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 100.0, right: 20.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: DropdownButton(
                            items: InfiniteScrollType.values
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e.name),
                                    ))
                                .toList(),
                            onChanged: (type) {
                              scrollType = type!;
                              setState(() {});
                            },
                            value: scrollType,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ]);
        });
  }
}

class Err {
  Err({required this.message, this.errorCode});
  final String message;
  final int? errorCode;
}
