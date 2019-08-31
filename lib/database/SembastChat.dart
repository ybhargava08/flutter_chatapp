import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/database/SembastUserLastChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

class SembastChat {
  static SembastChat _sembastChat;

  factory SembastChat() => _sembastChat ??= SembastChat._();

  SembastChat._();

  static const CHAT_STORE = 'chatStore';

  static final Lock lock = Lock();

  final _chatStore = intMapStoreFactory.store(CHAT_STORE);

  Future upsertInChatStore(ChatModel chat, String source) async {
    await lock.synchronized(() async {
      Map<String, dynamic> data = new Map();
      bool shouldUpdate = false;
      bool shoulInsert = false;
      //print('inside lock ' + chat.id.toString());
      final finder = Finder(filter: Filter.equals('id', chat.id));
      RecordSnapshot snap = await _chatStore
          .findFirst(await SembastDatabase().getDatabase(), finder: finder);
      if (snap != null && snap.key != null) {
        chat.localChatId = snap.key;
        if (ChatModel.CHAT!=snap['chatType'] && snap['firebaseStorage'] == null 
        && null!=chat.firebaseStorage && ''!=chat.firebaseStorage) {
          data['firebaseStorage'] = chat.firebaseStorage;
          shouldUpdate = true;
        }
        if (snap['delStat'] == null && chat.delStat!=null ||
            chat.delStat.compareTo(snap['delStat']) > 0) {
          data['delStat'] = chat.delStat;
          shouldUpdate = true;
        }
      } else {
        shoulInsert = true;
        chat.localChatId = DateTime.now().millisecondsSinceEpoch;
      }

      if (shoulInsert) {
        Map<String, dynamic> map = await _chatStore
            .record(chat.localChatId)
            .put(await SembastDatabase().getDatabase(), chat.toJson(),
                merge: true);

        ChatModel updatedChat = ChatModel.fromJson(map);
        updatedChat.localChatId = chat.localChatId;
        ChatBloc().addInChatController(updatedChat);
        SembastUserLastChat().upsertUserLastChat(chat);
      }

      if (shouldUpdate) {
        await _chatStore.update(await SembastDatabase().getDatabase(), data,
            finder: finder);
        ChatBloc().addInChatController(chat);
        SembastUserLastChat().upsertUserLastChat(chat);
      }
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
      /*print('found all chat list from sembast less than id' +
          id.toString() +
          ' ' +
          list.toString());*/
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<List<ChatModel>> getChatsForUserFromSembast(
      String toUserId, int limit) async {
    //int start = DateTime.now().millisecondsSinceEpoch;
    List<ChatModel> result;
    final finder = Finder(
        filter: Filter.or([
          Filter.equals('fromUserId', toUserId),
          Filter.equals('toUserId', toUserId),
        ]),
        sortOrders: [SortOrder(Field.key, false)],
        limit: limit);

    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    if (list != null && list.length > 0) {
      print('found all chat list from sembast ' + list.toString());
      result = list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    //int diff = DateTime.now().millisecondsSinceEpoch - start;
    /*print(
        'time taken in fetching chats from sembast ' + diff.toString() + ' ms');*/
    return result;
  }

  Future<List<ChatModel>> getMediaDataNotUploaded() async {
    final finder = Finder(
        filter: Filter.and([
      Filter.notEquals('chatType', ChatModel.CHAT),
      Filter.isNull('firebaseStorage'),
      Filter.notNull('localPath')
    ]));
    List<RecordSnapshot> list = await _chatStore
        .find(await SembastDatabase().getDatabase(), finder: finder);
    //print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      //print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future updateDeliveryReceipt(String chatId,String val) async {
          int chatid = int.parse(chatId);
          final finder = Finder(filter: Filter.equals('id', chatid));
          RecordSnapshot rs = await _chatStore.findFirst(await SembastDatabase().getDatabase(),finder:finder);
          print('val is '+val+' chatid '+chatid.toString()+' got record snap updateDeliveryReceipt '+rs.toString());
          if(null!=rs && rs.key!=null && (null == rs['delStat'] || val.compareTo(rs['delStat']) > 0)) {
              await _chatStore.record(rs.key).put(await SembastDatabase().getDatabase(), {'delStat':val},merge: true);
          }
  }

  Future<int> deleteAllChats() async {
    return await _chatStore.delete(await SembastDatabase().getDatabase());
  }
}
