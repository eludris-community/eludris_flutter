import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class MissingManifest implements Exception {}

class PluginRejection implements Exception {}

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
  late final PluginManager manager;
  late final Manifest manifest;
  late final List<String> hooks;
  late final Directory path;

  PluginInfo(this.path, this.manager) {
    final manifestPath = File(join(path.path, 'manifest.json'));

    if (!manifestPath.existsSync()) {
      delete(reload: true);
    }

    final manifestData = manifestPath.readAsStringSync();

    if (manifestData.isEmpty) {
      delete(reload: true);
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

  void delete({bool reload = true}) {
    manager.deletePlugin(reload: reload, plugin: this);
  }
}

class PluginManager {
  final List<PluginInfo> _plugins = [];

  List<PluginInfo> get plugins => List.unmodifiable(_plugins);

  Future<Directory> _getPluginsDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final pluginsDir = Directory(join(appDocDir.path, 'plugins'));
    return pluginsDir;
  }

  Future<Directory> getPluginDir(String name) async {
    final pluginsDir = await _getPluginsDir();
    final pluginDir = Directory(join(pluginsDir.path, name));
    return pluginDir;
  }

  Future<void> deletePlugin(
      {bool reload = true, PluginInfo? plugin, String? path}) async {
    if (plugin == null && path == null) {
      throw ArgumentError('Either plugin or path must be provided');
    }

    final pluginDir = plugin?.path ?? await getPluginDir(path!);

    if (await pluginDir.exists()) {
      await pluginDir.delete(recursive: true);
    }

    if (reload) {
      await loadPlugins();
    }
  }

  Future<Manifest?> getManifest(String path) async {
    String contents;
    try {
      contents = await File(join(path, 'manifest.json')).readAsString();
    } on FileSystemException {
      return null;
    }

    final manifest = Manifest.fromJson(jsonDecode(contents));

    return manifest;
  }

  Future<Archive> _getArchive(PlatformFile file) async {
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
    final pluginsDir = await _getPluginsDir();
    final pluginDir = Directory(join(
        pluginsDir.path, file.name.substring(0, file.name.lastIndexOf('.'))));
    if (await pluginDir.exists()) {
      await pluginDir.delete(recursive: true);
    }
    await pluginDir.create(recursive: true);
    return archive;
  }

  Future<bool?> addPlugin(String pluginName, PlatformFile file) async {
    final pluginDir = await getPluginDir(pluginName);
    final archive = await _getArchive(file);

    await _extract(archive, pluginDir);

    return true;
  }

  Future<void> _extract(Archive archive, Directory pluginDir) async {
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
  }

  Future<void> loadPlugins() async {
    final pluginsDir = await _getPluginsDir();

    _plugins.clear();
    for (final event in await pluginsDir.list().toList()) {
      if (event is Directory) {
        final plugin = PluginInfo(event, this);
        _plugins.add(plugin);
      }
    }
  }
}
