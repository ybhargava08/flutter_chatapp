import 'dart:async';

import 'package:chatapp/blocs/NotificationBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatReceiptListener {
  static ChatReceiptListener _chatReceiptListener;

  factory ChatReceiptListener() =>
      _chatReceiptListener ?? ChatReceiptListener._();

  ChatReceiptListener._();

  Map<int, StreamSubscription> _chatDelReceiptListenersGreater = Map();

  Map<int, StreamSubscription> _chatDelReceiptListenersLesser = Map();

  initChatReceiptListeners(int chatId, String delStat, String toUserId) {
    _listenForChatReceiptsGreater(chatId, delStat, toUserId);
    _listenForChatReceiptsLess(chatId, delStat, toUserId);
  }

  _listenForChatReceiptsGreater(int chatId, String delStat, String toUserId) {
    if (!_chatDelReceiptListenersGreater.containsKey(chatId) &&
        _chatDelReceiptListenersGreater[chatId] == null) {
      _chatDelReceiptListenersGreater[chatId] = Firebase()
          .getChatCollectionRef(
              Utils()
                  .getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
              Firebase.CHAT_COL_COMPLETE)
          .where('id', isEqualTo: chatId)
          .where('delStat', isGreaterThan: delStat)
          .where('delStat',
              isGreaterThanOrEqualTo: ChatModel.DELIVERED_TO_SERVER)
          .snapshots()
          .listen((data) {
        data.documentChanges.forEach((change) {
          _processData(data, change);
        });
      });
    }
  }

  _listenForChatReceiptsLess(int chatId, String delStat, String toUserId) {
    if (!_chatDelReceiptListenersLesser.containsKey(chatId) &&
        _chatDelReceiptListenersLesser[chatId] == null) {
      _chatDelReceiptListenersLesser[chatId] = Firebase()
          .getChatCollectionRef(
              Utils()
                  .getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
              Firebase.CHAT_COL_COMPLETE)
          .where('id', isEqualTo: chatId)
          .where('delStat', isLessThan: delStat)
          .where('delStat',
              isGreaterThanOrEqualTo: ChatModel.DELIVERED_TO_SERVER)
          .snapshots()
          .listen((data) {
        data.documentChanges.forEach((change) {
          _processData(data, change);
        });
      });
    }
  }

  closeChatReceiptListeners(int chatId) {
    if (_chatDelReceiptListenersGreater.containsKey(chatId) &&
        _chatDelReceiptListenersGreater[chatId] != null) {
      _chatDelReceiptListenersGreater[chatId].cancel().then((_) {
        _chatDelReceiptListenersGreater.remove(chatId);
      });
    }
    if (_chatDelReceiptListenersLesser.containsKey(chatId) &&
        _chatDelReceiptListenersLesser[chatId] != null) {
      _chatDelReceiptListenersLesser[chatId].cancel().then((_) {
        _chatDelReceiptListenersLesser.remove(chatId);
      });
    }
  }

  closeAllListeners() {  

      _chatDelReceiptListenersGreater.forEach((k,v) {
              closeChatReceiptListeners(k);
      });
      _chatDelReceiptListenersLesser.forEach((k,v) {
              closeChatReceiptListeners(k);
      });
  }

  _processData(QuerySnapshot data, DocumentChange change) {
    if (change.type == DocumentChangeType.modified) {
      data.documents.forEach((snapshot) {
        ChatModel c = ChatModel.fromDocumentSnapshot(snapshot);
        print('got data from chat delivery listener ' + c.toString());
        SembastChat().upsertInChatStore(c, false, 'chatDelivery');
        NotificationBloc().addToNotificationController(c.id, c.delStat);
      });
    }
  }
}
