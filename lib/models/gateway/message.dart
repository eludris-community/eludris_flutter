import 'dart:convert';

class MessageData {
  late final String author;
  late bool optimistic;
  late String content;

  MessageData(this.author, this.content, this.optimistic);

  MessageData.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    author = map['author'];
    content = map['content'];
    optimistic = false;
  }
}
