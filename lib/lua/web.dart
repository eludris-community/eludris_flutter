import 'package:flutter/cupertino.dart';

class PluginManager {
  final List<dynamic> plugins = [];

  dynamic loadPlugins() {}
}

class Plugins extends StatelessWidget {
  const Plugins({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Plugins are not supported on the web.');
  }
}
