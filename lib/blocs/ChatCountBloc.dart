import 'dart:async';

import 'package:chatapp/model/ChatCountModel.dart';

class ChatCountBloc{

  static ChatCountBloc _chatCountBloc;

  factory ChatCountBloc() => _chatCountBloc??ChatCountBloc._();

  ChatCountBloc._();

  StreamController<ChatCountModel> _controller;

  openChatCountController() {
       if(checkIfChatCountControllerClosed()) {
             _controller = StreamController.broadcast();
       }
  }

  StreamController<ChatCountModel> getChatCountController() {
         if(!checkIfChatCountControllerClosed()) {
              return _controller;
         }
         return null;
  }

  addToChatCountController(ChatCountModel data) {
    openChatCountController();
               _controller.sink.add(data);
        
  }

  checkIfChatCountControllerClosed() {
       return _controller == null || _controller.isClosed;
  }

  closeChatCountController() {
        if(!checkIfChatCountControllerClosed()) {
             _controller.close();
        }
  }
}