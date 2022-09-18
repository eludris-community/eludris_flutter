import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaru/yaru.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      data: const YaruThemeData(variant: YaruVariant.purple),
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.save),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<SharedPreferences>(future: Future(() async {
              return await SharedPreferences.getInstance();
            }), builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Icon(Icons.heart_broken);
              }
              if (!snapshot.hasData) {
                return const Icon(Icons.hourglass_empty);
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: snapshot.data!.getString("http-url"),
                    decoration: const InputDecoration(
                      labelText: 'HTTP URL',
                      hintText: 'https://eludris.tooty.xyz/',
                    ),
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString("http-url", value);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    initialValue: snapshot.data!.getString("gateway-url"),
                    decoration: const InputDecoration(
                      labelText: 'Gateway URL',
                      hintText: 'https://eludris.tooty.xyz/messages',
                    ),
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString("gateway-url", value);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    initialValue: snapshot.data!.getString("effis-url"),
                    decoration: const InputDecoration(
                      labelText: 'Effis URL',
                      hintText: 'https://effis.tooty.xyz/',
                    ),
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString("effis-url", value);
                    },
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
