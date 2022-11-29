import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';

final getIt = GetIt.instance;

Future<void> requestFilePermissions() async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return;
    }
  }
}

class APIConfig {
  get httpUrl =>
      getIt<SharedPreferences>().getString('http-url') ?? defaultHttpUrl;
  get wsUrl =>
      getIt<SharedPreferences>().getString('gateway-url') ?? defaultWsUrl;
  get effisUrl =>
      getIt<SharedPreferences>().getString('effis-url') ?? defaultEffisUrl;

  static const defaultHttpUrl = 'https://eludris.tooty.xyz';
  static const defaultWsUrl = 'wss://eludris.tooty.xyz/ws/';
  static const defaultEffisUrl = 'https://effis.tooty.xyz';
}

extension CustomTheme on ThemeData {
  ThemeData withCustom() {
    return copyWith(useMaterial3: true, visualDensity: VisualDensity.standard);
  }
}

final themeDark = yaruPurpleDark.withCustom();
final themeLight = yaruPurpleLight.withCustom();
