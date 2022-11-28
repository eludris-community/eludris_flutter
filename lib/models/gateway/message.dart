import 'dart:convert';

class MessageData {
  late String author;
  late bool optimistic;
  late String content;
  late String? plugin;

  MessageData(this.author, this.content, this.optimistic, {this.plugin});

  MessageData.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    author = map['author'];
    content = map['content'];
    optimistic = false;
    plugin = null;
  }
}
