import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

class SembastUserLastChat {
  static SembastUserLastChat _sembastUserLastChat;

  factory SembastUserLastChat() =>
      _sembastUserLastChat ??= SembastUserLastChat._();

  SembastUserLastChat._();

  static const USER_LAST_CHAT_STORE = 'lastchatStore';

  static final Lock lock = Lock();

  final _userLastChatStore = intMapStoreFactory.store(USER_LAST_CHAT_STORE);

  Future<ChatModel> getLastUserChat(String toUserId) async {
    final finder = Finder(filter: Filter.and(
      [
        Filter.equals('toUserId', toUserId),
        Filter.equals('delStat', ChatModel.READ_BY_USER)
      ]
    ));
    RecordSnapshot rs = await _userLastChatStore
        .findFirst(await SembastDatabase().getDatabase(), finder: finder);
    if (rs != null && rs['id'] != null) {
      return ChatModel.fromRecordSnapshot(rs);
    }
    return null;
  }

  Future upsertUserLastChat(ChatModel chat) async {
    await lock.synchronized(() async {
      String toUserId = (UserBloc().getCurrUser().id == chat.fromUserId)
          ? chat.toUserId
          : chat.fromUserId;
      final finder = Finder(filter: Filter.equals('toUserId', toUserId));
      int key;
      RecordSnapshot rs = await _userLastChatStore
          .findFirst(await SembastDatabase().getDatabase(), finder: finder);
      if (rs != null && rs['toUserId'] != null) {
        key = rs.key;
      } else {
        key = DateTime.now().microsecondsSinceEpoch;
        chat.chatDate = DateTime.now().millisecondsSinceEpoch;
      }
      _userLastChatStore
          .record(key)
          .put(await SembastDatabase().getDatabase(), chat.toJson()).then((_) {
                  ChatListener().addToController(toUserId, chat);
          });
    });
  }

  Future deleteAllLastChats() async {
       return await _userLastChatStore.delete(await SembastDatabase().getDatabase());
  }
}
