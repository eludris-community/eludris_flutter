import 'package:eludris/api/message.dart';
import 'package:lua_dardo/lua.dart';

void pushMessageToLua(LuaState ls, Message message) {
  ls.newTable();

  // Add content
  ls.pushString('content');
  ls.pushString(message.content);
  ls.setTable(-3);

  ls.pushString('author');
  ls.pushString(message.author);
  ls.setTable(-3);
  ls.setGlobal('message');
}
