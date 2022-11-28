import 'package:eludris/lua/api.dart';
import 'package:eludris/lua/message.dart';
import 'package:eludris/models/gateway/message.dart';
import 'package:lua_dardo/lua.dart';

void pushToLua<T>(LuaState ls, String varName, String className, T object) {
  Userdata u = ls.newUserdata<T>();
  u.data = object;
  ls.getMetatableAux("${className}Class");
  ls.setMetatable(-2);
  ls.setGlobal(varName);
}

LuaState prepareLua([LuaAPI? api, MessageData? message]) {
  final ls = LuaState.newState();
  ls.openLibs();

  if (api != null) {
    LuaAPI.require(ls);
    pushToLua<LuaAPI>(ls, "api", "API", api);
  }

  if (message != null) {
    pushMessageToLua(ls, message);
  }
  return ls;
}
