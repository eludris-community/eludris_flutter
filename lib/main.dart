import 'package:eludris/common.dart';
import 'package:eludris/lua/manager.dart'
    if (dart.library.html) 'package:eludris/lua/web.dart';
import 'package:eludris/routes/home.dart';
import 'package:eludris/routes/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  runApp(const App());

  if (!kIsWeb) {
    getIt.registerSingleton<PluginManager>(PluginManager());
  }
  getIt.registerSingleton<APIConfig>(APIConfig());
  getIt.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eludris',
      home: const HomePage(),
      theme: themeLight,
      darkTheme: themeDark,
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
