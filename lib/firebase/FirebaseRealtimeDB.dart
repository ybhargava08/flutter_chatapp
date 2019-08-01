import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeDB {
  static FirebaseRealtimeDB _firebaseRealtimeDB;

  factory FirebaseRealtimeDB() => _firebaseRealtimeDB??=FirebaseRealtimeDB._();
  FirebaseRealtimeDB._();

  static FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference getUserCollectionRef(String toUserId,String fromId) {
      return _database.reference().child('UserActivity').child(Utils().getChatCollectionId(fromId, toUserId));
  }

  Future<int> getUserLastActivityTime(String toUserId) async {
       DataSnapshot snap = await getUserCollectionRef(UserBloc().getCurrUser().id,toUserId).once();
       if(snap!=null && snap.value!=null) {
            return snap.value['time'];
       }
       return -1;
  }

  setUserLastActivityTime(ChatModel chat) async {
      getUserCollectionRef(chat.fromUserId,chat.toUserId).set(<String,int>{"time":chat.fbId});
  }

  Future<void> deleteLastChatActivity() async {
        await _database.reference().child('UserActivity').remove();
  }
}