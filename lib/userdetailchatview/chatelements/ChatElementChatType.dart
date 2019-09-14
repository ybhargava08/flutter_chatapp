import 'package:chatapp/model/ChatModel.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatElementType.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatMediaWidget.dart';
import 'package:chatapp/userdetailchatview/chatelements/ChatTextWidget.dart';
import 'package:flutter/widgets.dart';

class ChatElementChatType extends StatelessWidget {

Widget _getChatChild(ChatModel chat) {
       if (chat.chatType != ChatModel.CHAT) {
          return ChatMediaWidget(ValueKey(chat.id),chat);
       }else{
          return ChatTextWidget(ValueKey(chat.id),chat);
       }
  }

  @override
  Widget build(BuildContext context) {
    final inheritedChat = ChatInheritedWidget.of(context);

    final _chat = inheritedChat.chat;
    return _getChatChild(_chat);
  }

}