import 'package:eludris/models/gateway/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as markdown;

class Message extends StatelessWidget {
  final MessageData message;
  final bool displayAuthor;

  const Message({
    Key? key,
    required this.displayAuthor,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ([
                displayAuthor
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Text(
                          message.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Container(),
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
              ]),
            ),
          ),
          if (message.plugin != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: "This message was created by ${message.plugin}",
                child: const Icon(Icons.extension),
              ),
            )
        ],
      ),
    );
  }
}
