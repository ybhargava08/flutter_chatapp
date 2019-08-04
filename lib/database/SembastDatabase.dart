import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/firebase/ChatListener.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class SembastDatabase {
  static const CHAT_STORE = 'chatStore';

  static const USER_STORE = 'userStore';

  static const USER_CONTACT_STORE = 'userContactStore';

  static SembastDatabase _sembastDatabase;

  factory SembastDatabase() => _sembastDatabase ??= SembastDatabase._();

  SembastDatabase._();

  static Completer<Database> _dbCompleter;

  final _chatStore = intMapStoreFactory.store(CHAT_STORE);

  final _userStore = intMapStoreFactory.store(USER_STORE);

  final _userContactStore = intMapStoreFactory.store(USER_CONTACT_STORE);

  Future<Database> _getDatabase() {
    if (_dbCompleter == null) {
      _dbCompleter = Completer();
      _openDatabase();
    }

    return _dbCompleter.future;
  }

  Future _openDatabase() async {
    final docDir = await getApplicationDocumentsDirectory();

    final dbPath = join(docDir.path, 'chatapp.db');

    final database = await databaseFactoryIo.openDatabase(dbPath);

    print('created / opened database at path '+dbPath.toString());

    _dbCompleter.complete(database);
  }

  Future upsertInUserStore(UserModel user) async {
           _userStore.record(DateTime.now().microsecondsSinceEpoch).put(await _getDatabase(), user.toJson(),merge: true);
  }

  Future<List<UserModel>> getUserContactList() async {
        List<RecordSnapshot> list = await _userStore.find(await _getDatabase());
        if(null!=list && list.length > 0) {
             return list.map((item)=> UserModel.fromRecordSnapshot(item)).toList();
        }
        return null;
  }

  Future upsertInStore(ChatModel chat) async {
    chat.delStat = ChatModel.DELIVERED_TO_LOCAL;
    await _chatStore.record(chat.id).put(await _getDatabase(), chat.toJson(),merge: true);
    

    ChatBloc().addInChatController(chat);
    chat.compareId = chat.id;
    ChatListener().addToController(chat.toUserId, chat,chat.toUserId,false);
  }

  Future deleteFromStore(ChatModel chat) async {
    print('deleting id frm sembast '+chat.id.toString());
    await _chatStore.record(chat.id).delete(await _getDatabase());
  }

  Future<List<ChatModel>> getDataFromStore(String toUserId) async {
    final finder = Finder(filter: Filter.equals('toUserId', toUserId));
    List<RecordSnapshot> list =
        await _chatStore.find(await _getDatabase(), finder: finder);
       print('record snapshot list '+list.toString()); 
    if (list != null && list.length > 0) {
       print('found list from sembast '+list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<List<ChatModel>> getAllData() async {
    final finder = Finder(filter: Filter.notEquals('chatType', ChatModel.CHAT));
    List<RecordSnapshot> list =
        await _chatStore.find(await _getDatabase(),finder:finder);
       print('record snapshot list '+list.toString()); 
    if (list != null && list.length > 0) {
       print('found list from sembast '+list.toString());
      return list.map((item) => ChatModel.fromRecordSnapshot(item)).toList();
    }
    return null;
  }

  Future<ChatModel> getLastChatForUser(String toUserId) async {
        
        final finder = Finder(
          filter: Filter.equals('toUserId', toUserId),
          sortOrders: [SortOrder(Field.key,false)]);
         RecordSnapshot rs =  await _chatStore.findFirst(await _getDatabase(),finder: finder);
         if(null!=rs) {
              return ChatModel.fromRecordSnapshot(rs);
         }
         return null;
  }

  Future upsertInUserContactStore(UserModel user,Map<String,dynamic> data) async {
    if(null!=user && user.ph!=UserBloc().getCurrUser().ph) {
        Map<String,dynamic> dataToStore = (data!=null)?data:user.toJson();
    Map<String,dynamic> snap = await _userContactStore.record(user.localId).put(await _getDatabase(), dataToStore,merge: true);
   print('after upserting contactUserStore data is '+snap.toString());
    }
    
  }

  Future<List<UserModel>> getAllContacts() async {
       final finder = Finder(sortOrders: [SortOrder('lastActivityTime',false)]);
       List<RecordSnapshot> list= await _userContactStore.find(await _getDatabase(),finder: finder);
       if(null!=list && list.length > 0) {
         print('found user contacts from local sembase length '+list.length.toString());
            return list.map((item) => UserModel.fromRecordSnapshot(item)).toList();
       } 
       return null;
  }

  Future deleteContactFromUserContactStore(UserModel user) async {
           final finder = Finder(filter: Filter.equals('id', user.id));
         int records =  await _userContactStore.delete(await _getDatabase(),finder:finder);
         print('delted '+records.toString()+' from sembast user contact store');
  }
}
