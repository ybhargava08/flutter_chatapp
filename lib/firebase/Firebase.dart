import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/database/SembastUser.dart';
import 'package:chatapp/firebase/FirebaseRealtimeDB.dart';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:chatapp/model/ChatDeleteModel.dart';
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
    _firestore
        .collection('users')
        .document(user.id)
        .setData(user.toJson(), merge: true);
  }

  CollectionReference getAllUserCollection() {
    return _firestore.collection('users');
  }

  DocumentReference getChatDocRef(String docId) {
    return _firestore.collection('chats').document(docId);
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

    try {
      if (chat.chatType == ChatModel.CHAT) {
        localChat = ChatModel(
            chat.id,
            chat.fromUserId,
            chat.toUserId,
            chat.chat,
            chat.chatDate,
            chat.chatType,
            chat.localPath,
            chat.thumbnailPath,
            chat.fileName,
            chat.firebaseStorage,
            ChatModel.DELIVERED_TO_LOCAL,
            false,chat.ts);
        ChatBloc().addInChatController(localChat);
        SembastChat().upsertInChatStore(localChat, 'addUpdateChatBefore');
      }

      if (shouldUpdateCount) {
        DocumentReference chatRef = getChatCollectionRef(
                Utils().getChatCollectionId(chat.fromUserId, chat.toUserId),
                collection)
            .document(chat.id.toString());
        chat.delStat = ChatModel.DELIVERED_TO_SERVER;
        chatRef.setData(chat.toFirestoreJson(), merge: true).then((_) async {
          
          FirebaseRealtimeDB().setLastChatRealtimeDB(
              chat.fromUserId, chat.toUserId, prepareDataForCountUpdate(chat));
          int time = await FirebaseRealtimeDB().setUserLastActivityTime(chat);
          String userSearchId = (chat.fromUserId == UserBloc().getCurrUser().id)
              ? chat.toUserId
              : chat.fromUserId;
          SembastUser().upsertInUserContactStore(
              UserBloc().findUser(userSearchId), {'lastActivityTime': time});
          if (null != localChat) {
            localChat.delStat = ChatModel.DELIVERED_TO_SERVER;
            NotificationBloc().addToNotificationController(
                localChat.id, ChatModel.DELIVERED_TO_SERVER);
            SembastChat()
                .upsertInChatStore(localChat, 'addUpdateChatAfterFBPersist');
          } else {
            SembastChat()
                .upsertInChatStore(chat, 'addUpdateChatAfterFBPersist');
            NotificationBloc().addToNotificationController(
                chat.id, ChatModel.DELIVERED_TO_SERVER);
          }
        });
      } else {
        getChatCollectionRef(
                Utils().getChatCollectionId(chat.fromUserId, chat.toUserId),
                collection)
            .document(chat.id.toString())
            .setData(chat.toJson(), merge: true)
            .then((val) {
          localChat.delStat = ChatModel.DELIVERED_TO_SERVER;
          NotificationBloc().addToNotificationController(
              localChat.id, ChatModel.DELIVERED_TO_SERVER);
        });
      }
    } catch (e) {
      //print('exception while add / update chat in FB ' + e.toString());
    }
  }

  markChatAsDeleted(List<ChatDeleteModel> list) async {
    if (list != null && list.length > 0) {
      WriteBatch batch = _firestore.batch();
      list.forEach((chatDelModel) {
        SembastChat().upsertInChatStore(chatDelModel.chat, 'markChatAsDeleted');
        DocumentReference _reference = getChatCollectionRef(
                Utils().getChatCollectionId(chatDelModel.chat.fromUserId, chatDelModel.chat.toUserId),
                Firebase.CHAT_COL_COMPLETE)
            .document(chatDelModel.chat.id.toString());
        batch.setData(_reference, chatDelModel.chat.toDeleteJson(chatDelModel.chat.ts,chatDelModel.chat.chatDate,true));
      });

      await batch.commit();

      list.forEach((chatDelModel) {
          FirebaseStorageUtil().removeChatFromFBandLocalStorage(chatDelModel);
        
      });
    }
  }

  Map<String, dynamic> prepareDataForCountUpdate(ChatModel chat) {
    UserModel fromUser = (chat.fromUserId == UserBloc().getCurrUser().id)
        ? UserBloc().getCurrUser()
        : UserBloc().findUser(chat.fromUserId);
    UserModel toUser = (chat.toUserId == UserBloc().getCurrUser().id)
        ? UserBloc().getCurrUser()
        : UserBloc().findUser(chat.toUserId);
    String name = (fromUser.name == null) ? fromUser.ph : fromUser.name;
    String msg = (chat.chatType == ChatModel.CHAT)
        ? chat.chat
        : (chat.chatType == ChatModel.VIDEO) ? 'Sent a Video' : 'Sent an Image';
    Map<String, dynamic> data = {
      'nm': name,
      'msg': msg,
      'fcm': toUser.fcmToken,
      'id': chat.id
    };

    return data;
  }
}
