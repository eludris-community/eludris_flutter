import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eludris/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:http/http.dart' show post;

void main() {
  runApp(const MyApp());
}

class Message {
  late final String author;
  late bool optimistic;
  late String content;

  Message(this.author, this.content, this.optimistic);

  Message.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    author = map['author'];
    content = map['content'];
    optimistic = false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: YaruTheme(
        data: YaruThemeData(variant: YaruVariant.purple),
        child: MyHomePage(),
      ),
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
      floatingActionButton: name != null
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SettingsRoute()));
              },
              child: const Icon(Icons.settings),
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
  StreamSubscription? _stream;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

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
      _messages.add(Message(widget.name, text, true));
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
    httpUrl = prefs.getString('http-url') ?? 'https://eludris.tooty.xyz';
    gatewayUrl = prefs.getString('gateway-url') ?? 'wss://eludris.tooty.xyz/ws';

    final ws = await WebSocket.connect(gatewayUrl);
    ws.pingInterval = const Duration(seconds: 10);
    _stream = ws.listen((event) {
      final message = Message.fromJson(event);
      setState(() {
        final result = _messages.cast<Message?>().firstWhere(
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ConnectionStatus(name: widget.name),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onLogout,
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.apply(
                                bodyColor:
                                    message.optimistic ? Colors.grey : null,
                              ),
                        ),
                        child: MarkdownBody(
                            data: message.content,
                            extensionSet: md.ExtensionSet(
                                md.ExtensionSet.gitHubFlavored.blockSyntaxes, [
                              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                              md.EmojiSyntax()
                            ])),
                      ),
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
