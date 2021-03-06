import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeDB {
  static FirebaseRealtimeDB _firebaseRealtimeDB;

  static FirebaseDatabase _database = FirebaseDatabase.instance;

  factory FirebaseRealtimeDB() =>
      _firebaseRealtimeDB ??= FirebaseRealtimeDB._internal();
  FirebaseRealtimeDB._internal(){
        _database.setPersistenceEnabled(true);
  }

  DatabaseReference getUserCollectionRef(String toUserId, String fromId) {
    return _database
        .reference()
        .child('UserActivity')
        .child(Utils().getChatCollectionId(fromId, toUserId));
  }

  Future<int> getUserLastActivityTime(String toUserId) async {
    DataSnapshot snap =
        await getUserCollectionRef(UserBloc().getCurrUser().id, toUserId)
            .once();
    if (snap != null && snap.value != null) {
      return snap.value['time'];
    }
    return -1;
  }

  Future setLastChatRealtimeDB(String fromUserId, String toUserId,
      Map<String, dynamic> data) async {
    DatabaseReference countRef=_database.reference().child('ChatActivity').child(toUserId).child('UnreadChat').child(fromUserId);
    countRef.set(data);
  }

  Future<int> setUserLastActivityTime(ChatModel chat) async {
    int time = DateTime.now().microsecondsSinceEpoch;
    await getUserCollectionRef(chat.fromUserId, chat.toUserId)
        .set(<String, int>{"time": time});
     return time;   
  }

  Future<void> deleteLastChatActivity() async {
    await _database.reference().child('UserActivity').remove();
  }

  DatabaseReference getDBPathReference(String path) {
        return _database.reference().child(path);
  }

  Future<int> writeLastBackUpTime() async {
       int time = DateTime.now().millisecondsSinceEpoch;
       await getDBPathReference('DbBackup/'+UserBloc().getCurrUser().id).set(<String,int>{'tm':time});
       return time;
  }

  Future<int> getLastBackUpTime() async {
        DataSnapshot snap = await getDBPathReference('DbBackup/'+UserBloc().getCurrUser().id).once();

        if(snap!=null && snap.value!=null) {
             return snap.value['tm'];
        }
        return 0;
  }
}
