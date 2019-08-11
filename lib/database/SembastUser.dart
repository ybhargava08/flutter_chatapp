import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastDatabase.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:sembast/sembast.dart';

class SembastUser {
  static const USER_STORE = 'userStore';

  static const USER_CONTACT_STORE = 'userContactStore';

  static SembastUser _sembastChat;

  factory SembastUser() => _sembastChat ??= SembastUser._();

  SembastUser._();

  final _userContactStore = intMapStoreFactory.store(USER_CONTACT_STORE);
  
  Future upsertInUserContactStore(UserModel user,Map<String,dynamic> data) async {
    if(null!=user && user.ph!=UserBloc().getCurrUser().ph) {
        Map<String,dynamic> dataToStore = (data!=null)?data:user.toJson();
    Map<String,dynamic> snap = await _userContactStore.record(user.localId).put(await SembastDatabase().getDatabase(), dataToStore,merge: true);
   print('after upserting contactUserStore data is '+snap.toString());
    }
    
  }

  Future<List<UserModel>> getAllContacts() async {
       final finder = Finder(sortOrders: [SortOrder('lastActivityTime',false)]);
       List<RecordSnapshot> list= await _userContactStore.find(await SembastDatabase().getDatabase(),finder: finder);
       if(null!=list && list.length > 0) {
         print('found user contacts from local sembase length '+list.length.toString());
            return list.map((item) => UserModel.fromRecordSnapshot(item)).toList();
       } 
       return null;
  }

  Future deleteContactFromUserContactStore(UserModel user) async {
           final finder = Finder(filter: Filter.equals('id', user.id));
         int records =  await _userContactStore.delete(await SembastDatabase().getDatabase(),finder:finder);
         print('delted '+records.toString()+' from sembast user contact store');
  }
}
