import 'dart:async';

import 'package:chatapp/blocs/UserBloc.dart';
import 'package:chatapp/model/ChatModel.dart';

class ChatDeleteBloc {
  static ChatDeleteBloc _chatDeleteBloc;

  factory ChatDeleteBloc() => _chatDeleteBloc ??= ChatDeleteBloc._();

  ChatDeleteBloc._();

  List<ChatModel> _deleteList = List();

  StreamController<List<ChatModel>> _streamController;

  openController() {
    closeController();
    _streamController = StreamController.broadcast();
  }

  StreamController<List<ChatModel>> getStreamController() {
    if (!isControllerClosed()) {
      return _streamController;
    }
    return null;
  }

  addRemoveDeleteList(ChatModel chat) {
    if (chat.fromUserId == UserBloc().getCurrUser().id) {
      int index = _deleteList.indexWhere((item) => item.id == chat.id);

      if (index >= 0) {
        _deleteList.removeWhere((item) => item.id == chat.id);
      } else {
        _deleteList.add(chat);
      }
      _addToController();
    }
  }

  clearChatDeleteList(bool addToController) {
    if (_deleteList.length > 0) {
      _deleteList.clear();
      if (addToController) {
        _addToController();
      }
    }
  }

  List<ChatModel> getDeleteList() {
    return _deleteList;
  }

  _addToController() {
    if (!isControllerClosed()) {
      _streamController.sink.add(_deleteList);
    }
  }

  isControllerClosed() {
    return _streamController == null || _streamController.isClosed;
  }

  closeController() {
    if (!isControllerClosed()) {
      _streamController.close();
      clearChatDeleteList(false);
    }
  }
}
