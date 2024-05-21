import 'dart:math';

import 'package:flutter/material.dart';
import 'message_data.dart';

int _fetchDataCalledCounter = 0;
int _fetchAfterCalledCounter = 0;

const int _timeIntervalMilliseconds = 60000;

/// Dummy functon fetching message list with offset and cursor.
///
/// Return message List, and bool hasMoreMessage which represents more messages exist or not.
Future<({List<MessageData> messages, bool hasMoreMessage})> fetchData(
    {required int offset, int cursor = 0, bool doRandom = false}) async {
  _fetchDataCalledCounter++;
  await Future.delayed(const Duration(milliseconds: 500));
  final random = Random();
  List<MessageData> items = _generateRandomMessageDataList(
      offset,
      (doRandom ? DateTime.timestamp() : DateTime.utc(2023)).subtract(Duration(
          milliseconds: (cursor + offset) * _timeIntervalMilliseconds)),
      doRandom: doRandom);
  if (doRandom ? random.nextInt(5) == 0 : _fetchDataCalledCounter % 4 == 0) {
    throw FlutterError("fetch error!!");
  }
  return (
    messages: items,
    hasMoreMessage:
        ((doRandom ? random.nextInt(5) > 0 : cursor != (4 * offset)))
  );
}

/// Dummy functon fetching message list which have been created after specified time.
Future<List<MessageData>> fetchAfter(DateTime after,
    {bool doRandom = false}) async {
  await Future.delayed(const Duration(milliseconds: 500));
  _fetchAfterCalledCounter++;
  final random = Random();
  List<MessageData> items = _generateRandomMessageDataList(
      doRandom ? random.nextInt(3) : 3,
      after.add(const Duration(milliseconds: _timeIntervalMilliseconds)),
      doRandom: doRandom);

  if (doRandom ? random.nextInt(5) == 0 : _fetchAfterCalledCounter % 4 == 0) {
    throw FlutterError("fetch error!!");
  }

  return items;
}

List<MessageData> _generateRandomMessageDataList(int count, DateTime from,
    {bool doRandom = false}) {
  final random = Random();
  final items = List.generate(count, (index) {
    final lines = doRandom ? random.nextInt(20) + 1 : index % 20;
    MessageData content = MessageData(
        message: 'Message ${'\n' * lines}',
        name: "name${doRandom ? random.nextInt(5) : index % 5}",
        createdAt:
            from.add(Duration(milliseconds: index * _timeIntervalMilliseconds)),
        type: MessageDataType.message);
    if (doRandom ? random.nextInt(5) == 0 : index % 5 == 3) {
      content = MessageData(
          createdAt: content.createdAt, type: MessageDataType.image);
    }
    return content;
  });
  items.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  return items;
}
