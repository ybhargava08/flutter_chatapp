import 'dart:async';

import 'package:chatapp/blocs/ChatUpdateBloc.dart';
import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/database/DBConstants.dart';
import 'package:chatapp/database/OfflineDBChat.dart';
import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/utils.dart';

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
    _chatController = StreamController.broadcast();
    ChatUpdateBloc().openChatUpdateController();
  }

  checkIfChatControllerClosed() {
    return null == _chatController || _chatController.isClosed;
  }

  Stream<List<ChatModel>> getChatStream() {
    return _chatController.stream;
  }

  int setInitList(List<ChatModel> list, String toUserId) {
    _oneToOneList.clear();
    int maxTS = 0;
    list.forEach((chat) {
      if (chat.fromUserId != UserBloc().getCurrUser().id &&
          chat.delStat != ChatModel.DELIVERED_TO_LOCAL &&
          chat.ts > maxTS) {
        maxTS = chat.ts;
      }
    });

    _oneToOneList = list;

    _chatController.sink.add(_oneToOneList);
    _setMinChatId(_oneToOneList[_oneToOneList.length - 1]);
    return maxTS;
  }

  addInChatController(ChatModel cm) {
    if (!checkIfChatControllerClosed()) {
      int index = _oneToOneList.indexWhere((item) => item.id == cm.id);
      if (index < 0) {
        _oneToOneList.insert(0, cm);
        _chatController.sink.add(_oneToOneList);
        if (cm.fromUserId.compareTo(UserBloc().getCurrUser().id) == 0) {
          Utils().playSound('sounds/send_msg.mp3');
        } else {
          Utils().playSound('sounds/incoming_msg.mp3');
        }
      } else {
        _oneToOneList[index] = cm;
        ChatUpdateBloc().addToChatUpdateController(cm);
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
    ChatUpdateBloc().closeUpdateChatController();
  }

  getMoreData(String toUserId) async {
    List<ChatModel> list = await OfflineDBChat()
        .getChatsLessThanId(_minChatId, DBConstants.DATA_RETREIVE_COUNT);
    if (null != list && list.length > 0) {
      setMoreData(list);
    }
  }

  _setMinChatId(ChatModel chat) {
    if (chat.id != null) {
      _minChatId = chat.id;
    }
  }
}
