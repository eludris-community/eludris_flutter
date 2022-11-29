import 'package:eludris/common.dart';
import 'package:eludris/lua/manager.dart'
    if (dart.library.html) 'package:eludris/lua/web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

final getIt = GetIt.instance;

const Map<String, String> permissionsExplained = {
  "READ_MESSAGES": "This plugin can read ALL messages",
  "SEND_MESSAGES": "This plugin can send messages",
  "MODIFY_MESSAGES":
      "This plugin can modify your messages before you send them",
};

const unknownPermissionWarning = Text(
  "Unknown permission. Update your app or contact the plugin author.",
  style: TextStyle(color: Colors.yellow),
);

class Permission extends StatelessWidget {
  final String permission;
  const Permission(this.permission, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(permission, style: const TextStyle(fontWeight: FontWeight.bold)),
        permissionsExplained.containsKey(permission)
            ? Text(permissionsExplained[permission]!)
            : unknownPermissionWarning
      ],
    );
  }
}

class Hook extends StatelessWidget {
  final PluginInfo plugin;
  final String name;

  static Map<String, String> hooks = {
    "postGotMessage": "Ran after receiving a message",
    "preSendMessage": "Ran before sending a message",
  };
  static TextStyle cannotRunStyle = const TextStyle(
      color: Colors.grey, decoration: TextDecoration.lineThrough);
  const Hook(this.name, this.plugin, {super.key});

  @override
  Widget build(BuildContext context) {
    final canRun = plugin.canRun(name);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ).merge(!canRun ? cannotRunStyle : null),
            ),
            Text(hooks[name]!,
                style:
                    const TextStyle().merge(!canRun ? cannotRunStyle : null)),
          ],
        ),
        if (!canRun)
          const Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            message: "This hook is disabled because its missing permission",
            child: Icon(
              Icons.warning,
            ),
          )
      ],
    );
  }
}

class Plugins extends StatefulWidget {
  const Plugins({
    Key? key,
  }) : super(key: key);

  @override
  State<Plugins> createState() => _PluginsState();
}

enum PluginState { enabled, disabled, missingManifest }

class _PluginsState extends State<Plugins> {
  Future<void> _loadPlugins() async {
    await getIt<PluginManager>().loadPlugins();
    setState(() {});
  }

  Future<PluginState> _addPlugin(PlatformFile file) async {
    await getIt<PluginManager>()
        .addPlugin(path.basenameWithoutExtension(file.name), file);
    final dir = await getIt<PluginManager>()
        .getPluginDir(path.basenameWithoutExtension(file.name));
    final manifest = await getIt<PluginManager>().getManifest(dir.path);

    if (manifest == null) {
      return PluginState.missingManifest;
    }
    final plugin = PluginInfo(dir, getIt<PluginManager>());

    bool accepted = await _askAcceptPlugin(plugin) ?? false;
    if (!accepted) {
      plugin.delete();
      return PluginState.disabled;
    } else {
      await getIt<PluginManager>().loadPlugins();
    }

    return PluginState.enabled;
  }

  Future<bool?> _askAcceptPlugin(PluginInfo plugin) async {
    final accepted = await Navigator.of(context).push<bool?>(MaterialPageRoute(
      builder: (context) {
        return DefaultYaru(
          AskPlugin(plugin),
        );
      },
    ));
    return accepted;
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
                          onPressed: () => _pickPlugin(context),
                          icon: const Icon(Icons.add))
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: getIt<PluginManager>()
                      .plugins
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

  void _pickPlugin(BuildContext context) async {
    requestFilePermissions();
    await FilePicker.platform.clearTemporaryFiles().catchError((e) {});

    final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowedExtensions: ["zip", "tar", "gz"],
        type: FileType.custom);

    final file = result?.files.first;
    if (file == null) return;
    final accepted = await _addPlugin(file);

    if (accepted == PluginState.enabled) {
      _loadPlugins();
    } else if (accepted == PluginState.missingManifest) {
      if (mounted) {
        // Because this is async, the widget might be disposed
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot load plugin - invalid manifest'),
        ));
      }
    }
  }
}

class AskPlugin extends StatelessWidget {
  final PluginInfo plugin;

  const AskPlugin(this.plugin, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              AboutPlugin(plugin),
              const Spacer(),
              DiscardAddPlugin(plugin.manifest),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutPlugin extends StatelessWidget {
  final PluginInfo plugin;
  const AboutPlugin(
    this.plugin, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${plugin.manifest.name} - ${plugin.manifest.version}",
              style: Theme.of(context).textTheme.headline5),
          Text(plugin.manifest.description),
          Text(
              "Created by ${plugin.manifest.author} - ${plugin.manifest.license}"),
          const SizedBox(height: 20),
          Text("Permissions", style: Theme.of(context).textTheme.headline5),
          Column(
            children: plugin.manifest.permissions
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Permission(e),
                    ))
                .toList(),
          ),
          Text("Hooks", style: Theme.of(context).textTheme.headline5),
          Column(
            children: plugin.hooks
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Hook(e, plugin),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DiscardAddPlugin extends StatefulWidget {
  final Manifest manifest;
  const DiscardAddPlugin(this.manifest, {super.key});

  @override
  State<DiscardAddPlugin> createState() => _DiscardAddPluginState();
}

class _DiscardAddPluginState extends State<DiscardAddPlugin> {
  bool ignoredUnknownPermissions = false;
  @override
  Widget build(BuildContext context) {
    final hasUnknownPermissions = widget.manifest.permissions
        .where((p) => !permissionsExplained.containsKey(p))
        .isNotEmpty;
    return Column(
      children: [
        ignoredUnknownPermissions
            ? const Text(
                "No support will be provided for this plugin. Use at your own risk.",
                style: TextStyle(color: Colors.red),
              )
            : Container(),
        Row(children: [
          Expanded(
              child: ElevatedButton.icon(
            onLongPress: hasUnknownPermissions
                ? () {
                    setState(() {
                      ignoredUnknownPermissions = !ignoredUnknownPermissions;
                    });
                  }
                : null,
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: const Icon(Icons.close),
            label: const Text("Discard"),
          )),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: hasUnknownPermissions
                  ? "This plugin has unknown permissions. Update your app or contact the plugin author."
                  : "",
              child: ElevatedButton.icon(
                style: ignoredUnknownPermissions
                    ? ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.grey[700]))
                    : null,
                onPressed: hasUnknownPermissions && !ignoredUnknownPermissions
                    ? null
                    : () {
                        Navigator.of(context).pop(true);
                      },
                icon: const Icon(Icons.check),
                label: const Text("Add"),
              ),
            ),
          ),
        ])
      ],
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
    final hasUnknownPermissions = plugin.manifest.permissions
        .where((p) => !permissionsExplained.containsKey(p))
        .isNotEmpty;

    return Card(
      child: ListTile(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (context) {
          return DefaultYaru(Scaffold(
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
                        AboutPlugin(plugin),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            plugin.delete();
                            onDeleted();
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.red)),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text("Delete"),
                        )
                      ],
                    )),
              )));
        })),
        title: Text(plugin.manifest.name),
        subtitle: Text(plugin.manifest.description),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: hasUnknownPermissions
                    ? "This plugin has unknown permissions. Update your app or contact the plugin author."
                    : "",
                child: Icon(hasUnknownPermissions
                    ? Icons.error_outline
                    : Icons.extension),
              ),
            ],
          ),
        ),
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
