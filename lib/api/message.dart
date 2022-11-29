import 'dart:convert';

class Message {
  late String author;
  late bool optimistic;
  late String content;
  late String? plugin;

  Message(this.author, this.content, this.optimistic, {this.plugin});

  Message.fromMap(Map<String, String> data) {
    author = data['author']!;
    content = data['content']!;
    optimistic = false;
    plugin = null;
  }
}
