import 'package:eludris/common.dart';
import 'package:eludris/lua/manager.dart'
    if (dart.library.html) 'package:eludris/lua/web.dart';
import 'package:eludris/routes/home.dart';
import 'package:eludris/routes/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  if (!kIsWeb) {
    getIt.registerSingleton<PluginManager>(PluginManager());
  }
  getIt.registerSingleton<APIConfig>(APIConfig());
  getIt.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Eludris',
      home: YaruTheme(
        data: YaruThemeData(variant: YaruVariant.purple),
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Home()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsRoute()));
        },
        child: const Icon(Icons.settings),
      ),
    );
  }
}
