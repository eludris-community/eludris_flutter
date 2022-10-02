import 'package:eludris/models/gateway/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as markdown;

class Message extends StatelessWidget {
  const Message({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageData message;

  @override
  Widget build(BuildContext context) {
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
                      bodyColor: message.optimistic ? Colors.grey : null,
                    ),
              ),
              child: MarkdownBody(
                  data: message.content,
                  extensionSet: markdown.ExtensionSet(
                      markdown.ExtensionSet.gitHubFlavored.blockSyntaxes, [
                    ...markdown.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                    markdown.EmojiSyntax()
                  ])),
            ),
          ],
        ),
      ),
    );
  }
}
