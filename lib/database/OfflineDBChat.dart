import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/database/OfflineDBDatabase.dart';
import 'package:chatapp/database/OfflineDBUserLastChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

class OfflineDBChat {
  static OfflineDBChat _offlineDBChat;

  factory OfflineDBChat() => _offlineDBChat ??= OfflineDBChat._();

  OfflineDBChat._();

  static const CHAT_STORE = 'chatStore';

  static final Lock lock = Lock();

  final _chatStore = intMapStoreFactory.store(CHAT_STORE);

  Future upsertInChatStore(ChatModel chat, String source) async {
    await lock.synchronized(() async {
      Map<String, dynamic> data = new Map();
      final finder = Finder(filter: Filter.equals('id', chat.id));
      RecordSnapshot snap = await _chatStore
          .findFirst(await OfflineDBDatabase().getDatabase(), finder: finder);

      int recordKey = _getRecordKey(snap);

      bool merge = !chat.isD;
      bool shoulInsert = chat.isD || (recordKey == null);

     if(recordKey!=null) {
        data = _checkIsUpdate(snap, chat, data);
     }
    
      bool shouldUpdate = !shoulInsert && data.isNotEmpty;

      recordKey = (recordKey == null)
          ? DateTime.now().millisecondsSinceEpoch
          : recordKey;

      data = shoulInsert
          ? chat.isD
              ? chat.toDeleteJson(chat.ts, chat.chatDate, false)
              : chat.toJson()
          : data;

      if (shoulInsert) {
        Map<String, dynamic> map = await _chatStore
            .record(recordKey)
            .put(await OfflineDBDatabase().getDatabase(), data, merge: merge);

        ChatModel updatedChat = ChatModel.fromJson(map);
        updatedChat.localChatId = recordKey;
        ChatBloc().addInChatController(updatedChat);
        OfflineDBUserLastChat().upsertUserLastChat(chat);
      } else if (shouldUpdate) {
        int noUpdates = await _chatStore.update(
            await OfflineDBDatabase().getDatabase(), data,
            finder: finder);
        if (noUpdates > 0) {
          ChatBloc().addInChatController(chat);
          OfflineDBUserLastChat().upsertUserLastChat(chat);
        }
      }
    });
  }

  Future<List<ChatModel>> getChatsLessThanId(int id, int limit) async {
    final finder = Finder(
        filter: Filter.lessThan('id', id),
        sortOrders: [SortOrder(Field.key, false)],
        limit: limit);
    List<RecordSnapshot> list = await _chatStore
        .find(await OfflineDBDatabase().getDatabase(), finder: finder);
    if (list != null && list.length > 0) {
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<List<ChatModel>> getChatsForUserFromOfflineDB(
      String toUserId, int limit) async {
    List<ChatModel> result;
    final finder = Finder(
        filter: Filter.or([
          Filter.equals('fromUserId', toUserId),
          Filter.equals('toUserId', toUserId),
        ]),
        sortOrders: [SortOrder(Field.key, false)],
        limit: limit);

    List<RecordSnapshot> list = await _chatStore
        .find(await OfflineDBDatabase().getDatabase(), finder: finder);
    if (list != null && list.length > 0) {
      //  print('found all chat list from sembast ' + list.toString());
      result = list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
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
        .find(await OfflineDBDatabase().getDatabase(), finder: finder);
    //print('record snapshot list ' + list.toString());
    if (list != null && list.length > 0) {
      //print('found list from sembast ' + list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<bool> updateDeliveryReceipt(String chatId, String val) async {
    int chatid = int.parse(chatId);
    final finder = Finder(filter: Filter.equals('id', chatid));
    RecordSnapshot rs = await _chatStore
        .findFirst(await OfflineDBDatabase().getDatabase(), finder: finder);
    if (null != rs &&
        rs.key != null &&
        (null == rs['delStat'] || val.compareTo(rs['delStat']) > 0)) {
      await _chatStore.record(rs.key).put(
          await OfflineDBDatabase().getDatabase(), {'delStat': val},
          merge: true);
      OfflineDBUserLastChat().updateLastChatDelivery(chatid, val);
      return true;
    }
    OfflineDBUserLastChat().updateLastChatDelivery(chatid, val);
    return false;
  }

  int _getRecordKey(RecordSnapshot snap) {
    if (snap != null && snap.key != null) {
      return snap.key;
    }
    return null;
  }

  Map<String, dynamic> _checkIsUpdate(
      RecordSnapshot snap, ChatModel chat, Map<String, dynamic> data) {
    if (ChatModel.CHAT != snap['chatType'] &&
        snap['firebaseStorage'] == null &&
        null != chat.firebaseStorage &&
        '' != chat.firebaseStorage) {
      data['firebaseStorage'] = chat.firebaseStorage;
    }
    if( chat.thumbnailPath!=null && ( snap['thumbnailPath'] == null || chat.thumbnailPath.compareTo(snap['thumbnailPath'])!=0)) {
        data['thumbnailPath'] = chat.thumbnailPath;
    }
    if (snap['delStat'] == null && chat.delStat != null ||
       chat.delStat!=null && chat.delStat.compareTo(snap['delStat']) > 0) {
      data['delStat'] = chat.delStat;
    }
    if (null != chat.ts && (snap['ts'] == null && chat.ts > 0 ||
        snap['ts'] != null && chat.ts > snap['ts'])) {
      data['ts'] = chat.ts;
    }
    if (null != chat.chatDate && (snap['chatDate'] == null &&
            
            chat.chatDate > 0 ||
        snap['chatDate'] != null && chat.chatDate > snap['chatDate'])) {
      data['chatDate'] = chat.chatDate;
    }
    return data;
  }

  Future<int> deleteAllChats() async {
    return await _chatStore.delete(await OfflineDBDatabase().getDatabase());
  }
}
