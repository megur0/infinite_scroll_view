import 'package:flutter/material.dart';

enum MessageDataType {
  message,
  image,
}

@immutable
class MessageData {
  const MessageData({
    this.message,
    this.name,
    this.createdAt,
    required this.type,
  })  : assert(!(type == MessageDataType.message &&
            (message == null || name == null || createdAt == null))),
        assert(!(type == MessageDataType.image && createdAt == null));
  final String? message;
  final String? name;
  final DateTime? createdAt;
  final MessageDataType type;
}
