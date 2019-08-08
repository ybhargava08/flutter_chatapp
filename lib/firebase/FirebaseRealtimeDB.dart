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

  Future incDecUnreadChatCount(String fromUserId, String toUserId,
      Map<String, dynamic> data, String type, int count) async {
    DatabaseReference countRef;

    if(type == 'inc') {
      countRef = _database.reference().child('ChatActivity').child(toUserId).child('UnreadChat').child(fromUserId);
         final TransactionResult result = await countRef.runTransaction((MutableData mutableData) async {
                    if(mutableData.value == null || mutableData.value['ct'] == null) {
                         data['ct'] = count;
                    } else{
                       data['ct'] = mutableData.value['ct']+count;
                    }
                    mutableData.value = data;
                    return mutableData;
         });
         if(result.error!=null) {
               print('error while commiting transaction '+result.error.toString());
         }
    }else{
      countRef = _database.reference().child('ChatActivity').child(toUserId).child('UnreadChat').child(fromUserId).child('ct');
      countRef.runTransaction((MutableData mutableData) async {
            if (mutableData.value != null) {
          mutableData.value = (mutableData.value - count) >= 0
              ? (mutableData.value - count)
              : 0;
        }
        return mutableData;
      });
    }
  }

  setUserLastActivityTime(ChatModel chat) async {
    getUserCollectionRef(chat.fromUserId, chat.toUserId)
        .set(<String, int>{"time": chat.fbId});
  }

  Future<void> deleteLastChatActivity() async {
    await _database.reference().child('UserActivity').remove();
  }

  DatabaseReference getChatCountReference(String path) {
        return _database.reference().child(path);
  }
}
