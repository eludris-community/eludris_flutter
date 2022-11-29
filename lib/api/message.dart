import 'dart:convert';

class Message {
  late String author;
  late bool optimistic;
  late String content;
  late String? plugin;

  Message(this.author, this.content, this.optimistic, {this.plugin});

  Message.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    author = map['author'];
    content = map['content'];
    optimistic = false;
    plugin = null;
  }
}
