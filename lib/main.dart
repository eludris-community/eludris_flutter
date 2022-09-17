import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:yaru/yaru.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:http/http.dart' show post;

void main() {
  runApp(const MyApp());
}

class Message {
  late final String author;
  late String content;

  Message(this.author, this.content);

  Message.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    author = map['author'];
    content = map['content'];
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: YaruTheme(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: name == null
            ? NeedsLogin((String pName) {
                setState(() {
                  name = pName;
                });
              })
            : LoggedIn(name!, () {
                setState(() {
                  name = null;
                });
              }),
      ),
    );
  }
}

class NeedsLogin extends StatelessWidget {
  final dynamic Function(String) onSubmit;
  final TextEditingController _controller = TextEditingController();

  NeedsLogin(this.onSubmit, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String value) {
                  onSubmit(value);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                child: const Text('Login'),
                onPressed: () {
                  onSubmit(_controller.text);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoggedIn extends StatefulWidget {
  final String name;
  final dynamic Function() onLogout;
  const LoggedIn(
    this.name,
    this.onLogout, {
    Key? key,
  }) : super(key: key);

  @override
  State<LoggedIn> createState() => _LoggedInState();
}

class _LoggedInState extends State<LoggedIn> {
  final _messages = <Message>[];
  StreamSubscription? _steam;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textController.dispose();
    _scrollController.dispose();
    _steam?.cancel();
    super.dispose();
  }

  _sendMessage() async {
    await post(
      Uri.parse('https://eludris.tooty.xyz/messages'),
      body: jsonEncode({
        'author': widget.name,
        'content': _textController.text,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    _textController.clear();
  }

  _initState() async {
    final ws = await WebSocket.connect('wss://eludris.tooty.xyz/ws');
    ws.pingInterval = const Duration(seconds: 10);
    _steam = ws.listen((event) {
      final message = Message.fromJson(event);
      setState(() {
        _messages.add(message);
        // scroll to bottom
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initState();
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
    return Column(
      children: [
        Row(
          children: [
            Text('Logged in as ${widget.name}'),
            ElevatedButton(
              child: Text('Logout'),
              onPressed: widget.onLogout,
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            controller: _scrollController,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.author,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      MarkdownBody(
                          data: message.content,
                          extensionSet: md.ExtensionSet(
                              md.ExtensionSet.gitHubFlavored.blockSyntaxes, [
                            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                            md.EmojiSyntax()
                          ])),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: _textController,
                  onSubmitted: (data) {
                    _sendMessage();
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
    );
  }
}
