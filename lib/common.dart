import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<void> requestFilePermissions() async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return;
    }
  }
}
