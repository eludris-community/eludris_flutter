import 'dart:convert';
import 'dart:io';

import 'package:eludris/api/message.dart';

class HTTP {
  late final String baseUrl;
  late final HttpClient _client;

  HTTP({required this.baseUrl}) {
    _client = HttpClient();
  }

  Future<Message> createMessage(String author, String content) async {
    final request = await _client.postUrl(Uri.parse('$baseUrl/messages'));
    request.headers.contentType = ContentType.json;
    request.write('{"author": "$author", "content": "$content"}');

    final response = await request.close();
    return Message.fromJson(await response.transform(utf8.decoder).join());
  }
}
