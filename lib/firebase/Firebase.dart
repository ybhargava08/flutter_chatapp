import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/database/SembastUser.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/model/UserModel.dart';
import 'package:chatapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Firebase {
  static Firestore _firestore = Firestore.instance;


  static Firebase _firebase;

  static const String CHAT_COL_COMPLETE = 'complete';

  factory Firebase() => _firebase ??= Firebase._internal();
  Firebase._internal() {
    _firestore.settings(persistenceEnabled: true);
  }

  addUpdateUser(UserModel user) async {
    _firestore.collection('users').document(user.id).setData(user.toJson(),merge: true);
  }

  CollectionReference getAllUserCollection() {
    return _firestore.collection('users');
  }

  DocumentReference getChatDocRef(String docId) {
       return _firestore
        .collection('chats')
        .document(docId); 
  }

  CollectionReference getChatCollectionRef(String docId, String collection) {
    return _firestore
        .collection('chats')
        .document(docId)
        .collection(collection);
  }

  Future<void> addUpdateChat(
      ChatModel chat, String collection, bool shouldUpdateCount) async {
        ChatModel localChat;
    print('chat data before persist ' + chat.toJson().toString());
    
    try {
      if (chat.chatType == ChatModel.CHAT) {
        localChat = ChatModel(chat.id, chat.fromUserId, chat.toUserId, chat.chat, chat.chatDate, chat.chatType, 
        chat.localPath, chat.thumbnailPath, chat.fileName, chat.firebaseStorage, ChatModel.DELIVERED_TO_LOCAL);
        ChatBloc().addInChatController(localChat);
      }

      SembastChat().upsertInChatStore(localChat,'addUpdateChatBefore');

      if (shouldUpdateCount) {
        DocumentReference chatRef = getChatCollectionRef(
                Utils().getChatCollectionId(chat.fromUserId, chat.toUserId),
                collection)
            .document(chat.id.toString());
            chat.delStat = ChatModel.DELIVERED_TO_SERVER; 
            chatRef.setData(chat.toJson(),merge:true)
        .whenComplete(() async {
          
          FirebaseRealtimeDB().incDecUnreadChatCount(chat.fromUserId, chat.toUserId,
          prepareDataForCountUpdate(chat) , 'inc', 1);
          int time = await FirebaseRealtimeDB().setUserLastActivityTime(chat);
          String userSearchId = (chat.fromUserId == UserBloc().getCurrUser().id)?chat.toUserId:chat.fromUserId;
          SembastUser().upsertInUserContactStore(UserBloc().findUser(userSearchId), {'lastActivityTime':time});
          if(null!=localChat) {
              localChat.delStat = ChatModel.DELIVERED_TO_SERVER;
          NotificationBloc().addToNotificationController(localChat.id, ChatModel.DELIVERED_TO_SERVER);
          SembastChat().upsertInChatStore(localChat,'addUpdateChatBefore');
          }else{
            NotificationBloc().addToNotificationController(chat.id, ChatModel.DELIVERED_TO_SERVER);
          }
          
        });
      } else {
        getChatCollectionRef(
                Utils().getChatCollectionId(chat.fromUserId, chat.toUserId),
                collection)
            .document(chat.id.toString())
            .setData(chat.toJson(),merge: true).then((val) {
              localChat.delStat = ChatModel.DELIVERED_TO_SERVER;
                     NotificationBloc().addToNotificationController(localChat.id, ChatModel.DELIVERED_TO_SERVER);
            });
      }
    } catch (e) {
      print('exception while add / update chat in FB ' + e.toString());
    }
  }

  markChatsAsReadOrDelivered(String otherUserId, List<ChatModel> chats,
      bool shouldUpdateCount, String type) async {
    if(chats.length > 0)  {
        WriteBatch batch = _firestore.batch();
    chats.forEach((chat) {
      DocumentReference docRef = getChatCollectionRef(
              Utils().getChatCollectionId(
                  UserBloc().getCurrUser().id, otherUserId),
              CHAT_COL_COMPLETE)
          .document(chat.id.toString());
      Map<String, dynamic> data = Map();
      if (type == ChatModel.READ_BY_USER) {
        data = {'delStat': ChatModel.READ_BY_USER};
      } else {
        data = {'delStat': ChatModel.DELIVERED_TO_USER};
      }
      batch.setData(docRef, data, merge: true);
    });
    batch.commit().then((val) {
           if(type == ChatModel.READ_BY_USER) {
                  ChatModel cm = chats[0];
            FirebaseRealtimeDB().incDecUnreadChatCount(cm.fromUserId, cm.toUserId, null, 'dec', chats.length);
           }
    });
    }   
  }

  Map<String,dynamic> prepareDataForCountUpdate(ChatModel chat) {
         UserModel fromUser = (chat.fromUserId == UserBloc().getCurrUser().id)?UserBloc().getCurrUser():
         UserBloc().findUser(chat.fromUserId);
         UserModel toUser = (chat.toUserId == UserBloc().getCurrUser().id)?UserBloc().getCurrUser()
         :UserBloc().findUser(chat.toUserId);
         String name = (fromUser.name == null)?fromUser.ph:fromUser.name;
         String msg = (chat.chatType == ChatModel.CHAT)?chat.chat:(chat.chatType == ChatModel.VIDEO)?'Sent a Video':'Sent an Image';
         Map<String,dynamic> data = {'nm':name,'msg':msg,'fcm':toUser.fcmToken,'id':chat.id};

         return data;
  }
}
