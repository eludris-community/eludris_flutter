import 'package:eludris/common.dart';
import 'package:eludris/routes/plugins.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';

final getIt = GetIt.instance;

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  APIConfig get _config => getIt<APIConfig>();
  get _prefs => getIt<SharedPreferences>();

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      data: const YaruThemeData(variant: YaruVariant.purple),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.save),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Input(
                    label: "HTTP URL",
                    hint: APIConfig.defaultHttpUrl,
                    prefsKey: "http-url",
                    initialValue: _config.httpUrl),
                const SizedBox(height: 8.0),
                Input(
                    label: "Gateway URL",
                    hint: APIConfig.defaultWsUrl,
                    prefsKey: "gateway-url",
                    initialValue: _config.wsUrl),
                const SizedBox(height: 8.0),
                Input(
                    label: "Effis URL",
                    hint: APIConfig.defaultEffisUrl,
                    prefsKey: "effis-url",
                    initialValue: _config.effisUrl),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const DefaultYaru(Plugins())));
                        },
                        child: const Text("Plugin Settings")),
                    const Spacer(),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Input extends StatelessWidget {
  final String label;
  final String hint;
  final String prefsKey;
  final String initialValue;

  const Input(
      {required this.label,
      required this.hint,
      required this.prefsKey,
      required this.initialValue,
      super.key});
  APIConfig get _config => getIt<APIConfig>();
  SharedPreferences get _prefs => getIt<SharedPreferences>();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      onChanged: (value) => _prefs.setString(prefsKey, value),
    );
  }
}
