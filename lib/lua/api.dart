import 'package:eludris/api/http.dart';
import 'package:eludris/lua/manager.dart';
import 'package:eludris/api/message.dart';
import 'package:lua_dardo/lua.dart';

class LuaAPI {
  final API api;
  bool rejected = false;
  final Message? message;

  LuaAPI(this.api, {this.message});

  static const Map<String, DartFunction> _registry = {};
  static const Map<String, DartFunction> _apiMember = {
    "sendMessage": _sendMessage,
    "rejectMessage": _rejectMessage,
    "updateMessage": _updateMessage,
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

  static int _updateMessage(LuaState ls) {
    final api = _getThis(ls);
    final String content = ls.checkString(2)!;
    final String author = ls.checkString(3)!;
    if (api.message != null) {
      api.api.updateMessage(api.message!, content: content, author: author);
    }

    return 0;
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
  final PluginInfo plugin;
  final List<Message> messages = [];
  final HTTP http;

  API({required this.http, required this.plugin});

  void sendMessage(String content, String author) async {
    if (!plugin.manifest.permissions.contains("SEND_MESSAGES")) {
      throw Exception("Plugin does not have permission to send messages");
    }
    messages.add(Message(author, content, true, plugin: plugin.manifest.name));

    http.createMessage(author, content);
  }

  void updateMessage(Message message, {String? content, String? author}) {
    if (!plugin.manifest.permissions.contains("MODIFY_MESSAGES")) {
      throw Exception("Plugin does not have permission to modify messages");
    }
    if (content != null) {
      message.content = content;
    }
    if (author != null) {
      message.author = author;
    }
  }
}
