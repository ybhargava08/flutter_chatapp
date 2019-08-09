import 'dart:async';

import 'package:chatapp/blocs/ChatBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/SembastChat.dart';
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

  Map<String, ChatModel> _lastChat = Map();

  Map<String, int> _lastIdMap = Map();

  StreamSubscription /*_deliverySubs,*/ _newChatSubs;

  static SharedPreferences _prefs;

  createListener(String id) {
    if (_listeners[id] == null || !_listeners.containsKey(id)) {
      _openController(id);
      _listeners[id] = List();
    }
  }

  openFirebaseListener(String id) {
    if (_listeners.containsKey(id) && _listeners[id].length == 0) {
      _listeners[id].add(Firebase()
          .getChatCollectionRef(
              Utils().getChatCollectionId(UserBloc().getCurrUser().id, id),
              Firebase.CHAT_COL_COMPLETE)
          .where('toUserId', isEqualTo: UserBloc().getCurrUser().id)
          .orderBy('fbId', descending: true)
          .limit(1)
          .snapshots()
          .listen((data) {
        bool hasPendingWrites = false;
        data.documentChanges.forEach((change) {
          hasPendingWrites = change.document.metadata.hasPendingWrites;
        });
        parseReceivedData(data, id, hasPendingWrites);
      }));

      _listeners[id].add(Firebase()
          .getChatCollectionRef(
              Utils().getChatCollectionId(UserBloc().getCurrUser().id, id),
              Firebase.CHAT_COL_COMPLETE)
          .where('fromUserId', isEqualTo: UserBloc().getCurrUser().id)
          .orderBy('id', descending: true)
          .limit(1)
          .snapshots()
          .listen((data) {
        bool hasPendingWrites = false;
        data.documentChanges.forEach((change) {
          hasPendingWrites = change.document.metadata.hasPendingWrites;
        });
        parseReceivedData(data, id, hasPendingWrites);
      }));
    }
  }

  getLatestChat(String toUserId) {
    if (_lastChat.containsKey(toUserId) && _lastChat[toUserId] != null) {
      return _lastChat[toUserId];
    }
    return null;
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

  addToController(
      String id, ChatModel chat, String toUserId, bool storeLastUpdated) {
    if (!isControllerClosed(id)) {
      print('adding chat for id ' + id + ' chat ' + chat.toString());
      _controller[id].sink.add(chat);
      if (storeLastUpdated) {
        _lastChat[toUserId] = chat;
        _lastIdMap[toUserId] = chat.compareId;
      }
      UserBloc().reorderList(toUserId);
    }
  }

  parseReceivedData(
      QuerySnapshot data, String toUserId, bool hasPendingWrites) {
    if (data != null && data.documents.length > 0) {
      ChatModel cm = ChatModel.fromDocumentSnapshot(data.documents[0]);
      cm.delStat =
          (hasPendingWrites) ? ChatModel.DELIVERED_TO_LOCAL : cm.delStat;
      bool isReceivedChat = cm.fromUserId != UserBloc().getCurrUser().id;
      if (isReceivedChat &&
          cm.delStat.compareTo(ChatModel.DELIVERED_TO_USER) < 0) {
        cm.fbId = DateTime.now().microsecondsSinceEpoch;
      }
      if (isReceivedChat) {
        cm.compareId = cm.fbId;
      } else {
        cm.compareId = cm.id;
      }
      if (isReceivedChat) {
        print('receiver chat ' + cm.toString());
      } else {
        print('sender chat ' +
            cm.toString() +
            ' is received chat ' +
            isReceivedChat.toString() +
            ' new delStat ' +
            cm.delStat);
      }

      String source = (isReceivedChat)?'receivedChatparseReceivedChat':'sentChatparseReceivedChat';

      ChatModel _chatModel = _lastChat[toUserId];
      int _lastId = _lastIdMap[toUserId];
      data.documentChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          print('chat listener got chat ' + cm.toString());

          if (_chatModel == null ||
              cm != _chatModel && cm.compareId > _lastId) {
            print('setting chat ' + cm.toString());
            addToController(toUserId, cm, toUserId, true);
            if(!hasPendingWrites) {
              
                SembastChat().upsertInChatStore(cm,false,source);
            }
            

            if (isReceivedChat) {
              _markChatAsDelivered(cm, toUserId);
            }
          }
        } else if (change.type == DocumentChangeType.modified) {
          if (cm.id == _chatModel.id && cm.delStat != _chatModel.delStat) {
            addToController(toUserId, cm, toUserId, false);
            if(!hasPendingWrites) {
                SembastChat().upsertInChatStore(cm,false,source);
            }
          }
        }
      });
    }
  }

  _markChatAsDelivered(ChatModel chat, String toUserId) {
    if (chat.fromUserId != UserBloc().getCurrUser().id &&
        chat.delStat == ChatModel.DELIVERED_TO_SERVER) {
      List<ChatModel> list = List();
      list.add(chat);

      Firebase().markChatsAsReadOrDelivered(
          toUserId, list, false, false, ChatModel.DELIVERED_TO_USER);
    }
  }

  listenForNewAddedChats(String toUserId,int maxChatId) {
    print('listenForNewAddedChats '+maxChatId.toString());
    _newChatSubs = Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
            Firebase.CHAT_COL_COMPLETE)
        .where('toUserId', isEqualTo: UserBloc().getCurrUser().id)
        .where('delStat', isGreaterThanOrEqualTo: ChatModel.DELIVERED_TO_SERVER)
        .where('id',isGreaterThan: maxChatId)
        .snapshots()
        .listen((data) {

      data.documentChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          if (data != null && data.documents.length > 0) {
            data.documents.forEach((snapshot) {
              ChatModel c = ChatModel.fromDocumentSnapshot(snapshot);
              print('got to user chat ' + c.toString());
              if (c.toUserId == UserBloc().getCurrUser().id &&
                  c.delStat != ChatModel.READ_BY_USER) {
                c.fbId = DateTime.now().microsecondsSinceEpoch;
              }
              ChatBloc().addInChatController(c);
              SembastChat().upsertInChatStore(c,false,'newAddedChat');
            });
          }
        }
      });
    });
  }

 Future<int> getInitChatList(String toUserId) async {
    
    if (null == _prefs) {
      _prefs = await SharedPreferences.getInstance();
    }

    int chatLimit = _prefs.getInt(toUserId);
    chatLimit = (chatLimit == null || chatLimit <= DBConstants.DATA_RETREIVE_COUNT)?DBConstants.DATA_RETREIVE_COUNT:chatLimit;
      List<ChatModel> completeList = List();
      completeList = await SembastChat().getChatsForUserFromSembast(toUserId,chatLimit);
      if (completeList == null || completeList.length == 0) {
        QuerySnapshot chatComplete = await Firebase()
            .getChatCollectionRef(
                Utils()
                    .getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
                Firebase.CHAT_COL_COMPLETE)
            .orderBy("fbId", descending: true)
            .limit(chatLimit)
            .getDocuments();

        if (chatComplete != null && chatComplete.documents.length > 0) {
          completeList = chatComplete.documents
              .map((item) => ChatModel.fromDocumentSnapshot(item))
              .toList();
        }
      SembastChat().bulkUpsertInChatStore(completeList);
       print('chat list loaded from firebase for '+toUserId);
      }else{
        print('chat list loaded from sembase for '+toUserId);
      }
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
    /*if (null != _deliverySubs) {
      _deliverySubs.cancel();
    }*/
    if (_newChatSubs != null) {
      _newChatSubs.cancel();
    }
  }
}
