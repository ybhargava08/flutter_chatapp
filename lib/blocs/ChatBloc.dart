import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../utils.dart';

class ChatBloc {
  static ChatBloc _chatBloc;

  factory ChatBloc() => _chatBloc ??= ChatBloc._();

  ChatBloc._();

  Map<String, double> _scrollPos = Map();

  List<ChatModel> _oneToOneList = List();

  StreamController<List<ChatModel>> _chatController;

  Map<String, bool> _openChatScreen = Map();

  static int _minChatId = 0;

  int getChatListLength() {
    return _oneToOneList.length;
  }

  addScrollPos(String id, double pos) {
    _scrollPos[id] = pos;
  }

  getScrollPos(String id) {
    if (_scrollPos.containsKey(id)) {
      return _scrollPos[id];
    }
    return 10000.0;
  }

  addOpenScreenId(String id) {
    _openChatScreen[id] = true;
  }

  closeOpenScreenId(String id) {
    if (_openChatScreen.containsKey(id)) {
      _openChatScreen.remove(id);
    }
  }

  List<ChatModel> getList() {
    return _oneToOneList;
  }

  bool getOpenScreenStatus(String id) {
    return _openChatScreen.containsKey(id) && _openChatScreen[id];
  }

  initChatController() {
    closeChatController();
    _chatController = StreamController();
  }

  checkIfChatControllerClosed() {
    return null == _chatController || _chatController.isClosed;
  }

  Stream<List<ChatModel>> getChatStream() {
    return _chatController.stream;
  }

  setInitList(List<ChatModel> list) {
    list.forEach((chat) {
      if (chat.fromUserId == UserBloc().getCurrUser().id) {
        chat.compareId = chat.id;
      } else {
        chat.compareId = chat.fbId;
      }
    });
    list.sort((a, b) {
      return a.compareId.compareTo(b.compareId);
    });

    _oneToOneList = list;

    _chatController.sink.add(_oneToOneList);
    _minChatId = _oneToOneList[0].id;
  }

  addInChatController(ChatModel cm) {
    if (!checkIfChatControllerClosed()) {
      List<ChatModel> foundItem =
          _oneToOneList.where((item) => item.id == cm.id).toList();

      if (foundItem == null || foundItem.isEmpty) {
        print('cm not found in list ' + cm.toString());
        if (cm.fromUserId == UserBloc().getCurrUser().id) {
          cm.compareId = cm.id;
        } else {
          cm.compareId = cm.fbId;
        }
        _oneToOneList.add(cm);

        _chatController.sink.add(_oneToOneList);

        _minChatId = _oneToOneList[0].id;
      } else {
        print('cm found in list ' + cm.toString());
      }
    }
  }

  setMoreData(List<ChatModel> moreData) { 
    _oneToOneList.insertAll(0, moreData);
    _chatController.sink.add(_oneToOneList);
    _minChatId = _oneToOneList[0].id;
  }

  closeChatController() {
    if (!checkIfChatControllerClosed()) {
      _chatController.close();
    }
  }

  getMoreData(String toUserId) async {
    QuerySnapshot moreData = await Firebase()
        .getChatCollectionRef(
            Utils().getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
            Firebase.CHAT_COL_COMPLETE)
        .where("fbId", isLessThan: _minChatId)
        .orderBy("fbId", descending: true)
        .limit(DBConstants.DATA_RETREIVE_COUNT)
        .getDocuments();

    if (moreData != null && moreData.documents.length > 0) {
      List<ChatModel> list = moreData.documents
          .map((item) => ChatModel.fromDocumentSnapshot(item))
          .toList();
      list.forEach((chat) {
        if (chat.fromUserId == UserBloc().getCurrUser().id) {
          chat.compareId = chat.id;
        } else {
          chat.compareId = chat.fbId;
        }
      });
      list.sort((a, b) {
        if(a.id > b.id){
             return b.compareId.compareTo(a.compareId);
        }else{
              return a.compareId.compareTo(b.compareId);
        }
        
      });
      setMoreData(list);
    }
  }
}
