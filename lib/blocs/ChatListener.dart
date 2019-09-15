import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/OfflineDBChat.dart';
import 'package:chatapp/database/OfflineDBUserLastChat.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatListener {
  static ChatListener _chatListener;

  factory ChatListener() => _chatListener ??= ChatListener._();

  ChatListener._();

  Map<String, List<StreamSubscription>> _listeners = Map();
  Map<String, StreamController<ChatModel>> _controller = Map();

  StreamSubscription _newChatSubs;

  static SharedPreferences _prefs;

  createListener(String id) {
    if (_listeners[id] == null || !_listeners.containsKey(id)) {
      _openController(id);
      _listeners[id] = List();
    }
  }

  openFirebaseListener(String id) async {
    ChatModel lastChat = await OfflineDBUserLastChat().getLastUserChat(id);
    int lastId = 0;
    if (null != lastChat && null != lastChat.id) {
      if (lastChat.isD || lastChat.delStat == ChatModel.READ_BY_USER) {
        lastId = lastChat.id;
      } else {
        lastId = (lastChat.id - 1 > 0) ? lastChat.id - 1 : 0;
      }
      String toUserId = (UserBloc().getCurrUser().id == lastChat.fromUserId)
          ? lastChat.toUserId
          : lastChat.fromUserId;
      addToController(toUserId, lastChat);
    }
    if (_listeners.containsKey(id) && _listeners[id].length == 0) {
      _listeners[id].add(Firebase()
          .getChatCollectionRef(
              Utils().getChatCollectionId(UserBloc().getCurrUser().id, id),
              Firebase.CHAT_COL_COMPLETE)
          .where('toUserId', isEqualTo: UserBloc().getCurrUser().id)
          .where('id', isGreaterThan: lastId)
          .orderBy('id', descending: true)
          .limit(1)
          .snapshots()
          .listen((data) {
        data.documentChanges.forEach((change) {
          ChatModel cm = ChatModel.fromDocumentSnapshot(change.document);
          if (change.type == DocumentChangeType.added) {
            if (null != cm.delStat || '' == cm.delStat) {
              cm.delStat = ChatModel.DELIVERED_TO_SERVER;
            }
            OfflineDBUserLastChat().upsertUserLastChat(cm);
          } else if (change.type == DocumentChangeType.modified) {
            OfflineDBUserLastChat().upsertUserLastChat(cm);
          }
        });
      }));
    }
  }

  _openController(String id) {
    if (isControllerClosed(id)) {
      _controller[id] = StreamController.broadcast();
    }
  }

  isControllerClosed(String id) {
    if (_controller.containsKey(id) && _controller[id] != null) {
      return _controller[id].isClosed;
    }
    return true;
  }

  StreamController<ChatModel> getController(String id) {
    if (!isControllerClosed(id)) {
      return _controller[id];
    }
    return null;
  }

  addToController(String toUserId, ChatModel chat) {
    if (!isControllerClosed(toUserId)) {
      _controller[toUserId].sink.add(chat);
      UserBloc().reorderList(toUserId);
    }
  }

  listenForNewAddedChats(String toUserId, int maxTS) {
    _newChatSubs = Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
            Firebase.CHAT_COL_COMPLETE)
        .where('toUserId', isEqualTo: UserBloc().getCurrUser().id)
        .where('ts', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(maxTS))
        .orderBy('ts', descending: false)
        .snapshots()
        .listen((data) {
      data.documentChanges.forEach((change) {
        ChatModel cm = ChatModel.fromDocumentSnapshot(change.document);
        if (change.type == DocumentChangeType.added) {
          
          if (null != cm.delStat || '' == cm.delStat) {
            cm.delStat = ChatModel.DELIVERED_TO_SERVER;
          }
        } else if (change.type == DocumentChangeType.modified) {
          OfflineDBChat()
              .upsertInChatStore(cm, 'newAddedChat / updated / deleted chat');
        }
      });
    });
  }

  Future<int> getInitChatList(String toUserId) async {
    if (null == _prefs) {
      _prefs = await SharedPreferences.getInstance();
    }

    int chatLimit = _prefs.getInt(toUserId);
    chatLimit =
        (chatLimit == null || chatLimit <= DBConstants.DATA_RETREIVE_COUNT)
            ? DBConstants.DATA_RETREIVE_COUNT
            : chatLimit;
    List<ChatModel> completeList = List();
    completeList =
        await OfflineDBChat().getChatsForUserFromOfflineDB(toUserId, chatLimit);
    if (null != completeList && completeList.length > 0) {
      return ChatBloc().setInitList(completeList, toUserId);
    }
    return 0;
  }

  setDbCountPrefAtClose(String toUserId) {
    if (null != _prefs) {
      _prefs.setInt(
          toUserId,
          ChatBloc().getChatListLength() <= DBConstants.DATA_RETREIVE_COUNT
              ? DBConstants.DATA_RETREIVE_COUNT
              : ChatBloc().getChatListLength());
    }
  }

  _closeController(String id) {
    if (!isControllerClosed(id)) {
      _controller[id].close();
    }
  }

  closeAllListeners() {
    _listeners.forEach((key, val) {
      val.forEach((subs) {
        if (subs != null) {
          subs.cancel();
        }
      });
      _closeController(key);
    });
  }

  closeChatDeliveryAndNewAddedListener() {
    if (_newChatSubs != null) {
      _newChatSubs.cancel();
    }
  }
}
