import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaru/yaru.dart';

Future<void> requestFilePermissions() async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return;
    }
  }
}

class DefaultYaru extends StatelessWidget {
  final Widget child;
  const DefaultYaru(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      data: YaruThemeData(variant: YaruVariant.purple),
      child: child,
    );
  }
}
