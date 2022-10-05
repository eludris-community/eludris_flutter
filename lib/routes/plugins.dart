import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:eludris/common.dart';
import 'package:eludris/lua/manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:yaru/yaru.dart';

const Map<String, String> permissionsExplained = {
  "READ_MESSAGES": "This plugin can read ALL messages",
  "SEND_MESSAGES": "This plugin can send messages",
  "MODIFY_MESSAGES":
      "This plugin can modify your messages before you send them",
};

class Plugins extends StatefulWidget {
  const Plugins({
    Key? key,
  }) : super(key: key);

  @override
  State<Plugins> createState() => _PluginsState();
}

enum PluginState { enabled, disabled, missingManifest }

class _PluginsState extends State<Plugins> {
  final manager = PluginManager();

  Future<void> _loadPlugins() async {
    await manager.loadPlugins();
    setState(() {});
  }

  Future<PluginState> _addPlugin(PlatformFile file) async {
    await manager.addPlugin(path.basenameWithoutExtension(file.name), file);
    final dir =
        await manager.getPluginDir(path.basenameWithoutExtension(file.name));
    final manifest = await manager.getManifest(dir.path);

    if (manifest == null) {
      return PluginState.missingManifest;
    }

    bool accepted = await _askAcceptPlugin(manifest) ?? false;
    if (!accepted) {
      manager.deletePlugin(path: file.path!, reload: false);
      return PluginState.disabled;
    } else {
      await manager.loadPlugins();
    }

    return PluginState.enabled;
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Column(
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
                          onPressed: () {
                            requestFilePermissions();
                            FilePicker.platform
                                .pickFiles(
                                    withData: true,
                                    allowedExtensions: ["zip", "tar", "gz"],
                                    type: FileType.custom)
                                .then((result) {
                              final file = result?.files.first;
                              if (file == null) return;
                              _addPlugin(file).then((accepted) {
                                if (accepted == PluginState.enabled) {
                                  _loadPlugins();
                                } else if (accepted ==
                                    PluginState.missingManifest) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Cannot load plugin - invalid manifest'),
                                  ));
                                }
                              });
                            });
                          },
                          icon: const Icon(Icons.add))
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: manager.plugins
                      .map((p) => Plugin(p, _loadPlugins))
                      .toList(),
                ),
              )
            ],
          ),
        ),
      ),
    );
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
              plugin.delete();
              onDeleted();
            }),
      ),
    );
  }
}
