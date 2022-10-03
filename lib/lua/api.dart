import 'dart:convert';

import 'package:lua_dardo/lua.dart';
import 'package:http/http.dart' show post;

class LuaAPI {
  final API api;
  bool rejected = false;

  LuaAPI(this.api);

  static const Map<String, DartFunction> _registry = {};
  static const Map<String, DartFunction> _apiMember = {
    "sendMessage": _sendMessage,
    "rejectMessage": _rejectMessage
  };

  static LuaAPI _getThis(LuaState ls) => ls.toUserdata<LuaAPI>(1)!.data;

  static int _openAPILib(LuaState ls) {
    ls.newMetatable("APIClass");
    ls.pushValue(-1);
    ls.setField(-2, "__index");
    ls.setFuncs(_apiMember, 0);

    ls.newLib(_registry);
    return 1;
  }

  static int _rejectMessage(LuaState ls) {
    _getThis(ls).rejected = true;
    return 0;
  }

  static int _sendMessage(LuaState ls) {
    LuaAPI luaAPI = _getThis(ls);
    String content = ls.checkString(2)!;
    String author = ls.checkString(3)!;

    luaAPI.api.sendMessage(content, author);
    return 0;
  }

  static void require(LuaState ls) {
    ls.requireF("API", _openAPILib, true);
    ls.pop(1);
  }
}

class API {
  void sendMessage(String content, String author) async {
    await post(Uri.parse("https://eludris.tooty.xyz/messages"),
        body: jsonEncode({"content": content, "author": author}),
        headers: {
          "Content-Type": "application/json",
        });
  }
}
