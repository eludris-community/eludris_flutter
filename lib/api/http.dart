import 'dart:convert';
import 'package:http/http.dart';

import 'package:eludris/api/message.dart';

class HTTP {
  late final String baseUrl;

  HTTP({required this.baseUrl});

  Future<Message> createMessage(String author, String content) async {
    final request = Request('POST', Uri.parse('$baseUrl/messages'));
    request.body = jsonEncode({'author': author, 'content': content});

    await request.send();
    return Message(author, content, true);
  }
}
