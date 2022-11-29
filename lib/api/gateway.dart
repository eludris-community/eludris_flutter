import 'dart:async';

import 'package:eludris/api/message.dart';
import 'package:websocket_universal/websocket_universal.dart';

class Gateway {
  late final String url;
  late final StreamSubscription<String> _stream;
  late final IWebSocketHandler<String, String> _ws;

  final onMessageCreate = StreamController<Message>.broadcast();

  var connectionOptions = const SocketConnectionOptions(
    pingIntervalMs: 20 * 1000,
  );

  Gateway({required this.url});

  void _handler(String data) {
    onMessageCreate.add(Message.fromJson(data));
  }

  Future<void> connect() async {
    final IMessageProcessor<String, String> textSocketProcessor =
        SocketSimpleTextProcessor();
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
