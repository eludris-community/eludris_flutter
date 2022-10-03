import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:eludris/lua/api.dart';
import 'package:eludris/lua/common.dart';
import 'package:eludris/models/gateway/message.dart';
import 'package:eludris/widgets/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show post, MultipartRequest, MultipartFile;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';

class ConnectionStatus extends StatelessWidget {
  final String name;

  const ConnectionStatus({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Icon(Icons.heart_broken);
          if (!snapshot.hasData) return const Icon(Icons.hourglass_empty);

          final prefs = snapshot.data!;

          final httpUrl =
              prefs.getString('http-url') ?? 'https://eludris.tooty.xyz';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connected as $name'),
              Text('Using ${Uri.parse(httpUrl).host}')
            ],
          );
        });
  }
}

class LoggedIn extends StatefulWidget {
  final String name;
  const LoggedIn(
    this.name, {
    Key? key,
  }) : super(key: key);

  @override
  State<LoggedIn> createState() => _LoggedInState();
}

class _LoggedInState extends State<LoggedIn> {
  final _messages = <MessageData>[];
  StreamSubscription? _stream;

  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool textEnabled = true;
  String effisUrl = 'https://eludris.tooty.xyz';
  String httpUrl = "https://eludris.tooty.xyz";
  String gatewayUrl = "wss://eludris.tooty.xyz/ws";

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    _scrollController.dispose();
    _stream?.cancel();
    super.dispose();
  }

  _sendMessage() async {
    final String text = _textController.text;
    _textController.clear();
    setState(() {
      _messages.add(MessageData(widget.name, text, true));
    });
    await post(
      Uri.parse('$httpUrl/messages'),
      body: jsonEncode({
        'author': widget.name,
        'content': text,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  _initState() async {
    final prefs = await SharedPreferences.getInstance();
    httpUrl = prefs.getString('http-url') ?? httpUrl;
    gatewayUrl = prefs.getString('gateway-url') ?? gatewayUrl;
    effisUrl = prefs.getString('effis-url') ?? effisUrl;

    final ws = await WebSocket.connect(gatewayUrl);
    ws.pingInterval = const Duration(seconds: 10);
    _stream = ws.listen((event) {
      final message = MessageData.fromJson(event);

      final api = LuaAPI(API());
      final ls = prepareLua(api, message);

      // TODO: Run postGotMessage hooks

      setState(() {
        final result = _messages.cast<MessageData?>().firstWhere(
            (element) =>
                element?.optimistic == true &&
                element?.content == message.content &&
                element?.author == message.author,
            orElse: () => null);
        if (result != null) {
          result.optimistic = false;
        } else {
          _messages.add(message);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initState());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    return YaruTheme(
      data: const YaruThemeData(variant: YaruVariant.purple),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ConnectionStatus(name: widget.name),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  controller: _scrollController,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Message(message: message);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () async {
                          final files = await FilePicker.platform.pickFiles();
                          if (files != null) {
                            setState(() {
                              textEnabled = false;
                            });
                            final file = File(files.files.single.path!);

                            final request = MultipartRequest(
                                "POST", Uri.parse("$effisUrl/upload"));
                            request.fields['name'] = file.path.split('/').last;
                            request.files.add(await MultipartFile.fromPath(
                                'file', file.path));

                            final result = await request.send();
                            final data = await jsonDecode(
                                await result.stream.bytesToString());

                            final uri = Uri.parse(effisUrl);
                            _textController.text += Uri(
                              host: uri.host,
                              scheme: uri.scheme,
                              path: data["id"].toString(),
                            ).toString();

                            setState(() {
                              textEnabled = true;
                            });

                            _focusNode.requestFocus();
                          }
                        },
                        icon: const Icon(Icons.upload)),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: _textController,
                        enabled: textEnabled,
                        focusNode: _focusNode,
                        onSubmitted: (data) {
                          _sendMessage();
                          _focusNode.requestFocus();
                        },
                        decoration:
                            const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
