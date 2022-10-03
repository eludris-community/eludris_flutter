import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaru/yaru.dart';

class PluginsRoute extends StatelessWidget {
  const PluginsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const YaruTheme(
      data: YaruThemeData(variant: YaruVariant.purple),
      child: PluginsScaffold(),
    );
  }
}

class PluginsScaffold extends StatefulWidget {
  const PluginsScaffold({
    Key? key,
  }) : super(key: key);

  @override
  State<PluginsScaffold> createState() => _PluginsScaffoldState();
}

class _PluginsScaffoldState extends State<PluginsScaffold> {
  final List<FileSystemEntity> _plugins = [];

  Future<void> _loadPlugins() async {
    final pluginsDir = await _getPluginDir();
    if (!pluginsDir.existsSync()) {
      pluginsDir.createSync();
    }
    final files = pluginsDir.listSync();
    setState(() {
      _plugins.clear();
      _plugins.addAll(files);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Plugins',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      const Spacer(),
                      IconButton(
                          onPressed: () async {
                            final file = (await FilePicker.platform.pickFiles(
                                    withData: true,
                                    allowedExtensions: ["zip"],
                                    type: FileType.custom))
                                ?.files
                                .single;
                            if (file == null) return;
                            final pluginsDir = await _getPluginDir();
                            await pluginsDir.create();
                            // Copy the file into appDocDir
                            final fileToSave =
                                File('${pluginsDir.path}/${file.name}');
                            await fileToSave.writeAsBytes(file.bytes!);
                            _loadPlugins();
                          },
                          icon: const Icon(Icons.add))
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final plugin in _plugins)
                      Plugin(
                        'Plugin ${plugin.path.split(Platform.pathSeparator).last}',
                        'Description of plugin ${plugin.path.split(Platform.pathSeparator).last}',
                        plugin.path,
                        _loadPlugins,
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Directory> _getPluginDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final pluginsDir =
        Directory('${appDocDir.path}${Platform.pathSeparator}plugins');
    return pluginsDir;
  }
}

class Plugin extends StatelessWidget {
  final String name;
  final String description;
  final String path;
  final Function onDeleted;

  const Plugin(
    this.name,
    this.description,
    this.path,
    this.onDeleted, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(description),
        trailing: IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              File(path).delete();
              onDeleted();
            }),
      ),
    );
  }
}
