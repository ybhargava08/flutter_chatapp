import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/firebase/Firebase.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils.dart';

class ChatBloc {
  static ChatBloc _chatBloc;

  factory ChatBloc() => _chatBloc ??= ChatBloc._();

  ChatBloc._();

  List<ChatModel> _oneToOneList = List();

  StreamController<List<ChatModel>> _chatController;

  Map<String, bool> _openChatScreen = Map();

  static int _minChatId = 0;

  int getChatListLength() {
    return _oneToOneList.length;
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

  int setInitList(List<ChatModel> list, String toUserId) {
    _oneToOneList.clear();
    int maxId = 0;
    list.forEach((chat) {
      if (chat.fromUserId == UserBloc().getCurrUser().id) {
        chat.compareId = chat.id;
      } else {
        chat.compareId = chat.fbId;
      }
      if(chat.delStat != ChatModel.DELIVERED_TO_LOCAL && chat.id > maxId) {
           maxId = chat.id;
      }
    });
    _sortList(list);

    _oneToOneList = list;

    _chatController.sink.add(_oneToOneList);
    _minChatId = _oneToOneList[_oneToOneList.length - 1].id;
    return maxId;
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
        _oneToOneList.insert(0, cm);

        _chatController.sink.add(_oneToOneList);

        _minChatId = _oneToOneList[_oneToOneList.length - 1].id;
      } else {
        print('cm found in list ' + cm.toString());
      }
    }
  }

  setMoreData(List<ChatModel> moreData) {
    _oneToOneList.addAll(moreData);
    _chatController.sink.add(_oneToOneList);
    _minChatId = _oneToOneList[_oneToOneList.length - 1].id;
  }

  closeChatController() {
    if (!checkIfChatControllerClosed()) {
      _chatController.close();
    }
  }

  getMoreData(String toUserId) async {
    print('min chat id ' + _minChatId.toString());
    List<ChatModel> list = await SembastChat()
        .getChatsLessThanId(_minChatId, DBConstants.DATA_RETREIVE_COUNT);

    if (null == list) {
      QuerySnapshot moreData = await Firebase()
          .getChatCollectionRef(
              Utils()
                  .getChatCollectionId(UserBloc().getCurrUser().id, toUserId),
              Firebase.CHAT_COL_COMPLETE)
          .where("id", isLessThan: _minChatId)
          .orderBy("id", descending: true)
          .limit(DBConstants.DATA_RETREIVE_COUNT)
          .getDocuments();

      if (moreData != null && moreData.documents.length > 0) {
        list = moreData.documents
            .map((item) => ChatModel.fromDocumentSnapshot(item))
            .toList();
        list.forEach((chat) {
          if (chat.fromUserId == UserBloc().getCurrUser().id) {
            chat.compareId = chat.id;
          } else {
            chat.compareId = chat.fbId;
          }
        });
      }

      SembastChat().bulkUpsertInChatStore(list);
    }
    _sortList(list);
      setMoreData(list);
  }

  _sortList(List<ChatModel> list) {
    list.sort((a, b) {
      if (a.compareId > b.compareId) {
        return b.compareId.compareTo(a.compareId);
      } else {
        return a.compareId.compareTo(b.compareId);
      }
    });
  }
}
