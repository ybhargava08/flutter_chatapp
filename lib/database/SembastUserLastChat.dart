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
    final finder = Finder(filter: Filter.equals('toUserId', toUserId));
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
      final finder = Finder(filter: Filter.or([
        Filter.equals('toUserId', toUserId),
        Filter.equals('fromUserId', toUserId)
      ]));
      int key;
      RecordSnapshot rs = await _userLastChatStore
          .findFirst(await SembastDatabase().getDatabase(), finder: finder);
      if (rs != null) {
        key = rs.key;
        print('found key in upsertuserlastchat current last chat '+rs['chat'].toString()+" current last time "+rs['chatDate'].toString()
        +' new chat '+chat.chat+' new date '+chat.chatDate.toString());
        if(chat.chatDate < rs['chatDate']) {
             return;
        }
      } else {
        key = DateTime.now().microsecondsSinceEpoch;
        
      }
      _userLastChatStore
          .record(key)
          .put(await SembastDatabase().getDatabase(), chat.toJson()).then((map) {
                  ChatListener().addToController(toUserId, chat);
                  ChatModel c = ChatModel.fromJson(map);
            print('upsert last user chat '+c.toString());
          });
    });
  }

  Future deleteAllLastChats() async {
       return await _userLastChatStore.delete(await SembastDatabase().getDatabase());
  }
}
