import 'dart:async';

import 'package:chatapp/model/ChatModel.dart';

class ChatUpdateBloc {
    
    static ChatUpdateBloc _chatUpdateBloc;

    factory ChatUpdateBloc() => _chatUpdateBloc??=ChatUpdateBloc._();

    ChatUpdateBloc._();

    StreamController<ChatModel> _controller; 

    openChatUpdateController() {
        closeUpdateChatController();
        _controller = StreamController.broadcast();
    }

   addToChatUpdateController(ChatModel chat) {
          if(!_isChatUpdateControllerClosed()) {
                _controller.sink.add(chat);
          }
   }

   StreamController<ChatModel> getChatUpdateController() {
         if(!_isChatUpdateControllerClosed()) {
             return _controller;
         }
         return null;
    }

    _isChatUpdateControllerClosed() {
              return _controller == null || _controller.isClosed;
    }

    closeUpdateChatController() {
         if(!_isChatUpdateControllerClosed()) {
               _controller.close();
         }
    }
}