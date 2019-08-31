import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/WebSocModel.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

class ChatReceiptDB {
  static ChatReceiptDB _chatReceiptDB;

  factory ChatReceiptDB() => _chatReceiptDB ??= ChatReceiptDB._();

  ChatReceiptDB._();

  static const CHAT_RECEIPT_STORE = 'chatRecStore';

  static final Lock lock = Lock();

  final _chatReceiptStore = intMapStoreFactory.store(CHAT_RECEIPT_STORE);

  Future<WebSocModel> upsertReceiptInDB(ChatModel chat) async {
    final finder = Finder(filter: Filter.equals(Field.key, chat.id));
    RecordSnapshot snap = await _chatReceiptStore
        .findFirst(await SembastDatabase().getDatabase(), finder: finder);

    if (snap == null ||
        snap != null && snap.key != null && snap['delStat'] < chat.delStat) {
      Map<String, dynamic> savedData = await _chatReceiptStore
          .record(chat.id)
          .put(await SembastDatabase().getDatabase(), {
        'fromUserId': chat.fromUserId,
        'toUserId': chat.toUserId,
        'value': chat.delStat
      });
      return WebSocModel(WebSocModel.RECEIPT_DEL, savedData['fromUserId'],
          savedData['toUserId'], chat.id.toString(), savedData['value']);
    }
    return null;
  }

  Future<List<WebSocModel>> getAllReceipts() async {
    List<RecordSnapshot> list =
        await _chatReceiptStore.find(await SembastDatabase().getDatabase());
    if (null != list && list.length > 0) {
      return list
          .map((rs) => WebSocModel(WebSocModel.RECEIPT_DEL, rs['fromUserId'],
              rs['toUserId'], rs.key.toString(), rs['value']))
          .toList();
    }
    return null;
  }

  deleteReceiptInDB(String id) async {
    int key = int.parse(id);

    _chatReceiptStore.delete(await SembastDatabase().getDatabase(),
        finder: Finder(filter: Filter.equals(Field.key, key)));
  }
}
