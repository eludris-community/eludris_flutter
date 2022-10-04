import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:eludris/common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:yaru/yaru.dart';

class MissingManifest implements Exception {}

class PluginRejection implements Exception {}

const Map<String, String> permissionsExplained = {
  "READ_MESSAGES": "This plugin can read ALL messages",
  "SEND_MESSAGES": "This plugin can send messages",
  "MODIFY_MESSAGES":
      "This plugin can modify your messages before you send them",
};

class Manifest {
  final String name;
  final String version;
  final String description;
  final String author;
  final String license;
  final List<String> permissions;

  Manifest({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.license,
    required this.permissions,
  });

  static Manifest fromJson(Map<String, dynamic> json) {
    return Manifest(
        author: json['author'],
        license: json['license'],
        permissions: json['permissions'].cast<String>(),
        name: json['name'],
        version: json['version'],
        description: json['description']);
  }
}

class PluginInfo {
  late final Manifest manifest;
  late final List<String> hooks;
  late final Directory path;

  PluginInfo(
    this.path,
  ) {
    final manifestPath = File(join(path.path, 'manifest.json'));

    if (!manifestPath.existsSync()) {
      throw MissingManifest();
    }

    final manifestData = manifestPath.readAsStringSync();

    if (manifestData.isEmpty) {
      throw MissingManifest();
    }

    manifest = Manifest.fromJson(jsonDecode(manifestData));

    hooks = path
        .listSync()
        .where((element) {
          return element is File && element.path.endsWith('.lua');
        })
        .map((e) => e.path)
        .toList();
  }
}

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
  final List<PluginInfo> _plugins = [];
  final List<String> _failedPluginsInfo = [];
  String? _pluginsPath;

  Future<void> _loadPlugins() async {
    final pluginsDir = await _getPluginDir();
    if (!await pluginsDir.exists()) {
      await pluginsDir.create();
    }
    final files = <PluginInfo>[];

    for (final file in await pluginsDir.list().toList()) {
      if (file is Directory) {
        try {
          files.add(
            PluginInfo(
              file,
            ),
          );
        } on MissingManifest {
          final name = file.path.split(Platform.pathSeparator).last;
          _failedPluginsInfo.add(
              'Unable to load Plugin $name, plugin is missing a manifest file (.json)');
          await file.delete(recursive: true);
        }
      }
    }

    setState(() {
      _plugins.clear();
      _plugins.addAll(files);
    });
    if (_failedPluginsInfo.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_failedPluginsInfo.join('\n')),
      ));
      _failedPluginsInfo.clear();
    }
  }

  Future<bool> _addPlugin(PlatformFile file) async {
    Archive archive;
    if (file.extension == 'zip') {
      archive = ZipDecoder().decodeBuffer(InputFileStream(file.path!));
    } else if (file.extension == 'tar') {
      archive = TarDecoder().decodeBytes(file.bytes!);
    } else if (file.extension == 'gz') {
      final bytes = GZipDecoder().decodeBytes(file.bytes!);
      archive = TarDecoder().decodeBytes(bytes);
    } else {
      throw Exception('Unsupported file type');
    }
    final pluginsDir = await _getPluginDir();
    final pluginDir = Directory(join(
        pluginsDir.path, file.name.substring(0, file.name.lastIndexOf('.'))));
    if (await pluginDir.exists()) {
      await pluginDir.delete(recursive: true);
    }
    await pluginDir.create(recursive: true);

    final manifestStream = archive.findFile('manifest.json')?.content;

    if (manifestStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Plugin is missing a manifest file'),
      ));
      return false;
    }
    final manifest = Manifest.fromJson(jsonDecode(String.fromCharCodes(
        manifestStream is List<int>
            ? manifestStream
            : manifestStream.toList())));
    bool accepted = await _askAcceptPlugin(manifest) ?? false;

    if (!accepted) {
      await pluginDir.delete(recursive: true);
      return false;
    }

    for (final archiveFile in archive.files) {
      final filename = archiveFile.name;
      if (archiveFile.isFile) {
        final data = archiveFile.content as List<int>;
        final file = File(join(pluginDir.path, filename));
        await file.create(recursive: true);
        await file.writeAsBytes(data);
      } else {
        final dir = Directory(join(pluginDir.path, filename));
        await dir.create(recursive: true);
      }
    }

    return true;
  }

  Future<bool?> _askAcceptPlugin(Manifest manifest) async {
    final accepted = await showModalBottomSheet<bool?>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${manifest.name} - ${manifest.version}",
                  style: Theme.of(context).textTheme.bodyText1),
              Text(manifest.description),
              Text("Created by ${manifest.author} - ${manifest.license}"),
              const SizedBox(height: 8),
              Text("Permissions", style: Theme.of(context).textTheme.bodyText1),
              SizedBox(
                width: 400,
                child: Column(
                  children: manifest.permissions
                      .map(
                        (e) => Row(
                          children: [
                            Text(e),
                            const Spacer(),
                            Text(permissionsExplained[e]!)
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Discard"),
                )),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Add"),
                  ),
                ),
              ])
            ],
          ),
        );
      },
    );
    return accepted;
  }

  @override
  void initState() {
    super.initState();
    _getPluginDir().then((value) => setState(() {
          _pluginsPath = value.path;
        }));
    _loadPlugins();
  }

  @override
  Widget build(BuildContext context) {
    // show snackbar with _failedPluginsInfo

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Plugins',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                          const Spacer(),
                          IconButton(
                              onPressed: () async {
                                await requestFilePermissions();
                                final file = (await FilePicker.platform
                                        .pickFiles(
                                            withData: true,
                                            allowedExtensions: [
                                              "zip",
                                              "tar",
                                              "gz"
                                            ],
                                            type: FileType.custom))
                                    ?.files
                                    .single;
                                if (file == null) return;
                                if (await _addPlugin(file)) {
                                  _loadPlugins();
                                }
                              },
                              icon: const Icon(Icons.add))
                        ],
                      ),
                      Text("Path: $_pluginsPath"),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final plugin in _plugins)
                      Plugin(
                        plugin,
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
    final pluginsDir = Directory(join(appDocDir.path, 'plugins'));
    return pluginsDir;
  }
}

class Plugin extends StatelessWidget {
  final PluginInfo plugin;
  final Function onDeleted;

  const Plugin(
    this.plugin,
    this.onDeleted, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(plugin.manifest.name),
        subtitle: Text(plugin.manifest.description),
        trailing: IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              Directory(plugin.path.path)
                  .delete(recursive: true)
                  .then((value) => onDeleted());
            }),
      ),
    );
  }
}
