import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/firebase/ChatListener.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';

class SembastChat {
  static SembastChat _sembastChat;

  factory SembastChat() => _sembastChat ??= SembastChat._();

  SembastChat._();

  static const CHAT_STORE = 'chatStore';

  final _chatStore = intMapStoreFactory.store(CHAT_STORE);

  Future upsertInChatStore(ChatModel chat) async {
    chat.delStat = ChatModel.DELIVERED_TO_LOCAL;
    await _chatStore
        .record(chat.id)
        .put(await SembastDatabase().getDatabase(), chat.toJson(), merge: true);

    ChatBloc().addInChatController(chat);
    chat.compareId = chat.id;
    ChatListener().addToController(chat.toUserId, chat, chat.toUserId, false);
  }

  Future deleteFromChatStore(ChatModel chat) async {
    print('deleting id frm sembast ' + chat.id.toString());
    await _chatStore
        .record(chat.id)
        .delete(await SembastDatabase().getDatabase());
  }

  Future<List<ChatModel>> getChatDataFromStore(String toUserId) async {
    final finder = Finder(filter: Filter.equals('toUserId', toUserId));
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<List<ChatModel>> getMediaDataNotUploaded() async {
    final finder = Finder(filter: Filter.notEquals('chatType', ChatModel.CHAT));
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<ChatModel> getLastChatForUser(String toUserId) async {
    final finder = Finder(
        filter: Filter.equals('toUserId', toUserId),
        sortOrders: [SortOrder(Field.key, false)]);
    RecordSnapshot rs = await _chatStore
        .findFirst(await SembastDatabase().getDatabase(), finder: finder);
    if (null != rs) {
      return ChatModel.fromRecordSnapshot(rs);
    }
    return null;
  }
}
