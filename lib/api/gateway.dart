import 'dart:async';
import 'dart:convert';

import 'package:eludris/api/message.dart';
import 'package:websocket_universal/websocket_universal.dart';

class EludrisProcessor extends SocketSimpleTextProcessor {
  @override
  get pingServerMessage => jsonEncode({"op": "PING"});
}

class Gateway {
  late final String url;
  late final StreamSubscription<String> _stream;
  late final IWebSocketHandler<String, String> _ws;

  final onMessageCreate = StreamController<Message>.broadcast();

  var connectionOptions = const SocketConnectionOptions(
    pingIntervalMs: 45 * 1000,
  );

  Gateway({required this.url});

  void _handler(String data) {
    final event = jsonDecode(data);
    if (event["op"] == "MESSAGE_CREATE") {
      onMessageCreate.add(Message.fromMap(Map.from(event["d"])));
    }
  }

  Future<void> connect() async {
    final IMessageProcessor<String, String> textSocketProcessor =
        EludrisProcessor();
    _ws = IWebSocketHandler<String, String>.createClient(
      url,
      textSocketProcessor,
      connectionOptions: connectionOptions,
    );

    _stream = _ws.incomingMessagesStream.listen(_handler);
    await _ws.connect();
  }

  Future<void> dispose() async {
    _ws.close();
    await _stream.cancel();
    await onMessageCreate.close();
  }
}
