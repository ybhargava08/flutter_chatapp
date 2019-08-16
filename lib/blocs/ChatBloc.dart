import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/SembastChat.dart';
import 'package:chatapp/model/ChatModel.dart';

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
      if (chat.fromUserId != UserBloc().getCurrUser().id &&
          chat.delStat != ChatModel.DELIVERED_TO_LOCAL &&
          chat.id > maxId) {
        maxId = chat.id;
      }
    });

    _oneToOneList = list;

    _chatController.sink.add(_oneToOneList);
    _setMinChatId(_oneToOneList[_oneToOneList.length - 1]);
    print('setting max id ' + maxId.toString());
    return maxId;
  }

  addInChatController(ChatModel cm) {
    if (!checkIfChatControllerClosed()) {
      List<ChatModel> foundItem =
          _oneToOneList.where((item) => item.id == cm.id).toList();

      if (foundItem == null || foundItem.isEmpty) {
        print('cm not found in list ' + cm.toString());
    
        _oneToOneList.insert(0, cm);

        _chatController.sink.add(_oneToOneList);

      } else {
        print('cm found in list ' + cm.toString());
      }
    }
  }

  setMoreData(List<ChatModel> moreData) {
    _oneToOneList.addAll(moreData);
    _chatController.sink.add(_oneToOneList);
    _setMinChatId(_oneToOneList[_oneToOneList.length - 1]);
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
    if (null != list && list.length > 0) {
      setMoreData(list);
    }
  }

  _setMinChatId(ChatModel chat) {
    if(chat.localChatId!=null) {
          _minChatId = chat.localChatId;
    }
    
  }
}
