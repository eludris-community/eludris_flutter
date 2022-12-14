import 'package:eludris/api/gateway.dart';
import 'package:eludris/api/http.dart';
import 'package:flutter/foundation.dart';

import 'package:eludris/common.dart';
import 'package:eludris/lua/manager.dart'
    if (dart.library.html) 'package:eludris/lua/web.dart';
import 'package:eludris/api/message.dart';
import 'package:eludris/widgets/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' show MultipartRequest, MultipartFile;
import 'package:flutter/material.dart';

final getIt = GetIt.instance;

class ConnectionStatus extends StatelessWidget {
  final String name;

  const ConnectionStatus({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = getIt<APIConfig>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connected as $name'),
        Text('Using ${Uri.parse(config.httpUrl).host}')
      ],
    );
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
  APIConfig get _config => getIt<APIConfig>();

  final _gw = Gateway(url: getIt<APIConfig>().wsUrl);
  final _http = HTTP(baseUrl: getIt<APIConfig>().httpUrl);

  final _messages = <Message>[];

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _textEnabled = true;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    _scrollController.dispose();
    _gw.dispose();
    super.dispose();
  }

  _sendMessage() async {
    final String text = _textController.text;
    _textController.clear();

    final message = Message(widget.name, text, true);

    if (!kIsWeb) {
      for (final plugin in getIt<PluginManager>().plugins) {
        final messages =
            plugin.runPreSendMessage(http: _config.httpUrl, message: message);
        setState(() => _messages.addAll(messages));
      }
    }

    setState(() {
      _messages.add(message);
    });

    await _http.createMessage(widget.name, text);
  }

  _initState() async {
    await _gw.connect();
    _gw.onMessageCreate.stream.listen(_wsListen);
  }

  void _wsListen(Message message) {
    final result = _messages.cast<Message?>().firstWhere(
        (element) =>
            element!.optimistic == true &&
            element.content == message.content &&
            element.author == message.author,
        orElse: () => null);

    setState(() {
      if (result != null) {
        result.optimistic = false;
      } else {
        _messages.add(message);
      }
    });

    if (!kIsWeb) {
      for (final plugin in getIt<PluginManager>().plugins) {
        if (plugin.hooks.contains('postGotMessage') &&
            plugin.manifest.permissions.contains('READ_MESSAGES')) {
          final pMessages =
              plugin.runPostGotMessage(http: _config.httpUrl, message: message);
          setState(() {
            _messages.addAll(pMessages);
          });
        }
      }
    }
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

    return Scaffold(
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
                  var displayAuthor = index == 0 ||
                      _messages[index - 1].author != message.author;
                  return MessageWidget(
                    message: message,
                    displayAuthor: displayAuthor,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () async {
                        requestFilePermissions();
                        final files = await FilePicker.platform.pickFiles();
                        if (files != null) {
                          setState(() {
                            _textEnabled = false;
                          });
                          final file = files.files.first;

                          final request = MultipartRequest(
                              "POST", Uri.parse("${_config.effisUrl}/upload"));
                          request.fields['name'] = file.name;
                          request.files.add(MultipartFile.fromBytes(
                            'file',
                            file.bytes!,
                            filename: file.name,
                          ));

                          final result = await request.send();
                          final data = await result.stream.bytesToString();
                          final match =
                              RegExp(r"\d+").firstMatch(data)!.group(0);

                          final uri = Uri.parse(_config.effisUrl);
                          _textController.text += Uri(
                            host: uri.host,
                            scheme: uri.scheme,
                            path: match!,
                          ).toString();

                          setState(() {
                            _textEnabled = true;
                          });

                          _focusNode.requestFocus();
                        }
                      },
                      icon: const Icon(Icons.upload)),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _textController,
                      enabled: _textEnabled,
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
    );
  }
}
