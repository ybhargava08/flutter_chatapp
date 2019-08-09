import 'dart:async';

import 'package:chatapp/model/UserLatestChatModel.dart';

class UserLatestChatBloc {
  static UserLatestChatBloc _chatCountBloc;

  factory UserLatestChatBloc() => _chatCountBloc ?? UserLatestChatBloc._();

  UserLatestChatBloc._();

  static StreamController<UserLatestChatModel> _controller;

  openChatCountController() {
    if (checkIfChatCountControllerClosed()) {
      _controller = StreamController.broadcast();
    }
  }

  StreamController<UserLatestChatModel> getChatCountController() {
    if (!checkIfChatCountControllerClosed()) {
      return _controller;
    }
    return null;
  }

  addToChatCountController(UserLatestChatModel data) {
    if (!checkIfChatCountControllerClosed()) {
      print('adding to chat count sink ' + data.toString());
      _controller.sink.add(data);
    }
  }

  checkIfChatCountControllerClosed() {
      if(_controller !=null) {
            return _controller.isClosed;
      }
      return true;
  }

  closeChatCountController() {
    if (!checkIfChatCountControllerClosed()) {
      _controller.close();
    }
  }
}
