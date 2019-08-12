import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/ChatListener.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';

class SembastChat {
  static SembastChat _sembastChat;

  factory SembastChat() => _sembastChat ??= SembastChat._();

  SembastChat._();

  static const CHAT_STORE = 'chatStore';

  final _chatStore = intMapStoreFactory.store(CHAT_STORE);

  /*Future bulkUpsertInChatStore(List<ChatModel> list) async {
    if (null != list && list.length > 0) {
      List<Future> futureList = List();
      list.forEach((chat) async {
        futureList.add(upsertInChatStore(chat, false, 'bulkUpsertInChatStore'));
      });
      Future.wait(futureList);
    }
  }*/

  Future upsertInChatStore(ChatModel chat, String source) async {
    final finder = Finder(filter: Filter.equals('id', chat.id));
    RecordSnapshot snap = await _chatStore
        .findFirst(await SembastDatabase().getDatabase(), finder: finder);
    if (snap != null && snap['localChatId'] != null) {
      chat.localChatId = snap['localChatId'];
    } else {
      chat.localChatId = DateTime.now().millisecondsSinceEpoch;
    }
    _chatStore
        .record(chat.localChatId)
        .put(await SembastDatabase().getDatabase(), chat.toJson(), merge: true)
        .then((map) {
      ChatModel updatedChat = ChatModel.fromJson(map);
      print('source ' +
          source +
          ' after upserting chat value is ' +
          updatedChat.toString());

      ChatBloc().addInChatController(updatedChat);
      String toUserId = (UserBloc().getCurrUser().id == updatedChat.fromUserId)
          ? updatedChat.toUserId
          : updatedChat.fromUserId;
      ChatListener().addToController(toUserId, updatedChat);
    });
  }

  Future<List<ChatModel>> getChatsLessThanId(int id, int limit) async {
    final finder = Finder(
        filter: Filter.lessThan('id', id),
        sortOrders: [SortOrder(Field.key, false)],
        limit: limit);
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    if (list != null && list.length > 0) {
      print('found all chat list from sembast less than id' +
          id.toString() +
          ' ' +
          list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<List<ChatModel>> getChatsForUserFromSembast(
      String toUserId, int limit) async {
    int start = DateTime.now().millisecondsSinceEpoch;
    List<ChatModel> result;
    final finder = Finder(
        filter: Filter.or([
          Filter.equals('fromUserId', toUserId),
          Filter.equals('toUserId', toUserId)
        ]),
        sortOrders: [SortOrder(Field.key,false)],
        limit: limit);
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    if (list != null && list.length > 0) {
      print('found all chat list from sembast ' + list.toString());
      result = list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    int diff = DateTime.now().millisecondsSinceEpoch - start;
    print(
        'time taken in fetching chats from sembast ' + diff.toString() + ' ms');
    return result;
  }

  /*Future<List<ChatModel>> getChatDataFromStore(String toUserId) async {
    final finder = Finder(filter: Filter.equals('toUserId', toUserId));
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }*/

  Future<List<ChatModel>> getMediaDataNotUploaded() async {
    final finder = Finder(
        filter: Filter.and([
      Filter.notEquals('chatType', ChatModel.CHAT),
      Filter.isNull('firebaseStorage'),
      Filter.notNull('localPath')
    ]));
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  /*Future<ChatModel> getLastChatForUser(String toUserId) async {
    final finder = Finder(
        filter: Filter.equals('toUserId', toUserId),
        sortOrders: [SortOrder(Field.key, false)]);
    RecordSnapshot rs = await _chatStore
        .findFirst(await SembastDatabase().getDatabase(), finder: finder);
    if (null != rs) {
      return ChatModel.fromRecordSnapshot(rs);
    }
    return null;
  }*/
}
