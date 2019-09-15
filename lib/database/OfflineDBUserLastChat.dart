import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/OfflineDBDatabase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

class OfflineDBUserLastChat {
  static OfflineDBUserLastChat _sembastUserLastChat;

  factory OfflineDBUserLastChat() =>
      _sembastUserLastChat ??= OfflineDBUserLastChat._();

  OfflineDBUserLastChat._();

  static const USER_LAST_CHAT_STORE = 'lastchatStore';

  static final Lock lock = Lock();

  final _userLastChatStore = intMapStoreFactory.store(USER_LAST_CHAT_STORE);

  Future<ChatModel> getLastUserChat(String toUserId) async {
    final finder = Finder(filter: Filter.equals('toUserId', toUserId));
    RecordSnapshot rs = await _userLastChatStore
        .findFirst(await OfflineDBDatabase().getDatabase(), finder: finder);
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
      if (chat.isD) {
        final finder = Finder(filter: Filter.equals('id', chat.id));
        _userLastChatStore
            .update(await OfflineDBDatabase().getDatabase(),
                chat.toDeleteJson(chat.ts,chat.chatDate, false),
                finder: finder)
            .then((count) {
          if (count > 0) {
            ChatListener().addToController(toUserId, chat);
          }
        });
      } else {
        final finder = Finder(
            filter: Filter.or([
          Filter.equals('toUserId', toUserId),
          Filter.equals('fromUserId', toUserId)
        ]));
        int key;
        RecordSnapshot rs = await _userLastChatStore
            .findFirst(await OfflineDBDatabase().getDatabase(), finder: finder);
        if (rs != null) {
          key = rs.key;
          if (chat.chatDate.compareTo(rs['chatDate']) < 0) {
            return;
          }
        } else {
          key = DateTime.now().microsecondsSinceEpoch;
        }
        _userLastChatStore
            .record(key)
            .put(await OfflineDBDatabase().getDatabase(), chat.toJson())
            .then((map) {
          ChatListener().addToController(toUserId, chat);
        });
      }
    });
  }

  Future deleteAllLastChats() async {
    return await _userLastChatStore
        .delete(await OfflineDBDatabase().getDatabase());
  }

  Future updateLastChatDelivery(int chatId, String value) async {
    final finder = Finder(filter: Filter.equals('id', chatId));
    RecordSnapshot rs = await _userLastChatStore
        .findFirst(await OfflineDBDatabase().getDatabase(), finder: finder);
    if (null != rs) {}

    if (rs != null &&
        (rs['delStat'] == null ||
            (rs['delStat'] != null && value.compareTo(rs['delStat']) > 0))) {
      await _userLastChatStore.update(
          await OfflineDBDatabase().getDatabase(), {'delStat': value},
          finder: finder);
    }
  }
}
