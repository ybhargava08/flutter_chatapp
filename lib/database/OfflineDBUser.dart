import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/OfflineDBDatabase.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:sembast/sembast.dart';

class OfflineDBUser {
  static const USER_STORE = 'userStore';

  static const USER_CONTACT_STORE = 'userContactStore';

  static OfflineDBUser _sembastChat;

  factory OfflineDBUser() => _sembastChat ??= OfflineDBUser._();

  OfflineDBUser._();

  final _userContactStore = intMapStoreFactory.store(USER_CONTACT_STORE);
  
  Future upsertInUserContactStore(UserModel user,Map<String,dynamic> data) async {
    if(null!=user && user.ph!=UserBloc().getCurrUser().ph) {
        Map<String,dynamic> dataToStore = (data!=null)?data:user.toJson();
       _userContactStore.record(user.localId).put(await OfflineDBDatabase().getDatabase(), dataToStore,merge: true);
    }
    
  }

  Future<List<UserModel>> getAllContacts() async {
       final finder = Finder(sortOrders: [SortOrder('lastActivityTime',false)]);
       List<RecordSnapshot> list= await _userContactStore.find(await OfflineDBDatabase().getDatabase(),finder: finder);
       if(null!=list && list.length > 0) {
            return list.map((item) => UserModel.fromRecordSnapshot(item)).toList();
       } 
       return null;
  }

  Future deleteContactFromUserContactStore(UserModel user) async {
           final finder = Finder(filter: Filter.equals('id', user.id));
         _userContactStore.delete(await OfflineDBDatabase().getDatabase(),finder:finder);
  }
}
